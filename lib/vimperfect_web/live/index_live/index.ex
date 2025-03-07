defmodule VimperfectWeb.IndexLive.Index do
  use VimperfectWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    # Similar to GitHub style of doing root page. If you're logged in, you'll see the dashboard.
    # Otherwise, you'll see the home page.
    user_id = session["user_id"]

    if user_id != nil do
      IO.inspect(user_id)
      {:ok, socket |> redirect(to: ~p"/home")}
    else
      {:ok, socket, layout: false}
    end
  end

  @impl true
  def handle_event("auth", %{"provider" => "github"}, socket) do
    IO.inspect("auth")
    {:noreply, socket |> redirect(to: ~p"/auth/github")}
  end
end
