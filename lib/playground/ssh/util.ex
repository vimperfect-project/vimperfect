defmodule Vimperfect.Playground.Ssh.Util do
  def addr_to_string({ip, port}) do
    ip =
      ip
      |> :inet.ntoa()
      |> to_string()

    "#{ip}:#{port}"
  end
end
