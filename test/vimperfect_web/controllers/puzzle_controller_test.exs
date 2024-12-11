defmodule VimperfectWeb.PuzzleControllerTest do
  alias Vimperfect.PuzzlesFixtures
  alias Vimperfect.AccountsFixtures
  alias Vimperfect.AccountsFixtures
  use VimperfectWeb.ConnCase, async: true

  setup %{conn: conn} do
    user = AccountsFixtures.user_fixture()
    conn = conn |> Plug.Test.init_test_session(%{user_id: user.id})

    %{conn: conn, user: user}
  end

  describe "GET /puzzle/:slug" do
    test "with non-existent puzzle should return 404", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        conn |> get(~p"/puzzle/non-existent-slug")
      end
    end

    test "with existing puzzle should return puzzle page", %{conn: conn, user: user} do
      puzzle = PuzzlesFixtures.puzzle_fixture(user)

      conn = get(conn, ~p"/puzzle/#{puzzle}")
      assert html_response(conn, 200) =~ puzzle.name
    end
  end
end
