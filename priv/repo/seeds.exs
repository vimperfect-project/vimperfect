# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Vimperfect.Repo.insert!(%Vimperfect.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

user =
  Vimperfect.Repo.insert!(%Vimperfect.Accounts.User{
    username: "test_user",
    provider: :github,
    email: "test@test.com"
  })

public_key =
  Vimperfect.Repo.insert!(%Vimperfect.Accounts.PublicKey{
    user_id: user.id,
    key: "totally-fake-key"
  })

puzzles = [
  %Vimperfect.Puzzles.Puzzle{
    slug: "alice-and-bob",
    name: "Alice and Bob",
    description:
      "You need to replace the word in the parentheses with Bob without removing the parentheses.",
    author_id: user.id,
    initial_content: "Hello, my name is (Alice)",
    expected_content: "Hello, my name is (Bob)"
  },
  %Vimperfect.Puzzles.Puzzle{
    slug: "useless-parameters",
    name: "Useless Parameters",
    description: "Leave only the first parameter in the `greet` function definition",
    author_id: user.id,
    filename: "main.ex",
    initial_content: """
    defmodule Main do
      def greet(name, age \\\\ 25) do
        IO.puts("Hello, \#{name}!")
      end
    end
    """,
    expected_content: """
    defmodule Main do
      def greet(name) do
        IO.puts("Hello, \#{name}!")
      end
    end
    """
  }
]

Enum.each(puzzles, fn puzzle ->
  Vimperfect.Repo.insert!(puzzle)
end)
