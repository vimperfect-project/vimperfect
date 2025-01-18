defmodule Vimperfect.Puzzles.Solution do
  @moduledoc """
  Represents a solution entry for a puzzle.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "solutions" do
    belongs_to :user, Vimperfect.Accounts.User
    belongs_to :puzzle, Vimperfect.Puzzles.Puzzle
    belongs_to :original_solution, Vimperfect.Puzzles.OriginalSolution

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(solution, attrs) do
    solution
    |> cast(attrs, [:user_id, :puzzle_id, :original_solution_id])
    |> validate_required([:user_id, :puzzle_id, :original_solution_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:puzzle)
    |> assoc_constraint(:original_solution)
  end
end
