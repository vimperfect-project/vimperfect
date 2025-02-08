defmodule Vimperfect.Playground.Editor.NvimControls do
  def run_editor(filepath, keyspath, monitor_pid) do
    command = "nvim --clean -W #{keyspath} #{filepath}"
    :exec.run(command, [:monitor, :pty, :stdin, stdout: monitor_pid])
  end

  def send_input(os_pid, data) do
    :exec.send(os_pid, data)
  end

  def send_resize(os_pid, cols, rows) do
    :timer.sleep(100)
    :exec.winsz(os_pid, rows, cols)
  end

  def force_stop(_exec_pid, os_pid) do
    :exec.kill(os_pid, 9)
  end
end
