defmodule VimperfectWeb.PageController do
  require Logger
  use VimperfectWeb, :controller

  def home(conn, _params) do
    # Similar to GitHub style of doing root page. If you're logged in, you'll see the dashboard.
    # Otherwise, you'll see the home page.
    if conn.assigns.user != nil do
      puzzles = Vimperfect.Puzzles.list_puzzles()

      conn
      |> assign(:puzzles, puzzles)
      |> render(:dashboard)
    else
      render(conn, :home, layout: false)
    end
  end
end
