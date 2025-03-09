defmodule Vimperfect.Puzzles do
  @moduledoc """
  The Puzzles context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Vimperfect.Puzzles.Solution
  alias Vimperfect.Puzzles.OriginalSolution
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
  @spec get_puzzle_by_slug!(integer()) :: Puzzle
  def get_puzzle_by_slug!(slug), do: Repo.get_by!(Puzzle, slug: slug)

  @doc """
  Get a single puzzle by slug or nil if it doesn't exist.

  ## Examples

      iex> get_puzzle!(123)
      %Puzzle{}

      iex> get_puzzle!(456)
      nil
  """
  @spec get_puzzle_by_slug(String.t()) :: Puzzle | nil
  def get_puzzle_by_slug(slug), do: Repo.get_by(Puzzle, slug: slug)

  @doc """
  Saves the user solution to the database.
  """
  @spec submit_solution!(
          {solution :: binary(), score :: integer()},
          user :: Vimperfect.Accounts.User,
          puzzle :: Puzzle
        ) :: Solution | :ignored
  def submit_solution!({solution, score}, user, puzzle) do
    existing = get_user_solution_by_keystrokes(user, puzzle, solution)

    if existing == nil do
      original_solution = get_or_create_original_solution(solution, score, user, puzzle)
      Logger.debug("Got original solution: #{inspect(original_solution)}")

      %Solution{}
      |> Solution.changeset(%{
        user_id: user.id,
        puzzle_id: puzzle.id,
        original_solution_id: original_solution.id
      })
      |> Repo.insert!()
    else
      :ignored
    end
  end

  defp get_or_create_original_solution(solution, score, user, puzzle) do
    case get_original_solution_by_keystrokes(puzzle, solution) do
      nil ->
        %OriginalSolution{}
        |> OriginalSolution.changeset(%{
          keystrokes: solution,
          user_id: user.id,
          puzzle_id: puzzle.id,
          score: score
        })
        |> Repo.insert!()

      s ->
        s
    end
  end

  @doc """
  Gets user solution for a puzzle by keystrokes
  """
  @spec get_user_solution_by_keystrokes(User, Puzzle, String.t()) :: Solution | term() | nil
  def get_user_solution_by_keystrokes(user, puzzle, keystrokes) do
    query =
      from s in Solution,
        join: os in OriginalSolution,
        on: s.original_solution_id == os.id,
        where:
          s.user_id == ^user.id and s.puzzle_id == ^puzzle.id and os.keystrokes == ^keystrokes

    Repo.one(query)
  end

  @doc """
  Gets original solution by keystrokes
  """
  @spec get_original_solution_by_keystrokes(Puzzle, String.t()) :: OriginalSolution | nil
  def get_original_solution_by_keystrokes(puzzle, keystrokes) do
    query =
      from os in OriginalSolution,
        where: os.keystrokes == ^keystrokes and os.puzzle_id == ^puzzle.id

    Repo.one(query)
  end

  @doc "Checks if the given slug is valid"
  def valid_slug?(slug) do
    get_puzzle_slug(slug) == slug
  end

  defp get_puzzle_slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end

  @doc """
  Gets a single puzzle.

  Raises if the Puzzle does not exist.

  ## Examples

      iex> get_puzzle!(123)
      %Puzzle{}

  """
  def get_puzzle!(id) do
    Repo.get!(Puzzle, id)
  end

  @doc """
  Creates a puzzle.

  ## Examples

      iex> create_puzzle(%{field: value})
      {:ok, %Puzzle{}}

      iex> create_puzzle(%{field: bad_value})
      {:error, ...}

  """
  def create_puzzle(author_id, attrs \\ %{}) do
    %Puzzle{author_id: author_id}
    |> change_puzzle(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a puzzle.

  ## Examples

      iex> update_puzzle(puzzle, %{field: new_value})
      {:ok, %Puzzle{}}

      iex> update_puzzle(puzzle, %{field: bad_value})
      {:error, ...}

  """
  def update_puzzle(%Puzzle{} = puzzle, attrs) do
    raise "TODO"
  end

  @doc """
  Deletes a Puzzle.

  ## Examples

      iex> delete_puzzle(puzzle)
      {:ok, %Puzzle{}}

      iex> delete_puzzle(puzzle)
      {:error, ...}

  """
  def delete_puzzle(%Puzzle{} = puzzle) do
    raise "TODO"
  end

  @doc """
  Returns a data structure for tracking puzzle changes.

  ## Examples

      iex> change_puzzle(puzzle)
      %Todo{...}

  """
  def change_puzzle(%Puzzle{} = puzzle, attrs \\ %{}) do
    puzzle
    |> Puzzle.changeset(attrs)
  end
end
