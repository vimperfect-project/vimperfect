# **Improntant note**: I see no reason in mocking SessionContext as it does not have any
# complex functionality and the SessionContext module is tested itself.
# So, using a mock for SessionContext will only introduce unwanted complixity to the tests
defmodule Vimperfect.Playground.SessionHandlerTest do
  alias Vimperfect.Playground.SessionContext
  use ExUnit.Case, async: true

  import Mox

  defp prepare_session_after_ready(conn, setup_start_link \\ true) do
    SessionContext.set_field(conn, :puzzle, %{
      name: "testtask",
      filename: "puzzle.txt",
      content: "Hello, my name is Ali(bob)ce",
      expected_content: "Hello, my name is Alice"
    })

    ctx = %{
      term_mod: Vimperfect.Playground.Ssh.TermInfo.Xterm256color,
      size: {80, 24},
      chan: 0,
      conn: conn
    }

    if setup_start_link do
      EditorRunnerMock
      |> expect(:start_link, fn opts ->
        assert opts[:on_output] != nil
        assert opts[:on_exit] != nil

        {:ok, conn}
      end)
    end

    EditorControlsMock
    |> expect(:prepare_dir, fn sd, puz_name, filename, contents ->
      assert sd == "/tmp/vimperfect-sessions"
      assert puz_name == "testtask"
      assert filename == "puzzle.txt"
      assert contents == "Hello, my name is Ali(bob)ce"
      {:ok, "filepath", "keyspath"}
    end)

    ctx
  end

  setup :verify_on_exit!

  setup do
    test_self = self()

    on_exit(fn ->
      SessionContext.delete(test_self)
    end)
  end

  describe "on_connect/2" do
    test "saves the peer address upon connection" do
      conn = self()
      username = "bob"
      peer_address = {{127, 0, 0, 1}, 1337}
      method = "publickey"

      assert :ok =
               Vimperfect.Playground.SessionHandler.on_connect(
                 conn,
                 username,
                 peer_address,
                 method
               )

      assert %{peer_address: _} = SessionContext.get(conn)
    end
  end

  describe "auth/3" do
    test "accepts play username and sets the auth field to :with_public_key" do
      conn = self()
      public_key = "something"
      username = ~c"play"

      assert :ok = Vimperfect.Playground.SessionHandler.auth(conn, public_key, username)
      assert %{auth: :with_public_key} = SessionContext.get(conn)
    end

    test "returns an error if the username is not play" do
      conn = self()
      public_key = nil
      username = ~c"alice"

      assert {:error, :normal} =
               Vimperfect.Playground.SessionHandler.auth(conn, public_key, username)

      assert %{} = SessionContext.get(conn)
    end
  end

  describe "init/1" do
    test "returns :ok" do
      assert :ok = Vimperfect.Playground.SessionHandler.init(%{conn: self()})
    end
  end

  describe "on_ready/1" do
    test "properly greets the user" do
      conn = self()
      initial_session = SessionContext.set_field(conn, :peer_address, {{127, 0, 0, 1}, 1337})

      ctx = %{
        term_mod: Vimperfect.Playground.Ssh.TermInfo.Xterm256color,
        size: {80, 24},
        chan: nil,
        conn: conn
      }

      SshConnectionMock
      |> expect(:clear_screen, fn _ -> :ok end)
      |> expect(:puts, fn _, msg ->
        assert msg == "Welcome to the playground! Press q to quit, e to start editor"
      end)

      assert :ok = Vimperfect.Playground.SessionHandler.on_ready(ctx)
      # Should not editor the initial session info
      assert ^initial_session = SessionContext.get(conn)
    end
  end

  describe "on_data/2 without editor" do
    test "quits if q is pressed" do
      conn = self()

      ctx = %{
        term_mod: Vimperfect.Playground.Ssh.TermInfo.Xterm256color,
        size: {80, 24},
        chan: 0,
        conn: conn
      }

      assert {:error, :quit} = Vimperfect.Playground.SessionHandler.on_data(ctx, "q")
    end

    test "setups editor runner management" do
      conn = self()
      ctx = prepare_session_after_ready(conn, false)

      EditorRunnerMock
      |> expect(:start_link, fn opts ->
        assert opts[:on_output] != nil
        opts.on_output.("some data")

        # Wait a bit before sending exit singal
        Task.async(fn ->
          :timer.sleep(100)
          opts.on_exit.(:normal)
          send(conn, :exit_callback_called)
        end)

        {:ok, conn}
      end)
      |> expect(:run, fn c, f, k ->
        assert c == conn
        assert f == "filepath"
        assert k == "keyspath"
        :ok
      end)
      |> expect(:resize_window, fn c, cols, rows ->
        assert c == conn
        assert cols == 80
        assert rows == 24
        :ok
      end)

      SshConnectionMock
      |> expect(:write, fn _, msg ->
        assert msg == "some data"
        :ok
      end)
      |> expect(:puts, fn _, msg ->
        assert msg == "No checking is done now, consider yourself right."
        :ok
      end)
      |> expect(:clear_screen, fn _ -> :ok end)

      EditorControlsMock
      |> expect(:clear_dir, fn sd, puz_name ->
        assert sd == "/tmp/vimperfect-sessions"
        assert puz_name == "testtask"
        :ok
      end)

      assert :ok = Vimperfect.Playground.SessionHandler.on_data(ctx, "e")
      assert conn == SessionContext.get(conn).runner_pid

      assert_receive :exit_callback_called, 500

      assert nil == SessionContext.get(conn)[:runner_pid]
    end

    @tag capture_log: [level: :error]
    test "clears up properly if the editor process fails to start" do
      conn = self()
      ctx = prepare_session_after_ready(conn)

      EditorRunnerMock
      |> expect(:run, fn c, f, k ->
        assert c == conn
        assert f == "filepath"
        assert k == "keyspath"
        {:error, :some_error}
      end)

      SshConnectionMock
      |> expect(:puts, fn _, msg ->
        assert msg == "Sorry, unable to start the editor for you :("
      end)

      assert {:error, :some_error} = Vimperfect.Playground.SessionHandler.on_data(ctx, "e")
      assert nil == SessionContext.get(conn)[:runner_pid]
    end

    test "handles unknown key" do
      conn = self()

      ctx = %{
        term_mod: Vimperfect.Playground.Ssh.TermInfo.Xterm256color,
        size: {80, 24},
        chan: 0,
        conn: conn
      }

      assert :ok = Vimperfect.Playground.SessionHandler.on_data(ctx, "????")
    end
  end

  describe "on_data/2 with editor" do
    test "forwards data to the editor" do
      conn = self()
      SessionContext.set_field(conn, :runner_pid, self())

      ctx = %{
        term_mod: Vimperfect.Playground.Ssh.TermInfo.Xterm256color,
        size: {80, 24},
        chan: 0,
        conn: conn
      }

      EditorRunnerMock
      |> expect(:write, fn pid, "e" ->
        assert pid == conn
        :ok
      end)
      |> expect(:write, fn pid, "q" ->
        assert pid == conn
        :ok
      end)
      |> expect(:write, fn pid, "?" ->
        assert pid == conn
        :ok
      end)

      assert :ok = Vimperfect.Playground.SessionHandler.on_data(ctx, "e")
      assert :ok = Vimperfect.Playground.SessionHandler.on_data(ctx, "q")
      assert :ok = Vimperfect.Playground.SessionHandler.on_data(ctx, "?")
    end
  end

  describe "on_window_resize/3" do
    test "resizes window if the editor is running" do
      conn = self()
      SessionContext.set_field(conn, :runner_pid, self())

      ctx = %{
        term_mod: Vimperfect.Playground.Ssh.TermInfo.Xterm256color,
        size: {80, 24},
        chan: 0,
        conn: conn
      }

      EditorRunnerMock
      |> expect(:resize_window, fn pid, cols, rows ->
        assert pid == conn
        assert cols == 80
        assert rows == 24
        :ok
      end)

      assert :ok = Vimperfect.Playground.SessionHandler.on_window_resize(ctx, 80, 24)
    end

    test "does nothing if the editor is not running" do
      conn = self()
      SessionContext.unset_field(conn, :runner_pid)

      EditorRunnerMock
      |> deny(:resize_window, 3)

      ctx = %{
        term_mod: Vimperfect.Playground.Ssh.TermInfo.Xterm256color,
        size: {80, 24},
        chan: 0,
        conn: conn
      }

      assert :ok = Vimperfect.Playground.SessionHandler.on_window_resize(ctx, 80, 24)
    end
  end

  describe "disconnect/2" do
    test "calls clear_dir if puzzle is present" do
      conn = self()
      SessionContext.set_field(conn, :puzzle, %{name: "testtask"})

      EditorControlsMock
      |> expect(:clear_dir, fn sd, puz_name ->
        assert sd == "/tmp/vimperfect-sessions"
        assert puz_name == "testtask"
        :ok
      end)

      EditorRunnerMock
      |> expect(:alive?, 1, fn pid ->
        assert pid == conn
        true
      end)
      |> expect(:force_stop, 1, fn pid ->
        assert pid == conn
        :ok
      end)

      Vimperfect.Playground.SessionHandler.on_disconnect(conn, :normal)
      assert %{} = SessionContext.get(conn)

      SessionContext.set_field(conn, :runner_pid, self())
      Vimperfect.Playground.SessionHandler.on_disconnect(conn, :normal)
      assert %{} = SessionContext.get(conn)
    end

    test "does nothing if puzzle is not present" do
      conn = self()
      SessionContext.unset_field(conn, :puzzle)

      EditorControlsMock
      |> deny(:clear_dir, 2)

      EditorRunnerMock
      |> deny(:alive?, 1)
      |> deny(:force_stop, 1)

      Vimperfect.Playground.SessionHandler.on_disconnect(conn, :normal)
      assert %{} = SessionContext.get(conn)
    end
  end
end
