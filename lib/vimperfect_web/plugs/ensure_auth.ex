defmodule VimperfectWeb.Plugs.EnsureAuth do
  require Phoenix.VerifiedRoutes
  import Phoenix.VerifiedRoutes, only: [path: 3]
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # TODO: Redirect to login page instead
    if conn.assigns[:user] == nil do
      conn
      |> redirect(to: path(conn, PageController, ~p"/"))
      |> halt()
    else
      conn
    end
  end
end
