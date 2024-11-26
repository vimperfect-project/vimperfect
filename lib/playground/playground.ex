defmodule Vimperfect.Playground do
  def config_runtime() do
    import Config

    ssh_system_dir = env_dir!("PLAYGROUND_SSH_SYSTEM_DIR")
    sessions_dir = env_dir!("PLAYGROUND_SESSIONS_DIR")
    ssh_port = port!("PLAYGROUND_SSH_PORT", 22)

    config :vimperfect, Vimperfect.Playground,
      ssh_system_dir: ssh_system_dir,
      ssh_port: ssh_port,
      sessions_dir: sessions_dir
  end

  defp port!(env_var, default) do
    out = System.get_env(env_var) |> Integer.parse()

    case out do
      {port, ""} -> port
      _ -> default
    end
  end

  defp env_dir!(env_var) do
    enabled =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground)
      |> Keyword.get(:server_enable, true)

    dir = System.get_env(env_var)

    if dir != nil and File.dir?(dir) do
      dir
    else
      # No need to check env dir if the server will not be started
      if enabled do
        raise "#{env_var} is required to be an existing directory, but got '#{dir}'"
      end
    end
  end
end
