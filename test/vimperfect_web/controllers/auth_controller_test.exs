defmodule VimperfectWeb.AuthControllerTest do
  alias Vimperfect.AccountsFixtures
  use VimperfectWeb.ConnCase, async: true

  defp get_ueberauth(username \\ "foo", email \\ "foo@example.com") do
    %{
      provider: :github,
      info: %{
        nickname: username,
        email: email
      }
    }
  end

  # TODO TEST:
  # 1. Handles oauth callback properly for new and existing users
  # 2. Handles signout properly
  describe "GET /auth/github/callback" do
    test "successfully logs in a new user from GitHub", %{conn: conn} do
      auth = get_ueberauth()

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/"
      assert conn |> get_session(:user_id) != nil
    end

    test "successfully logs in an existing user from GitHub", %{conn: conn} do
      user = AccountsFixtures.user_fixture()

      auth =
        get_ueberauth(user.username, user.email)

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/"
      assert conn |> get_session(:user_id) == user.id
    end

    test "updates user email if it's changed", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      auth = get_ueberauth(user.username, "new@example.com")

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/"
      assert conn |> get_session(:user_id) == user.id
      user = Vimperfect.Repo.reload!(user)
      assert user.email == "new@example.com"
    end
  end

  describe "GET /auth/signout" do
    test "signout action", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      conn = Plug.Test.init_test_session(conn, user: user)

      conn = get(conn, ~p"/auth/signout")
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :user_id) == nil
    end
  end
end
