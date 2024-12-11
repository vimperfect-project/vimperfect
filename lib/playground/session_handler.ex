defmodule Vimperfect.Playground.SessionHandler do
  alias Vimperfect.Puzzles.Puzzle
  alias Vimperfect.Playground.Editor.NvimControls
  alias Vimperfect.Playground.Editor.NvimRunner
  alias Vimperfect.Playground.Ssh
  alias Vimperfect.Playground.SessionContext
  alias Vimperfect.Playground.Ssh.Util, as: SshUtil
  @behaviour Vimperfect.Playground.Ssh.Handler

  require Logger

  @impl true
  def on_connect(conn, username, peer_address, method) do
    Logger.metadata(addr: SshUtil.addr_to_string(peer_address))
    Logger.info("New connection from #{username} via #{method}")

    SessionContext.set_field(conn, :peer_address, peer_address)

    :ok
  end

  @impl true
  def auth(conn, public_key, username) do
    Logger.metadata(conn: conn)
    Logger.debug("New auth request")

    session = SessionContext.get(conn)

    # For some reason, auth is called twice,
    # so check if the auth is already set or if the previous key was invalid
    if not SessionContext.field_set?(conn, :auth) or session.auth == :invalid do
      SessionContext.set_field(conn, :puzzle_slug, username |> List.to_string())

      user =
        :ssh_file.encode(
          [{public_key, []}],
          :openssh_key
        )
        |> String.trim()
        |> Vimperfect.Accounts.get_user_by_public_key()

      if user != nil do
        SessionContext.set_field(conn, :auth, :ok)
      else
        SessionContext.set_field(conn, :auth, :invalid)
      end
    end

    :ok
  end

  @impl true
  def init(_ctx) do
    :ok
  end

  @impl true
  def on_ready(ctx) do
    session = SessionContext.get(ctx.conn)
    Logger.metadata(conn: ctx.conn, addr: SshUtil.addr_to_string(session.peer_address))
    Logger.info("Session ready")

    puzzle = Vimperfect.Puzzles.get_puzzle_by_slug(session.puzzle_slug)

    cond do
      ctx.term_mod == nil ->
        Ssh.Connection.puts(ctx, "Sorry, your terminal does not support the required features")

        {:error, :normal}

      session.auth == :invalid ->
        Ssh.Connection.puts(
          ctx,
          "Could not find your public key. Make sure you have added it in your profile settings."
        )

        {:error, :normal}

      puzzle == nil ->
        Ssh.Connection.puts(ctx, "Could not find the puzzle you are looking for")

        {:error, :normal}

      true ->
        session = SessionContext.set_field(ctx.conn, :puzzle, puzzle)
        run(ctx, session)

        # Ssh.Connection.clear_screen(ctx)
        # Ssh.Connection.puts(ctx, "Welcome to the playground! Press q to quit, e to start editor")
        # :ok
    end
  end

  @impl true
  def on_terminate(ctx) do
    session = SessionContext.delete(ctx.conn)
    runner_pid = session[:runner_pid]

    if runner_pid != nil do
      :ok = NvimRunner.force_stop(runner_pid)
    end

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
        NvimRunner.write(pid, data)
    end
  end

  @impl true
  def on_window_resize(ctx, cols, rows) do
    state = SessionContext.get(ctx.conn)
    runner_pid = state[:runner_pid]

    if runner_pid != nil do
      NvimRunner.resize_window(runner_pid, cols, rows)
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
      NvimControls.clear_dir(sessions_dir, puzzle[:name])
    end

    if state[:runner_pid] != nil and NvimRunner.alive?(state[:runner_pid]) do
      NvimRunner.force_stop(state[:runner_pid])
    end

    SessionContext.delete(conn)

    Logger.info("Successfully disconnected")
  end

  defp on_puzzle_runner_exit(ctx) do
    state = SessionContext.get(ctx.conn)

    sessions_dir =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:sessions_dir)

    # puzzle = state[:puzzle]

    if state[:runner_pid] != nil do
      NvimControls.clear_dir(sessions_dir, state[:session_name])
      SessionContext.unset_field(ctx.conn, :runner_pid)
    end

    # case NvimControls.run_headless_emulation() do
    # end

    #   {:ok, true, _keys} ->
    #     SshUtil.puts(ctx, "Congratulations, your solution is correct!")

    #   {:ok, false, _keys} ->
    #     SshUtil.puts(ctx, "Sorry, your solution is incorrect")

    #   {:error, reason} ->
    #     Logger.error("Failed to check solution: #{inspect(reason)}")
    #     SshUtil.puts(ctx, "Server error")
    # end

    Ssh.Connection.puts(ctx, "No checking is done now, consider yourself right.")
    Ssh.Connection.close(ctx)
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

  defp run(ctx, %{puzzle: %Puzzle{} = puzzle} = _state) do
    sessions_dir =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:sessions_dir)

    {:ok, runner_pid} =
      NvimRunner.start_link(%{
        on_output: &Ssh.Connection.write(ctx, &1),
        on_exit: fn _ -> on_puzzle_runner_exit(ctx) end
      })

    # TODO: Move directory setup to runner

    # TODO: DO not use ecto, rather a util func that returns a random UUID string
    session_name = Ecto.UUID.generate()

    {:ok, filepath, keyspath} =
      NvimControls.prepare_dir(
        sessions_dir,
        session_name,
        puzzle.filename || "input.txt",
        puzzle.initial_content
      )

    # FIXME: May be a bug since we started the runner but if run puzzle fails we do not clear it
    case NvimRunner.run(runner_pid, filepath, keyspath) do
      :ok ->
        {cols, rows} = ctx.size
        NvimRunner.resize_window(runner_pid, cols, rows)
        SessionContext.set_field(ctx.conn, :runner_pid, runner_pid)
        SessionContext.set_field(ctx.conn, :session_name, session_name)
        :ok

      {:error, reason} ->
        Logger.error("Failed to start editor: #{inspect(reason)}")
        Ssh.Connection.puts(ctx, "Sorry, unable to start the editor for you :(")
        {:error, reason}
    end
  end
end
