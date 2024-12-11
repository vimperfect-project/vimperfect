# TODO: DOCS
defmodule Vimperfect.Playground.Editor.NvimRunner do
  alias Vimperfect.Playground.Editor.NvimControls
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Kills the runner, which will cause the editor process and session directory cleanup
  """
  def kill(pid) do
    GenServer.stop(pid)
  end

  @doc """
  Will setup a directory for the editor process to work in. Required by `run/1`

  A file passed in parameters will be open by the editor when the `run/1` function is called. The file
  will contain the content passed in the `file_content` parameter.
  """
  @spec prepare_dir(pid(), filename :: binary(), file_content :: binary()) ::
          :ok | {:error, reason :: term()}
  def prepare_dir(pid, filename, file_content) do
    GenServer.call(pid, {:prepare_dir, filename, file_content})
  end

  @doc """
  Will start the editor process and start the editor process. Requires `prepare_dir/3` to be called beforehand,
  otherwise `{:error, :no_dir}` will be returned

  Editor process will be started in a PTY.
  """
  @spec run(pid()) :: :ok | {:error, :no_dir | :already_started}
  def run(pid) do
    GenServer.call(pid, :run)
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
  @spec write(pid(), binary()) :: :ok | {:error, reason :: term()}
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

  @impl true
  def init(opts) do
    {:ok,
     %{
       on_output: opts.on_output,
       on_exit: opts.on_exit,
       os_pid: nil,
       exec_pid: nil,
       file_path: nil
     }}
  end

  @impl true
  def handle_call(:run, _from, %{file_path: file_path} = state) do
    cond do
      file_path == nil ->
        {:reply, {:error, :no_dir}, state}

      state.exec_pid == nil ->
        keyspath = file_path |> Path.dirname() |> Path.join("keys.txt")
        {:ok, pid, os_pid} = NvimControls.run_editor(file_path, keyspath, self())

        Logger.debug("Started editor process #{inspect(pid)} with os pid #{inspect(os_pid)}")

        {:reply, :ok, %{state | os_pid: os_pid, exec_pid: pid}}

      true ->
        {:reply, {:error, :already_running}, state}
    end
  end

  def handle_call({:prepare_dir, filename, file_content}, _from, state) do
    root_dir =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:sessions_dir)

    session_name = Vimperfect.Playground.Util.generate_session_name()

    dir = Path.join(root_dir, session_name)
    {:ok, _} = File.rm_rf(dir)

    case ensure_dir(dir) do
      :ok ->
        file_path = Path.join(dir, filename)

        case File.write(file_path, file_content) do
          :ok ->
            {:reply, :ok, %{state | file_path: file_path}}

          err ->
            {:reply, err, state}
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:process_alive?, _from, state) do
    {:reply, state.exec_pid != nil && Process.alive?(state.exec_pid), state}
  end

  def handle_call({:write, data}, _from, state) do
    if state.os_pid != nil do
      # This will ignore any mouse related events, since real ninjas don't use mouse
      if not String.starts_with?(data, "\e[") do
        NvimControls.send_input(state.os_pid, data)
      end

      {:reply, :ok, state}
    else
      {:reply, {:error, :not_running}, state}
    end
  end

  @impl true
  def handle_cast({:resize, cols, rows}, state) do
    if state.os_pid != nil do
      :ok = NvimControls.send_resize(state.os_pid, cols, rows)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:stdout, _os_pid, data}, state) do
    state.on_output.(data)
    {:noreply, state}
  end

  def handle_info({:DOWN, os_pid, :process, _exec_pid, reason}, state) do
    Logger.debug(
      "Editor process #{inspect(os_pid)} finished: #{inspect(reason)}, stopping runner"
    )

    {:stop, reason, %{state | exec_pid: nil, os_pid: nil}}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Editor runner is terminating with reason #{inspect(reason)}")

    if state.exec_pid != nil do
      Logger.debug("Killing editor process #{inspect(state.exec_pid)}")
      :ok = NvimControls.force_stop(state.exec_pid, state.os_pid)
    end

    final_contents =
      if state.file_path != nil do
        # Trimming last newline since `read!` appends a newline for last line in file
        File.read!(state.file_path) |> String.replace_suffix("\n", "")
      else
        nil
      end

    if state.file_path != nil do
      dir = state.file_path |> Path.dirname()
      Logger.debug("Removing session directory #{inspect(dir)}")
      {:ok, _} = File.rm_rf(dir)
    end

    state.on_exit.(reason, final_contents)

    :ok
  end

  defp ensure_dir(dir) do
    case File.mkdir(dir) do
      :ok ->
        :ok

      {:error, :eexist} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
