defmodule Vimperfect.PuzzlesFixtures do
  alias Vimperfect.Repo
  alias Vimperfect.Puzzles.Puzzle

  def puzzle_fixture(author, slug \\ "test", name \\ "Test") do
    puzzle =
      %Puzzle{
        slug: slug,
        name: name,
        description: "Test description",
        initial_content: "hello, world!\nIt's nice to see you again",
        expected_content: "hello",
        author: author
      }
      |> Repo.insert!()

    puzzle
  end
end
