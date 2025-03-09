defmodule Vimperfect.GithubPuzzles do
  @moduledoc """
  This module is responsible for working with GitHub push events and extracting puzzle files from commits.
  """

  @type filename :: binary()

  @type commit :: %{
          added: [filename()],
          removed: [filename()]
        }

  @typedoc """
  A list of puzzle paths (relative to the repo root) that were update or removed in a particular push to a branch. Updated includes
  both added and modified files.
  """
  @type changed_puzzles :: %{
          updated: [filename()],
          removed: [filename()]
        }

  @type puzzle_file :: {filename(), content :: binary()}

  @spec get_file_contents(files :: [filename()]) :: [puzzle_file()]
  def get_file_contents(filenames) do
    []
  end

  @doc """
  Accepts a list of commits and returns a map of puzzle file paths that were added or removed in the commits.
  """
  @spec get_changed_puzzles(commits :: [commit()]) :: %{
          added: [filename()],
          removed: [filename()]
        }
  def get_changed_puzzles(commits) do
    puzzle_directory =
      Application.get_env(:vimperfect, Vimperfect.GithubPuzzles)[:puzzles_directory]

    commits
    |> Enum.reduce(
      %{
        updated: [],
        removed: []
      },
      fn commit, acc ->
        added_puzzles =
          commit.added
          |> Enum.filter(&String.starts_with?(&1, puzzle_directory))

        modified_puzzles =
          commit.modified
          |> Enum.filter(&String.starts_with?(&1, puzzle_directory))

        removed_puzzles =
          commit.removed
          |> Enum.filter(&String.starts_with?(&1, puzzle_directory))

        acc
        |> Map.update!(:updated, &(&1 ++ added_puzzles ++ modified_puzzles))
        |> Map.update!(:removed, &(&1 ++ removed_puzzles))
      end
    )
  end

  # defp fetch
end
