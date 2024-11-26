defmodule Vimperfect.Playground.Ssh.CliTest do
  @moduledoc """
  Tests how the `Vimperfect.Playground.Ssh.Cli` module works in isolation from the daemon.
  """
  use ExUnit.Case, async: true
  alias Vimperfect.Playground.Ssh.TermInfo.Xterm256color
  alias Vimperfect.Playground.Ssh.Cli
  import Mox

  setup :verify_on_exit!

  defp expect_xterm256color_stop_escape_sequences(mock) do
    mock
    # rmkx
    |> expect(:write, fn _ctx, "\e[?1l\e>" -> :ok end)
    # rmcup
    |> expect(:write, fn _ctx, "\e[?1049l" -> :ok end)
    # cnorm
    |> expect(:write, fn _ctx, "\e[?12l\e[?25h" -> :ok end)
  end

  describe "init/1" do
    test "properly initializes the state" do
      handler = SshHandlerMock
      {:ok, state} = Cli.init(handler: handler)

      assert %{conn: nil, chan: nil, term_mod: nil, cols: nil, rows: nil, handler: handler} ==
               state
    end
  end

  describe "ctx/1" do
    test "returns the context" do
      ctx =
        Cli.ctx(%{
          cols: 10,
          rows: 20,
          conn: self(),
          chan: 0,
          term_mod: Xterm256color
        })

      assert ctx.size == {10, 20}
      assert ctx.chan == 0
      assert ctx.conn == self()
      assert ctx.term_mod == Xterm256color
    end
  end

  describe "handle_msg/2" do
    test "ssh_channel_up successfull" do
      test_pid = self()

      SshHandlerMock
      |> expect(:init, fn ctx ->
        assert ctx.size == {nil, nil}
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        :ok
      end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      msg = {:ssh_channel_up, 0, self()}
      assert {:ok, _state} = Cli.handle_msg(msg, state)
    end

    test "stops if handlers fails to initialize" do
      test_pid = self()

      SshHandlerMock
      |> expect(:init, fn ctx ->
        assert ctx.size == {nil, nil}
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        {:error, :test}
      end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      msg = {:ssh_channel_up, 0, self()}
      assert {:stop, 0, _state} = Cli.handle_msg(msg, state)
    end

    test "nothing happes on the unknown message" do
      {:ok, state} = Cli.init(handler: SshHandlerMock)
      msg = {:unknown, 0, self()}
      assert {:ok, _state} = Cli.handle_msg(msg, state)
    end
  end

  describe "handle_ssh_msg/2" do
    test "handles xterm-256color PTY init" do
      test_pid = self()

      SshConnectionMock
      |> expect(:reply_request, fn ctx, wr, status ->
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        assert status == :success
        assert wr == true
        :ok
      end)
      # smcup
      |> expect(:write, fn _ctx, "\e[?1049h" -> :ok end)
      # smkx
      |> expect(:write, fn _ctx, "\e[?1h\e=" -> :ok end)
      # civis
      |> expect(:write, fn _ctx, "\e[?25l" -> :ok end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0}
      # Last 3 is something we don't care about
      pty_info = {"xterm-256color", 10, 20, 0, 0, 0}
      msg = {:ssh_cm, test_pid, {:pty, 0, true, pty_info}}

      assert {:ok, %{term_mod: Xterm256color, cols: 10, rows: 20} = _} =
               Cli.handle_ssh_msg(msg, state)
    end

    test "handles unknown PTY init with failure" do
      test_pid = self()

      SshConnectionMock
      |> expect(:reply_request, fn ctx, wr, status ->
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        assert status == :failure
        assert wr == true
        :ok
      end)

      SshConnectionMock
      # Should not write anything
      |> deny(:write, 2)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0}
      # Last 3 is something we don't care about
      pty_info = {"unknown", 10, 20, 0, 0, 0}
      msg = {:ssh_cm, test_pid, {:pty, 0, true, pty_info}}

      assert {:stop, 0, _state} = Cli.handle_ssh_msg(msg, state)
    end

    test "handles :data event" do
      test_pid = self()

      SshHandlerMock
      |> expect(:on_data, fn ctx, data ->
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        assert data == "test"
        :ok
      end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0}
      msg = {:ssh_cm, test_pid, {:data, 0, 0, "test"}}

      assert {:ok, _state} = Cli.handle_ssh_msg(msg, state)
    end

    test "terminates if handler on_data returns an error" do
      test_pid = self()

      SshHandlerMock
      |> expect(:on_data, fn ctx, data ->
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        assert data == "test"
        {:error, :test}
      end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0, term_mod: Xterm256color}
      msg = {:ssh_cm, test_pid, {:data, 0, 0, "test"}}

      assert {:stop, 0, _state} = Cli.handle_ssh_msg(msg, state)
    end

    test "handles :window_change event" do
      test_pid = self()

      SshHandlerMock
      |> expect(:on_window_resize, fn ctx, cols, rows ->
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        assert cols == 10
        assert rows == 20
        :ok
      end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0}
      msg = {:ssh_cm, test_pid, {:window_change, 0, 10, 20, 0, 0}}

      assert {:ok, _state} = Cli.handle_ssh_msg(msg, state)
    end

    test "ignores if handler on_window_resize returns an error" do
      test_pid = self()

      SshHandlerMock
      |> expect(:on_window_resize, fn ctx, cols, rows ->
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        assert cols == 10
        assert rows == 20
        {:error, :test}
      end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0}
      msg = {:ssh_cm, test_pid, {:window_change, 0, 10, 20, 0, 0}}

      assert {:ok, _state} = Cli.handle_ssh_msg(msg, state)
    end

    test "handles :shell event" do
      test_pid = self()

      SshHandlerMock
      |> expect(:on_ready, fn ctx ->
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        :ok
      end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0}
      msg = {:ssh_cm, test_pid, {:shell, 0, true}}

      assert {:ok, _state} = Cli.handle_ssh_msg(msg, state)
    end

    test "stops if handler on_ready returns an error" do
      test_pid = self()

      SshHandlerMock
      |> expect(:on_ready, fn ctx ->
        assert ctx.chan == 0
        assert ctx.conn == test_pid
        {:error, :test}
      end)

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0, term_mod: Xterm256color}
      msg = {:ssh_cm, test_pid, {:shell, 0, true}}

      assert {:stop, 0, _state} = Cli.handle_ssh_msg(msg, state)
    end

    test "handles unknown events" do
      test_pid = self()

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | conn: test_pid, chan: 0}
      msg = {:ssh_cm, test_pid, {:unknown, 0, true}}

      assert {:ok, _state} = Cli.handle_ssh_msg(msg, state)
    end
  end

  describe "terminate/2" do
    test "terminates the connection without pty" do
      {:ok, state} = Cli.init(handler: SshHandlerMock)
      assert :ok = Cli.terminate(:test, state)
    end

    test "sends PTY stop sequence if xterm-256color PTY is used" do
      SshConnectionMock
      |> expect_xterm256color_stop_escape_sequences()

      {:ok, state} = Cli.init(handler: SshHandlerMock)
      state = %{state | term_mod: Xterm256color}
      assert :ok = Cli.terminate(:test, state)
    end
  end
end
