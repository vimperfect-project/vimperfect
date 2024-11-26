defmodule Vimperfect.Playground.Editor.DefaultRunnerTest do
  alias Vimperfect.Playground.Editor.DefaultRunner
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  setup do
    pid =
      start_supervised!(
        {
          DefaultRunner,
          %{
            on_output: &RunnerCallbacksMock.on_output/1,
            on_exit: &RunnerCallbacksMock.on_exit/1,
            editor_controls: EditorControlsMock
          }
        },
        restart: :temporary
      )

    %{pid: pid}
  end

  describe "run/3 and alive?/1" do
    test "alive?1 returns false if the editor process is not running", %{pid: pid} do
      assert not DefaultRunner.alive?(pid)
    end

    test "should start the editor process and alive?/1 returns true", %{pid: pid} do
      filepath = "/tmp/test.txt"
      keyspath = "/tmp/keys.log"

      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_editor, fn f, k, monitor_pid ->
        assert monitor_pid == self()
        assert f == filepath, "Expected filepath to match"
        assert k == keyspath, "Expected keyspath to match"
        {:ok, self(), 123}
      end)

      assert :ok = DefaultRunner.run(pid, filepath, keyspath)
      assert DefaultRunner.alive?(pid)
    end

    test "handles already running process correctly", %{pid: pid} do
      os_pid = 123

      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_editor, fn _, _, _ -> {:ok, self(), os_pid} end)

      assert :ok = DefaultRunner.run(pid, "/tmp/test.txt", "/tmp/keys.log")
      assert DefaultRunner.alive?(pid)
      assert {:error, :already_running} = DefaultRunner.run(pid, "/tmp/test.txt", "/tmp/keys.log")
    end
  end

  describe "on_output callback" do
    test "should be called event is received", %{pid: pid} do
      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_editor, fn _, _, _ -> {:ok, self(), 123} end)

      test_pid = self()

      RunnerCallbacksMock
      |> allow(self(), pid)
      |> expect(:on_output, fn data ->
        assert data == "hello"
        send(test_pid, :callback_received)
      end)

      assert :ok = DefaultRunner.run(pid, "/tmp/test.txt", "/tmp/keys.log")
      assert DefaultRunner.alive?(pid)
      _ = send(pid, {:stdout, 123, "hello"})
      assert_receive :callback_received
    end
  end

  describe "on_exit callback" do
    test "should be called when the editor process exits", %{pid: pid} do
      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_editor, fn _, _, _ -> {:ok, self(), 123} end)

      test_pid = self()

      RunnerCallbacksMock
      |> allow(self(), pid)
      |> expect(:on_exit, fn reason ->
        assert reason == :normal
        send(test_pid, :callback_received)
      end)

      assert :ok = DefaultRunner.run(pid, "/tmp/test.txt", "/tmp/keys.log")
      assert DefaultRunner.alive?(pid)
      _ = send(pid, {:DOWN, 123, :process, self(), :normal})
      assert_receive :callback_received
    end
  end

  describe "force_stop/1" do
    test "will kill the editor process", %{pid: pid} do
      os_pid = 123
      exec_pid = self()
      test_pid = self()

      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_editor, fn _, _, _ -> {:ok, exec_pid, os_pid} end)
      |> expect(:force_stop, fn exec_pid_from_runner, os_pid_from_runner ->
        assert exec_pid_from_runner == exec_pid
        assert os_pid_from_runner == os_pid

        # Emulate process takedown
        send(pid, {:DOWN, os_pid, :process, exec_pid, :normal})
        :ok
      end)

      RunnerCallbacksMock
      |> allow(self(), pid)
      |> expect(:on_exit, fn reason ->
        assert reason == :normal
        send(test_pid, :callback_received)
      end)

      assert :ok = DefaultRunner.run(pid, "/tmp/test.txt", "/tmp/keys.log")
      assert DefaultRunner.alive?(pid)
      assert :ok = DefaultRunner.force_stop(pid)

      assert_receive :callback_received

      ref = Process.monitor(pid)
      # Wait for the process to die in case it didn't after last assert_receive
      assert_receive {:DOWN, ^ref, :process, ^pid, _}

      assert not DefaultRunner.alive?(pid)
    end

    test "will not call on_exit if the editor process is not running", %{pid: pid} do
      EditorControlsMock
      |> allow(self(), pid)
      |> deny(:force_stop, 2)

      assert not DefaultRunner.alive?(pid)
      assert {:error, :not_running} = DefaultRunner.force_stop(pid)
    end
  end

  describe "write/2" do
    test "sending input only works", %{pid: pid} do
      os_pid = 123

      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_editor, fn _, _, _ -> {:ok, self(), os_pid} end)
      |> expect(:send_input, fn os_pid_from_runner, data ->
        assert os_pid_from_runner == os_pid
        assert data == "hello"
        :ok
      end)

      assert :ok = DefaultRunner.run(pid, "/tmp/test.txt", "/tmp/keys.log")
      assert DefaultRunner.alive?(pid)

      assert :ok = DefaultRunner.write(pid, "hello")
    end

    test "will fail if the editor process is not running", %{pid: pid} do
      assert not DefaultRunner.alive?(pid)
      assert {:error, :not_running} = DefaultRunner.write(pid, "hello")
    end
  end

  describe "run_headless/3" do
    test "calls the editor controls to run the emulation", %{pid: pid} do
      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_headless_emulation, fn _, _ -> {:ok, "hello"} end)

      assert :ok = DefaultRunner.run_headless(pid, "/tmp/test.txt", "/tmp/keys.log")
    end

    test "properly passes errors to the caller", %{pid: pid} do
      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_headless_emulation, fn _, _ -> {:error, :some_error} end)

      assert {:error, :some_error} =
               DefaultRunner.run_headless(pid, "/tmp/test.txt", "/tmp/keys.log")
    end
  end

  describe "resize_window/3" do
    test "will call the editor controls to resize the window", %{pid: pid} do
      os_pid = 123
      test_pid = self()

      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_editor, fn _, _, _ -> {:ok, self(), os_pid} end)
      |> expect(:send_resize, fn os_pid, cols, rows ->
        assert os_pid == 123
        assert cols == 10
        assert rows == 20

        send(test_pid, :callback_received)
        :ok
      end)

      assert :ok = DefaultRunner.run(pid, "/tmp/test.txt", "/tmp/keys.log")
      assert :ok = DefaultRunner.resize_window(pid, 10, 20)

      assert_receive :callback_received
    end

    test "will fail if the editor process is not running", %{pid: pid} do
      os_pid = 123

      EditorControlsMock
      |> allow(self(), pid)
      |> expect(:run_editor, fn _, _, _ -> {:ok, self(), os_pid} end)
      |> deny(:send_resize, 3)

      assert :ok = DefaultRunner.run(pid, "/tmp/test.txt", "/tmp/keys.log")
      assert :ok = DefaultRunner.resize_window(pid, 10, 20)
    end
  end
end
