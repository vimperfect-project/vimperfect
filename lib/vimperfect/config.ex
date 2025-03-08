defmodule Vimperfect.Config do
  import Config

  def config_runtime!() do
    load_github_creds!()
  end

  def load_github_creds!() do
    client_id =
      System.get_env("VIMPERFECT_GITHUB_CLIENT_ID") ||
        raise "VIMPERFECT_GITHUB_CLIENT_ID is not set"

    client_secret =
      System.get_env("VIMPERFECT_GITHUB_CLIENT_SECRET") ||
        raise "VIMPERFECT_GITHUB_CLIENT_SECRET is not set"

    config :ueberauth, Ueberauth.Strategy.Github.OAuth,
      client_id: client_id,
      client_secret: client_secret
  end
end
