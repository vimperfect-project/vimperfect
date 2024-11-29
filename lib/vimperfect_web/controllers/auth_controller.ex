defmodule VimperfectWeb.AuthController do
  alias Vimperfect.Accounts
  use VimperfectWeb, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_data =
      %{email: auth.info.email, username: auth.info.nickname, provider: "github"}

    with {:ok, user} <- Accounts.find_or_create_user(user_data),
         {:ok, user} <- Accounts.update_user(user, %{email: auth.info.email}) do
      conn
      |> put_session(:user_id, user.id)
      |> redirect(to: ~p"/")
    else
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Something went wrong, please try again")
        |> redirect(to: ~p"/")
    end
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end
