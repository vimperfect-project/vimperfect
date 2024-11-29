defmodule VimperfectWeb.PageControllerTest do
  alias Vimperfect.AccountsFixtures
  alias Vimperfect.AccountsFixtures
  alias Vimperfect.Accounts.User
  use VimperfectWeb.ConnCase, async: true

  describe "GET /" do
    test "with no user in session should return home page", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Someday here will be a beautiful landing page"
    end

    test "with active user in session should return dashboard page", %{conn: conn} do
      user = AccountsFixtures.user_fixture()

      conn = conn |> Plug.Test.init_test_session(%{user_id: user.id}) |> get(~p"/")
      assert html_response(conn, 200) =~ "Welcome to Vimperfect, #{user.username}"
    end

    test "with non-existent user id in session should reset user assign and return home page",
         %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: 0})
        |> assign(:user, %User{id: 0})
        |> get(~p"/")

      assert conn.assigns[:user] == nil
      assert html_response(conn, 200) =~ "Someday here will be a beautiful landing page"
    end
  end
end
