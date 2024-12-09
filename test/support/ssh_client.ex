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
        timeout -> {:error, "Timeout. Did not receive data for #{timeout}ms."}
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

      any ->
        {:unknown, any}
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
