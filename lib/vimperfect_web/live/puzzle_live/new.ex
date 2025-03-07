defmodule VimperfectWeb.PuzzleLive.New do
  alias Vimperfect.Puzzles.Puzzle
  alias Vimperfect.Accounts
  use VimperfectWeb, :live_view

  alias Vimperfect.Puzzles

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket |> assign_new(:user, fn -> Accounts.get_user(session["user_id"]) end)

    form =
      %Puzzle{}
      |> Puzzles.change_puzzle(%{filename: "input.txt"})
      |> to_form()

    {:ok,
     socket
     |> assign(:puzzle_form, form)
     |> assign(:custom_slug, false)}
  end

  @impl true
  def handle_event("save", %{"puzzle" => params}, socket) do
    case Puzzles.create_puzzle(socket.assigns.user.id, params) do
      {:ok, puzzle} ->
        {:noreply,
         socket
         |> put_flash(:info, "Puzzle created successfully")
         |> push_navigate(to: ~p"/puzzles/#{puzzle}")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:puzzle_form, changeset |> to_form())}
    end
  end

  def handle_event("validate", %{"puzzle" => params}, socket) do
    params = apply_automatic_slug(socket, params)

    form =
      %Puzzle{}
      |> Puzzles.change_puzzle(params)
      |> to_form(action: :validate)

    {:noreply,
     socket
     |> assign(:puzzle_form, form)}
  end

  def handle_event("slug-changed", _params, socket) do
    IO.inspect("Slug changes")

    # If user chooses to input a custom slug, we should track it in order to not update slug anymore to be exact mirror of the name
    {:noreply, assign(socket, :custom_slug, true)}
  end

  defp apply_automatic_slug(socket, params) do
    if socket.assigns.custom_slug == false do
      params
      |> Map.put("slug", Puzzles.get_puzzle_slug(params["name"] || ""))
      # Since we synthetically change the slug, we should mark it as used so errors are shown
      |> Map.delete("_unused_slug")
    else
      # TODO: Maybe implement ability to automatically fix the slug for the user instead of doing nothing?
      # Note: done with hooks https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook
      params
    end
  end
end
