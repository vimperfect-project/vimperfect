defmodule Vimperfect.Config do
  import Config

  def config_runtime!() do
    load_github_creds!()
    load_github_webhook_config!()
  end

  def load_github_webhook_config!() do
    github_repo =
      System.get_env("VIMPERFECT_GITHUB_PUZZLES_REPO") ||
        raise "VIMPERFECT_GITHUB_PUZZLES_REPO is not set"

    webhook_secret =
      System.get_env("VIMPERFECT_GITHUB_WEBHOOK_SECRET") ||
        raise "VIMPERFECT_GITHUB_WEBHOOK_SECRET is not set"

    config :vimperfect, Vimperfect.GithubPuzzles,
      repo: github_repo,
      webhook_secret: webhook_secret
  end

  def load_github_creds!() do
    client_id =
      System.get_env("VIMPERFECT_GITHUB_OAUTH_CLIENT_ID") ||
        raise "VIMPERFECT_GITHUB_OAUTH_CLIENT_ID is not set"

    client_secret =
      System.get_env("VIMPERFECT_GITHUB_OAUTH_CLIENT_SECRET") ||
        raise "VIMPERFECT_GITHUB_OAUTH_CLIENT_SECRET is not set"

    config :ueberauth, Ueberauth.Strategy.Github.OAuth,
      client_id: client_id,
      client_secret: client_secret
  end
end
