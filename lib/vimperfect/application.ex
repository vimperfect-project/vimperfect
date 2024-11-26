defmodule Vimperfect.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    ensure_sessions_dir!()

    server_enabled =
      Application.get_env(:vimperfect, Vimperfect.Playground) |> Keyword.get(:server_enable, true)

    server =
      if server_enabled do
        [{Vimperfect.Playground.Ssh.Server, name: Vimperfect.Playground.Ssh.Server}]
      else
        []
      end

    children =
      [
        VimperfectWeb.Telemetry,
        Vimperfect.Repo,
        {DNSCluster, query: Application.get_env(:vimperfect, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Vimperfect.PubSub},
        # Start the Finch HTTP client for sending emails
        {Finch, name: Vimperfect.Finch},
        # Start a worker by calling: Vimperfect.Worker.start_link(arg)
        # {Vimperfect.Worker, arg},
        # Start to serve requests, typically the last entry
        VimperfectWeb.Endpoint,
        {Vimperfect.Playground.SessionContext, name: Vimperfect.Playground.SessionContext}
      ] ++ server

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vimperfect.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VimperfectWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def ensure_sessions_dir!() do
    sessions_dir =
      Application.get_env(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:sessions_dir)

    if not File.dir?(sessions_dir) do
      Logger.debug("Creating missing sessions directory: #{sessions_dir}")
      File.mkdir_p!(sessions_dir)
    end
  end
end
