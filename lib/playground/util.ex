defmodule Vimperfect.Playground.Util do
  alias Vimperfect.Puzzles.Puzzle

  @doc """
  Returns a command string that can be used to open a playground with a specific puzzle.
  It will append a port number if the playground is configured to use a non-standard port (useful for development)

  ## Examples

      iex> Playground.Util.get_ssh_command_for_puzzle(%Puzzle{slug: "demo"}, "localhost")
      "ssh demo@localhost"
  """
  def get_ssh_command_for_puzzle(%Puzzle{slug: user} = _puzzle, host) do
    port = Application.get_env(:vimperfect, Vimperfect.Playground) |> Keyword.get(:ssh_port)
    cmd = "ssh " <> if port != 22, do: "-p #{port}", else: ""

    cmd <> " " <> user <> "@" <> host
  end
end
