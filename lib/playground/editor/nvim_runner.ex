defmodule Vimperfect.Playground.Editor.NvimRunner do
  alias Vimperfect.Playground.Editor.NvimControls
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def force_stop(pid) do
    if alive?(pid) do
      GenServer.cast(pid, {:force_stop})
      :ok
    else
      {:error, :not_running}
    end
  end

  @doc """
  Will prepare the editor environment and start the editor process.

  Editor process will be started in a PTY.
  """
  def run(pid, filepath, keyspath) do
    GenServer.call(pid, {:run, filepath, keyspath})
  end

  def run_headless(pid, filepath, keyspath) do
    GenServer.call(pid, {:run_headless, filepath, keyspath})
  end

  @doc """
  Will check that the both runner process is still alive.

  Note: if the os process has been exited, this will cause the runner process to shutdown
  """
  def alive?(pid) when is_pid(pid) do
    Process.alive?(pid) and GenServer.call(pid, :process_alive?)
  end

  @doc """
  Used to pass the data directly to the editor process
  """
  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  @doc """
  As the editor process runs in a PTY, it can be resized by calling this function.
  """
  @spec resize_window(runner_pid :: pid(), cols :: integer(), rows :: integer()) :: :ok
  def resize_window(pid, cols, rows) do
    GenServer.cast(pid, {:resize, cols, rows})
  end

  def init(opts) do
    {:ok,
     %{
       on_output: opts.on_output,
       on_exit: opts.on_exit,
       os_pid: nil,
       exec_pid: nil
     }}
  end

  def handle_call({:run, filepath, keyspath}, _from, state) do
    if state.exec_pid == nil do
      {:ok, pid, os_pid} = NvimControls.run_editor(filepath, keyspath, self())

      Logger.debug("Started editor process #{inspect(pid)} with os pid #{inspect(os_pid)}")

      {:reply, :ok, %{state | os_pid: os_pid, exec_pid: pid}}
    else
      {:reply, {:error, :already_running}, state}
    end
  end

  def handle_call({:run_headless, filepath, keyspath}, _from, state) do
    out = NvimControls.run_headless_emulation(filepath, keyspath)

    case out do
      {:ok, _} ->
        {:reply, :ok, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:process_alive?, _from, state) do
    {:reply, state.exec_pid != nil && Process.alive?(state.exec_pid), state}
  end

  def handle_call({:write, data}, _from, state) do
    if state.os_pid != nil do
      NvimControls.send_input(state.os_pid, data)
      {:reply, :ok, state}
    else
      {:reply, {:error, :not_running}, state}
    end
  end

  def handle_cast({:resize, cols, rows}, state) do
    if state.os_pid != nil do
      :ok = NvimControls.send_resize(state.os_pid, cols, rows)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:force_stop}, state) do
    :ok = NvimControls.force_stop(state.exec_pid, state.os_pid)
    {:noreply, state}
  end

  def handle_info({:stdout, _os_pid, data}, state) do
    state.on_output.(data)
    {:noreply, state}
  end

  def handle_info({:DOWN, os_pid, :process, _exec_pid, reason}, state) do
    Logger.debug("Editor process #{inspect(os_pid)} finished: #{inspect(reason)}")
    {:stop, reason, %{state | exec_pid: nil, os_pid: nil}}
  end

  def terminate(reason, state) do
    state.on_exit.(reason)
    :ok
  end
end
