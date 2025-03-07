defmodule Vimperfect.PuzzlesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vimperfect.Puzzles` context.
  """

  @doc """
  Generate a puzzle.
  """
  def puzzle_fixture(attrs \\ %{}) do
    {:ok, puzzle} =
      attrs
      |> Enum.into(%{

      })
      |> Vimperfect.Puzzles.create_puzzle()

    puzzle
  end
end
