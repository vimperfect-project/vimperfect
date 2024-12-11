defmodule Vimperfect.Puzzles do
  @moduledoc """
  The Puzzles context.
  """

  import Ecto.Query, warn: false
  alias Vimperfect.Repo

  alias Vimperfect.Puzzles.Puzzle

  @doc """
  Returns the list of puzzles.

  ## Examples

      iex> list_puzzles()
      [%Puzzle{}, ...]

  """
  def list_puzzles do
    Repo.all(Puzzle)
  end

  @doc """
  Gets a single puzzle.

  Raises `Ecto.NoResultsError` if the Puzzle does not exist.

  ## Examples

      iex> get_puzzle!(123)
      %Puzzle{}

      iex> get_puzzle!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_puzzle_by_slug!(integer()) :: Puzzle.t()
  def get_puzzle_by_slug!(slug), do: Repo.get_by!(Puzzle, slug: slug)

  @doc """
  Get a single puzzle by slug or nil if it doesn't exist.

  ## Examples

      iex> get_puzzle!(123)
      %Puzzle{}

      iex> get_puzzle!(456)
      nil
  """
  @spec get_puzzle_by_slug(String.t()) :: Puzzle.t() | nil
  def get_puzzle_by_slug(slug), do: Repo.get_by(Puzzle, slug: slug)
end
