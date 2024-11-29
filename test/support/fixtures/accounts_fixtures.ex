defmodule Vimperfect.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vimperfect.Accounts` context.
  """

  @doc """
  Generate a user with folloing attributes:
  * username: "bob"
  * provider: :github
  * email: "bob@example.com"
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        username: "foo",
        provider: :github,
        email: "foo@example.com"
      })
      |> Vimperfect.Accounts.find_or_create_user()

    user
  end
end
