defmodule SSHClient do
  @moduledoc """
  Simple ssh client that can collect responses as they come from the server.

  Thanks to https://github.com/jbenden/esshd testing examples
  """

  def connect(opts) do
    opts =
      opts
      |> convert_values
      |> defaults(port: 22, negotiation_timeout: 5000, silently_accept_hosts: true)

    own_keys = [:ip, :port, :negotiation_timeout, :prompt]

    ssh_opts = opts |> Enum.filter(fn {k, _} -> k not in own_keys end)

    {:ok, conn} = :ssh.connect(opts[:ip], opts[:port], ssh_opts, opts[:negotiation_timeout])
    {:ok, chan_id} = :ssh_connection.session_channel(conn, :infinity)

    {:ok, conn, chan_id}
  end

  def close(conn, chan) do
    :ssh_connection.close(conn, chan)
  end

  def request_shell(conn, chan) do
    :ssh_connection.shell(conn, chan)
  end

  def request_pty(conn, chan, term \\ "xterm-256color", cols \\ 80, rows \\ 24) do
    case :ssh_connection.ptty_alloc(conn, chan, term: term, cols: cols, rows: rows) do
      :success -> :ok
      {:error, :closed} -> :ok
      any -> any
    end
  end

  @doc """
  Collects one message from the ssh connection
  """
  @spec collect_response(pid(), integer()) ::
          {status :: :ok | :error, output :: binary()} | :eof | :closed | {:unknown, any()}
  def collect_response(conn, chan, timeout \\ 5_000) do
    response =
      receive do
        {:ssh_cm, _, res} -> res
      after
        timeout -> {:timeout, "Timeout. Did not receive data for #{timeout}ms."}
      end

    case response do
      {:data, ^chan, _, new_data} ->
        :ssh_connection.adjust_window(conn, chan, byte_size(new_data))

      _ ->
        :ok
    end

    case response do
      {:data, ^chan, 1, new_data} ->
        {:error, new_data}

      {:data, ^chan, 0, new_data} ->
        {:ok, new_data}

      {:eof, ^chan} ->
        :eof

      {:closed, ^chan} ->
        :closed

      {:timeout, err} ->
        {:timeout, err}

      any ->
        {:unknown, any}
    end
  end

  @doc """
  Will run `collect_response/3` until the data is coming.

  Timeout specifies the maximum time to wait for new data to come.
  """
  @spec collect_all(pid(), integer(), timeout()) :: binary()
  def collect_all(conn, chan, timeout \\ 50) do
    do_collect_all(conn, chan, timeout, "")
  end

  defp do_collect_all(conn, chan, timeout, acc) do
    case collect_response(conn, chan, timeout) do
      {:ok, data} ->
        do_collect_all(conn, chan, timeout, acc <> data)

      {:timeout, _} ->
        acc

      {:error, data} ->
        acc <> data

      :eof ->
        acc

      :closed ->
        {:closed, acc}

      {:unknown, _} ->
        acc
    end
  end

  @doc """
  Parses a string as a sequence of keypresses and sends them individually.
  Drops the feedback except for the last key by default, use `all_feedback: true`
  """
  def send_keys(conn, chan, keys, opts \\ []) do
    out =
      keys
      |> String.graphemes()
      |> Enum.map(fn key ->
        send(conn, chan, key)

        collect_all(conn, chan)
      end)

    if Keyword.get(opts, :all_feedback, false) do
      Enum.join(out, "")
    else
      List.last(out)
    end
  end

  def send(conn, chan_id, string) do
    case :ssh_connection.send(conn, chan_id, string) do
      :ok -> :ok
      {:error, :closed} -> :ok
    end
  end

  defp defaults(args, defs) do
    defs |> Keyword.merge(args)
  end

  defp convert_values(args) do
    Enum.map(args, fn {k, v} -> {k, convert_value(v)} end)
  end

  defp convert_value(v) when is_binary(v) do
    String.to_charlist(v)
  end

  defp convert_value(v), do: v
end
