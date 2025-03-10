defmodule VimperfectWeb.Router do
  use VimperfectWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VimperfectWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug VimperfectWeb.Plugs.SetUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :github_webhooks do
    plug VimperfectWeb.Plugs.ValidateGithubWebhook
  end

  pipeline :auth do
    plug VimperfectWeb.Plugs.EnsureAuth
  end

  scope "/auth", VimperfectWeb do
    pipe_through :browser

    get "/signout", AuthController, :signout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Public routes
  scope "/", VimperfectWeb do
    pipe_through [:browser]

    live "/", IndexLive.Index, :index
  end

  scope "/webhooks", VimperfectWeb do
    pipe_through [:api, :github_webhooks]

    post "/github/push", GithubController, :push
  end

  # Authorized routes
  scope "/", VimperfectWeb do
    pipe_through [:browser, :auth]

    live "/profile", ProfileLive.Index, :index
    live "/home", HomeLive.Index, :index

    live "/puzzles/new", PuzzleLive.New, :new

    get "/puzzles/:slug", PuzzleController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:vimperfect, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: VimperfectWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
