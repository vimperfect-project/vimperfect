defmodule Vimperfect.Playground.Editor.NvimControls do
  def run_editor(filepath, keyspath, monitor_pid) do
    command = "nvim --clean -W #{keyspath} #{filepath}"
    Exexec.run(command, monitor: true, pty: true, stdin: true, stdout: monitor_pid)
  end

  def send_input(os_pid, data) do
    Exexec.send(os_pid, data)
  end

  def run_headless_emulation(filepath, keyspath) do
    Exexec.run("nvim --clean --headless -s #{keyspath} #{filepath}",
      sync: true,
      kill_timeout: 5
    )
  end

  def send_resize(os_pid, cols, rows) do
    :exec.winsz(os_pid, rows, cols)
  end

  def force_stop(_exec_pid, os_pid) do
    Exexec.kill(os_pid, 9)
  end

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
