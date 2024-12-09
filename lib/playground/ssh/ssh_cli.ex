defmodule Vimperfect.Playground.Ssh.Cli do
  @moduledoc """
  This module is responsible for making CLI functionality for the playground on
  the behalf of the module that was passed as the :handler field.
  The handler must implement `Vimperfect.Playground.Ssh.Handler` behaviour.

  It is responsible for setting up the SSH connection, initilizing PTY, window resizes and passing data to the handler as is comes.
  """
  alias Vimperfect.Playground.Ssh
  @behaviour :ssh_server_channel

  require Logger

  @impl true
  def init(args) do
    handler = Keyword.fetch!(args, :handler)

    {:ok,
     %{
       conn: nil,
       chan: nil,
       term_mod: nil,
       cols: nil,
       rows: nil,
       handler: handler
     }}
  end

  @impl true
  def handle_msg({:ssh_channel_up, chan, conn}, %{conn: nil, chan: nil} = state) do
    Logger.debug("Connection established", conn: conn, chan: chan)

    state = %{state | conn: conn, chan: chan}

    case state.handler.init(ctx(state)) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        Logger.debug("Handler failed to initialize with reason: #{inspect(reason)}",
          conn: conn,
          chan: chan
        )

        {:stop, chan, state}
    end
  end

  def handle_msg(_msg, state) do
    {:ok, state}
  end

  @impl true
  # Process a key
  def handle_ssh_msg(
        {:ssh_cm, conn, {:data, chan, 0, data}},
        %{conn: conn, chan: chan} = state
      ) do
    case state.handler.on_data(ctx(state), data) do
      :ok ->
        {:ok, state}

      {:error, _reason} ->
        {:stop, chan, state}
    end
  end

  # Allocate a new terminal, just record the properties passed for now
  def handle_ssh_msg(
        {:ssh_cm, conn, {:pty, chan, wr, props}},
        %{conn: conn, chan: chan} = state
      ) do
    {term_string, cols, rows, _, _, _} = props

    Logger.debug(
      "PTY requested term=#{inspect(term_string)}, cols=#{cols}, rows=#{rows}",
      conn: conn,
      chan: chan
    )

    if term_mod = Vimperfect.Playground.Ssh.TermInfo.lookup(to_string(term_string)) do
      Ssh.Connection.reply_request(ctx(state), wr, :success)
      init_term(%{state | term_mod: term_mod, cols: cols, rows: rows})
    else
      Logger.debug(
        "Could not found supported term_mod info for #{term_mod}, dropping the connection",
        conn: conn,
        chan: chan
      )

      Ssh.Connection.reply_request(ctx(state), wr, :failure)
      {:stop, chan, state}
    end
  end

  # Record any environment variables passed by the client
  # def handle_ssh_msg(
  #       {:ssh_cm, conn, {:env, chan, wr, key, val}},
  #       %{conn: conn, chan: chan} = state
  #     ) do
  #   Ssh.Connection.reply_request(conn, wr, :success, chan)
  #   {:ok, %{state | env: Map.put(state.env, to_string(key), to_string(val))}}
  # end

  # Process a window resize
  def handle_ssh_msg(
        {:ssh_cm, conn, {:window_change, chan, cols, rows, _, _}},
        %{conn: conn, chan: chan} = state
      ) do
    # Put cols and rows before the handler is called so that context and arguments match
    state = %{state | cols: cols, rows: rows}

    res = state.handler.on_window_resize(ctx(state), cols, rows)

    case res do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        Logger.debug("Handler failed to handle window resize: #{inspect(reason)}")
        {:ok, state}
    end
  end

  # Start the app - this 'shell' message arrives _after_ the 'pty' and
  # 'env' messages
  def handle_ssh_msg(
        {:ssh_cm, conn, {:shell, chan, _wr}},
        %{conn: conn, chan: chan} = state
      ) do
    case state.handler.on_ready(ctx(state)) do
      :ok ->
        {:ok, state}

      {:error, _reason} ->
        {:stop, chan, state}
    end
  end

  def handle_ssh_msg(msg, state) do
    Logger.debug("Unhandled ssh message: #{inspect(msg)}")
    {:ok, state}
  end

  defp init_term(%{conn: conn, chan: chan, term_mod: term_mod} = state) do
    _ = Code.ensure_loaded!(term_mod)

    Logger.debug("Sending terminal init sequence for term_mod #{inspect(term_mod)}",
      conn: conn,
      chan: chan
    )

    [:smcup, :smkx, :civis]
    |> Enum.filter(&function_exported?(term_mod, &1, 0))
    |> Enum.map(&apply(term_mod, &1, []))
    |> Enum.each(&Ssh.Connection.write(ctx(state), &1))

    Logger.debug("Initialized term", conn: conn, chan: chan)

    {:ok, state}
  end

  @impl true
  def terminate(reason, %{term_mod: term_mod} = state) do
    if term_mod != nil do
      _ = Code.ensure_loaded!(term_mod)

      [:rmkx, :rmcup, :cnorm]
      |> Enum.filter(&function_exported?(term_mod, &1, 0))
      |> Enum.map(&apply(term_mod, &1, []))
      |> Enum.each(&Ssh.Connection.write(ctx(state), &1))
    end

    Logger.debug("Terminating connection reason: #{inspect(reason)}")
    :ok
  end

  def ctx(%{conn: conn, chan: chan, rows: rows, cols: cols, term_mod: term_mod} = _state) do
    %{
      term_mod: term_mod,
      size: {cols, rows},
      chan: chan,
      conn: conn
    }
  end
end
