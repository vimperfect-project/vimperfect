defmodule Vimperfect.Playground.SessionHandler do
  alias Vimperfect.Puzzles.Puzzle
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
    if not SessionContext.field_set?(conn, :user) or session.user == nil do
      SessionContext.set_field(conn, :puzzle_slug, username |> List.to_string())

      user =
        :ssh_file.encode(
          [{public_key, []}],
          :openssh_key
        )
        |> String.trim()
        |> Vimperfect.Accounts.get_user_by_public_key()

      SessionContext.set_field(conn, :user, user)
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

      session.user == nil ->
        Ssh.Connection.puts(
          ctx,
          "Could not find your public key. Make sure you have added it in your profile settings."
        )

        {:error, :normal}

      puzzle == nil ->
        Ssh.Connection.puts(ctx, "Could not find the puzzle you are looking for")

        {:error, :normal}

      true ->
        # TODO: Setup an AFK trigger that will periodically check if the user is still active
        session = SessionContext.set_field(ctx.conn, :puzzle, puzzle)
        run(ctx, session)
    end
  end

  @impl true
  def on_terminate(ctx) do
    session = SessionContext.delete(ctx.conn)
    runner_pid = session[:runner_pid]

    if runner_pid != nil do
      NvimRunner.kill(runner_pid)
    end

    :ok
  end

  @impl true
  def on_data(ctx, data) do
    state = SessionContext.get(ctx.conn)

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
    Logger.info("Disconnected, clearing the session")
    SessionContext.delete(conn)
  end

  defp on_runner_exit(ctx, final_content, keystrokes) do
    state = SessionContext.get(ctx.conn)

    if state[:runner_pid] != nil do
      SessionContext.unset_field(ctx.conn, :runner_pid)
    end

    puzzle = state[:puzzle]

    Ssh.Connection.clear_screen(ctx)

    if puzzle != nil and puzzle.expected_content == final_content do
      {solution, score} =
        Vimperfect.Keystrokes.convert_keystrokes(keystrokes)
        |> Vimperfect.Keystrokes.strip_exit_sequence()

      existing = Vimperfect.Puzzles.get_solution_by_keystrokes(state.user, puzzle, solution)

      SessionContext.set_field(ctx.conn, :last_solution, {solution, score})

      Ssh.Connection.puts(
        ctx,
        """
        Congratulations, your solution is correct!
        Your solution: #{solution}
        Score: #{score}

        #{if existing != nil, do: "Note: You've already done this solution, so nothing will happen after submission", else: "This is a new solution!"}

        Press 's' to submit, 'r' to run the solution again and 'q' to quit
        """,
        multiline: true
      )
    else
      Ssh.Connection.puts(ctx, "Sorry, your solution is incorrect")
      Ssh.Connection.puts(ctx, "Press 'r' to run the solution again and 'q' to quit")
    end
  end

  defp handle_data(ctx, state, data) do
    case data do
      "q" ->
        Logger.debug("Quitting")
        {:error, :quit}

      "s" ->
        case state[:last_solution] do
          {solution, score} ->
            Ssh.Connection.puts(
              ctx,
              "Submitting your final solution #{solution} which scored #{score}"
            )

            case Vimperfect.Puzzles.submit_solution!({solution, score}, state.user, state.puzzle) do
              :ignored ->
                Ssh.Connection.puts(
                  ctx,
                  "Since you already have this solution, saving was skipped."
                )

              _ ->
                nil
            end

            # Exit
            {:error, :submit}

          nil ->
            :ok
        end

      "r" ->
        # Note: state.puzzle MAY be nil, but this is ok since it'll be refactored so that puzzle runner cannot be called by a keypress
        run(ctx, state)

      _ ->
        :ok
    end
  end

  defp run(ctx, %{puzzle: %Puzzle{} = puzzle} = _state) do
    {:ok, runner_pid} =
      NvimRunner.start_link(%{
        on_output: &Ssh.Connection.write(ctx, &1),
        on_exit: fn _, final_content, keystrokes ->
          on_runner_exit(ctx, final_content, keystrokes)
        end
      })

    :ok =
      NvimRunner.prepare_dir(
        runner_pid,
        puzzle.filename || "input.txt",
        puzzle.initial_content
      )

    # FIXME: May be a bug since we started the runner but if run puzzle fails we do not clear it
    case NvimRunner.run(runner_pid) do
      :ok ->
        {cols, rows} = ctx.size
        NvimRunner.resize_window(runner_pid, cols, rows)
        SessionContext.set_field(ctx.conn, :runner_pid, runner_pid)
        :ok

      {:error, reason} ->
        Logger.error("Failed to start editor: #{inspect(reason)}")
        Ssh.Connection.puts(ctx, "Sorry, unable to start the editor for you :(")
        {:error, reason}
    end
  end
end
