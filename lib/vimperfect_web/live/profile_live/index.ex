defmodule VimperfectWeb.ProfileLive.Index do
  use VimperfectWeb, :live_view

  alias Vimperfect.Accounts

  @impl true
  def mount(_params, session, socket) do
    user =
      session["user_id"] |> Accounts.get_user() |> Accounts.load_public_keys()

    socket =
      socket
      |> assign(:user, user)
      |> reset_form(user)

    {:ok, socket}
  end

  @impl true
  def handle_event("remove-pk", %{"public_key_id" => public_key_id}, socket)
      when is_binary(public_key_id) do
    user = Accounts.delete_public_key(socket.assigns.user, String.to_integer(public_key_id))

    {:noreply,
     socket
     |> put_flash(:info, "Key has been removed successfully.")
     |> assign(:user, user)
     |> reset_form(user)}
  end

  def handle_event("add-pk", %{"public_key" => %{"key" => key, "name" => name}}, socket) do
    case Accounts.add_public_key(socket.assigns.user, name, key) do
      {:ok, user} ->
        {:noreply,
         socket
         |> reset_form(socket.assigns.user)
         |> assign(:user, user)
         |> put_flash(:info, "Key has been added successfully.")
         |> push_navigate(to: ~p"/profile")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:public_key_form, changeset |> to_form())}
    end
  end

  def reset_form(socket, user) do
    new_key_name =
      if user.public_keys == [], do: "Default key", else: "Key #{length(user.public_keys) + 1}"

    assign(
      socket,
      :public_key_form,
      %Accounts.PublicKey{user_id: user.id}
      |> Accounts.PublicKey.changeset(%{key: "", name: new_key_name})
      |> to_form()
    )
  end
end
