defmodule VimperfectWeb.HomeLive.Index do
  use VimperfectWeb, :live_view
  alias Vimperfect.Accounts

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    if user_id == nil do
      {:ok, socket |> redirect(to: ~p"/")}
    else
      puzzles = Vimperfect.Puzzles.list_puzzles()

      socket =
        socket
        |> assign_new(:user, fn -> Accounts.get_user!(user_id) end)
        |> assign(:puzzles, puzzles)

      {:ok, socket}
    end
  end
end
