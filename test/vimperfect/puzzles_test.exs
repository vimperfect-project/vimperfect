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

  describe "puzzles" do
    alias Vimperfect.Puzzles.Puzzle

    import Vimperfect.PuzzlesFixtures

    @invalid_attrs %{}

    test "list_puzzles/0 returns all puzzles" do
      puzzle = puzzle_fixture()
      assert Puzzles.list_puzzles() == [puzzle]
    end

    test "get_puzzle!/1 returns the puzzle with given id" do
      puzzle = puzzle_fixture()
      assert Puzzles.get_puzzle!(puzzle.id) == puzzle
    end

    test "create_puzzle/1 with valid data creates a puzzle" do
      valid_attrs = %{}

      assert {:ok, %Puzzle{} = puzzle} = Puzzles.create_puzzle(valid_attrs)
    end

    test "create_puzzle/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Puzzles.create_puzzle(@invalid_attrs)
    end

    test "update_puzzle/2 with valid data updates the puzzle" do
      puzzle = puzzle_fixture()
      update_attrs = %{}

      assert {:ok, %Puzzle{} = puzzle} = Puzzles.update_puzzle(puzzle, update_attrs)
    end

    test "update_puzzle/2 with invalid data returns error changeset" do
      puzzle = puzzle_fixture()
      assert {:error, %Ecto.Changeset{}} = Puzzles.update_puzzle(puzzle, @invalid_attrs)
      assert puzzle == Puzzles.get_puzzle!(puzzle.id)
    end

    test "delete_puzzle/1 deletes the puzzle" do
      puzzle = puzzle_fixture()
      assert {:ok, %Puzzle{}} = Puzzles.delete_puzzle(puzzle)
      assert_raise Ecto.NoResultsError, fn -> Puzzles.get_puzzle!(puzzle.id) end
    end

    test "change_puzzle/1 returns a puzzle changeset" do
      puzzle = puzzle_fixture()
      assert %Ecto.Changeset{} = Puzzles.change_puzzle(puzzle)
    end
  end
end
