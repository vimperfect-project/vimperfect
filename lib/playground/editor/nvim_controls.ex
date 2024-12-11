defmodule Vimperfect.Playground.Editor.NvimControls do
  def run_editor(filepath, keyspath, monitor_pid) do
    command = "nvim --clean -W #{keyspath} #{filepath}"
    Exexec.run(command, monitor: true, pty: true, stdin: true, stdout: monitor_pid)
  end

  def send_input(os_pid, data) do
    Exexec.send(os_pid, data)
  end

  def send_resize(os_pid, cols, rows) do
    :exec.winsz(os_pid, rows, cols)
  end

  def force_stop(_exec_pid, os_pid) do
    Exexec.kill(os_pid, 9)
  end
end
