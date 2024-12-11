defmodule Vimperfect.PuzzlesTest do
  alias Vimperfect.AccountsFixtures
  use Vimperfect.DataCase

  alias Vimperfect.Puzzles

  describe "puzzles" do
    import Vimperfect.PuzzlesFixtures

    test "lists puzzles" do
      user = AccountsFixtures.user_fixture()
      puzzle1 = puzzle_fixture(user)
      puzzle2 = puzzle_fixture(user, "test2", "Test 2")

      puzzles = Puzzles.list_puzzles() |> Enum.map(&Map.get(&1, :id))
      assert puzzles == [puzzle1.id, puzzle2.id]
    end
  end
end
