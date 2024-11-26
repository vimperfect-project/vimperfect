defmodule Vimperfect.Playground.SessionHandler do
  alias Vimperfect.Playground.SessionContext
  alias Vimperfect.Playground.Ssh.Util, as: SshUtil
  @behaviour Vimperfect.Playground.Ssh.Handler

  require Logger

  defp editor_runner(),
    do:
      Application.fetch_env!(:vimperfect, Vimperfect.Playground)
      |> Keyword.get(:editor_runner, Vimperfect.Playground.Editor.DefaultRunner)

  defp connection(),
    do:
      Application.fetch_env!(:vimperfect, Vimperfect.Playground)
      |> Keyword.get(:connection_wrapper, Vimperfect.Playground.Ssh.Connection)

  defp editor_controls(),
    do:
      Application.fetch_env!(:vimperfect, Vimperfect.Playground)
      |> Keyword.get(:editor_controls, Vimperfect.Playground.Editor.NvimControls)

  @impl true
  def on_connect(conn, username, peer_address, method) do
    Logger.metadata(addr: SshUtil.addr_to_string(peer_address))
    Logger.info("New connection from #{username} via #{method}")

    SessionContext.set_field(conn, :peer_address, peer_address)

    :ok
  end

  @impl true
  def auth(conn, _public_key, username) do
    Logger.metadata(conn: conn)

    # For some reason, auth is called twice,
    # so check if the auth is already set
    if not SessionContext.field_set?(conn, :auth) do
      case username do
        ~c"play" ->
          SessionContext.set_field(conn, :auth, :with_public_key)
          :ok

        _ ->
          {:error, :normal}
      end
    else
      :ok
    end
  end

  @impl true
  def init(ctx) do
    # Note: temporary solution
    puzzle_info = %{
      name: "testtask",
      filename: "puzzle.txt",
      content: "Hello, my name is Ali(bob)ce",
      expected_content: "Hello, my name is Alice"
    }

    SessionContext.set_field(ctx.conn, :puzzle, puzzle_info)

    :ok
  end

  @impl true
  def on_ready(ctx) do
    session = SessionContext.get(ctx.conn)
    Logger.metadata(conn: ctx.conn, addr: SshUtil.addr_to_string(session.peer_address))
    Logger.info("Session ready")

    connection().clear_screen(ctx)
    connection().puts(ctx, "Welcome to the playground! Press q to quit, e to start editor")

    :ok
  end

  @impl true
  def on_data(ctx, data) do
    state = SessionContext.get(ctx.conn)
    Logger.debug("Received data #{inspect(data)}")

    case state[:runner_pid] do
      nil ->
        handle_data(ctx, state, data)

      pid ->
        editor_runner().write(pid, data)
    end
  end

  @impl true
  def on_window_resize(ctx, cols, rows) do
    state = SessionContext.get(ctx.conn)
    runner_pid = state[:runner_pid]

    if runner_pid != nil do
      editor_runner().resize_window(runner_pid, cols, rows)
    end

    :ok
  end

  @impl true
  def on_disconnect(conn, _reason) do
    Logger.info("Disconnected, clearing everything up")

    sessions_dir =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:sessions_dir)

    state = SessionContext.get(conn)
    puzzle = state[:puzzle]

    if puzzle != nil do
      # TODO: Use different thing for session name since people may solve the same puzzle at the same time
      editor_controls().clear_dir(sessions_dir, puzzle[:name])
    end

    if state[:runner_pid] != nil and editor_runner().alive?(state[:runner_pid]) do
      editor_runner().force_stop(state[:runner_pid])
    end

    SessionContext.delete(conn)

    Logger.info("Successfully disconnected")
  end

  defp on_puzzle_runner_exit(ctx) do
    state = SessionContext.get(ctx.conn)

    sessions_dir =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:sessions_dir)

    puzzle = state[:puzzle]

    if state[:runner_pid] != nil do
      editor_controls().clear_dir(sessions_dir, puzzle[:name])
      SessionContext.unset_field(ctx.conn, :runner_pid)
    end

    # case editor_runner().check_solution(state[:puzzle]) do
    #   {:ok, true, _keys} ->
    #     SshUtil.puts(ctx, "Congratulations, your solution is correct!")

    #   {:ok, false, _keys} ->
    #     SshUtil.puts(ctx, "Sorry, your solution is incorrect")

    #   {:error, reason} ->
    #     Logger.error("Failed to check solution: #{inspect(reason)}")
    #     SshUtil.puts(ctx, "Server error")
    # end

    connection().clear_screen(ctx)
    connection().puts(ctx, "No checking is done now, consider yourself right.")
  end

  defp handle_data(ctx, state, data) do
    case data do
      "q" ->
        Logger.debug("Quitting")
        {:error, :quit}

      "e" ->
        # Note: state.puzzle MAY be nil, but this is ok since it'll be refactored so that puzzle runner cannot be called by a keypress
        run(ctx, state)

      _ ->
        Logger.debug("Unknown key #{inspect(data)}")
        :ok
    end
  end

  defp run(ctx, %{puzzle: puzzle} = _state) do
    sessions_dir =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:sessions_dir)

    {:ok, runner_pid} =
      editor_runner().start_link(%{
        on_output: &connection().write(ctx, &1),
        on_exit: fn _ -> on_puzzle_runner_exit(ctx) end
      })

    {:ok, filepath, keyspath} =
      editor_controls().prepare_dir(
        sessions_dir,
        puzzle[:name],
        puzzle[:filename],
        puzzle[:content]
      )

    # FIXME: May be a bug since we started the runner but if run puzzle fails we do not clear it
    case editor_runner().run(runner_pid, filepath, keyspath) do
      :ok ->
        {cols, rows} = ctx.size
        editor_runner().resize_window(runner_pid, cols, rows)
        SessionContext.set_field(ctx.conn, :runner_pid, runner_pid)
        :ok

      {:error, reason} ->
        Logger.error("Failed to start editor: #{inspect(reason)}")
        connection().puts(ctx, "Sorry, unable to start the editor for you :(")
        {:error, reason}
    end
  end
end