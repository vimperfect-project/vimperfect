defmodule Vimperfect.Config do
  import Config

  def config_runtime!() do
    load_github_creds_file!()
  end

  def load_github_creds_file!() do
    creds_file =
      System.get_env("VIMPERFECT_GITHUB_CREDS_FILE") ||
        raise """
        environment variable VIMPERFECT_GITHUB_CREDS_FILE is not set, which is required for providing GitHub authentication

        Note: if you're developing for Vimperfect, set this file to priv/secrets/github and separate your client id and secret with a newline
        """

    [client_id, client_secret] = File.read!(creds_file) |> String.split("\n", trim: true)

    config :ueberauth, Ueberauth.Strategy.Github.OAuth,
      client_id: client_id,
      client_secret: client_secret
  end
end
