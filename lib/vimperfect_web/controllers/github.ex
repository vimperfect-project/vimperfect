defmodule VimperfectWeb.GithubController do
  alias Vimperfect.GithubPuzzles
  require Logger
  use VimperfectWeb, :controller

  def push(conn, %{"commits" => commits, "repository" => %{"full_name" => repo}}) do
    Logger.info("Received push event for repo #{inspect(repo)}")

    expected_repo =
      Application.get_env(:vimperfect, GithubPuzzles)[:repo]

    if repo == expected_repo do
      %{updated: changed_puzzles, removed: removed_puzzles} =
        commits
        |> Enum.map(fn commit ->
          %{added: commit["added"], modified: commit["modified"], removed: commit["removed"]}
        end)
        |> GithubPuzzles.get_changed_puzzles()
        |> IO.inspect()
    else
      Logger.info(
        "Ignoring push event for repo #{inspect(repo)} as this is not the expected repo"
      )
    end

    conn |> put_status(:ok) |> json("OK")
  end
end
