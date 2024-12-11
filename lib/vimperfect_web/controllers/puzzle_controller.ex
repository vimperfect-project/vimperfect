defmodule VimperfectWeb.PuzzleController do
  require Logger
  use VimperfectWeb, :controller

  def show(conn, %{"slug" => slug} = _params) do
    puzzle = Vimperfect.Puzzles.get_puzzle_by_slug!(slug)

    conn
    |> assign(:puzzle, puzzle)
    |> render(:show)
  end
end
