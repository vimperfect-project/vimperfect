defmodule Vimperfect.Puzzles.OriginalSolution do
  @moduledoc """
  To save up space, only unique solutions for a puzzle will be stored in this table, the actual puzzle entries are represented
  by the `Vimperfect.Puzzles.Solution` schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "original_solutions" do
    field :keystrokes, :string
    field :score, :integer
    field :similar_count, :integer

    belongs_to :user, Vimperfect.Accounts.User
    belongs_to :puzzle, Vimperfect.Puzzles.Puzzle

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(original_solution, attrs) do
    original_solution
    |> cast(attrs, [:keystrokes, :puzzle_id, :user_id, :score])
    |> validate_required([:keystrokes, :puzzle_id, :user_id, :score])
    |> assoc_constraint(:user)
    |> assoc_constraint(:puzzle)
  end
end
