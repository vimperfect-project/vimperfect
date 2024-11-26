defmodule Vimperfect.Playground.Editor.NvimControls do
  # TODO: Add impl for kill

  @behaviour Vimperfect.Playground.Editor.Controls

  @impl true
  def run_editor(filepath, keyspath, monitor_pid) do
    command = "nvim --clean -W #{keyspath} #{filepath}"
    Exexec.run(command, monitor: true, pty: true, stdin: true, stdout: monitor_pid)
  end

  @impl true
  def send_input(os_pid, data) do
    Exexec.send(os_pid, data)
  end

  @impl true
  def run_headless_emulation(filepath, keyspath) do
    Exexec.run("nvim --clean --headless -s #{keyspath} #{filepath}",
      sync: true,
      kill_timeout: 5
    )
  end

  @impl true
  def send_resize(os_pid, cols, rows) do
    path = "/proc/#{os_pid}/fd/0"
    command = "stty rows #{rows} cols #{cols} < #{path}"

    # NOTE: May be slow to run :os.cmd on every resize. Is there a better way to control PTY window size?
    case :os.cmd(String.to_charlist(command)) do
      [] ->
        :ok

      _ ->
        {:error, "Failed to set window size"}
    end
  end

  @impl true
  def force_stop(exec_pid, _os_pid) do
    :ok = Exexec.stop(exec_pid)
  end

  @impl true
  def prepare_dir(
        root_dir,
        session_name,
        filename,
        file_content
      ) do
    dir = Path.join(root_dir, session_name)
    :ok = clear_dir(root_dir, session_name)

    case ensure_dir(dir) do
      :ok ->
        filepath = Path.join(dir, filename)
        keys_path = Path.join(dir, "keys.log")
        File.write(filepath, file_content)
        {:ok, filepath, keys_path}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def clear_dir(root, session_name) do
    dir = Path.join(root, session_name)

    case File.rm_rf(dir) do
      {:ok, _files} ->
        :ok

      {:error, reason, _file} ->
        {:error, reason}
    end
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
