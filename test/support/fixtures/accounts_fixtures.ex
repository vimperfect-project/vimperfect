defmodule Vimperfect.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vimperfect.Accounts` context.
  """

  @doc """
  Generate a user with following attributes:
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

  @doc """
  Adds a fixture public key to user and returns the modified user with public keys preloaded
  """
  @spec add_public_key_fixture(User.t()) :: User.t()
  def add_public_key_fixture(user) do
    {:ok, user} =
      Vimperfect.Accounts.add_public_key(
        user,
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDZpN5HUZOjsu6hKpSyd3O7L4a4WI+SW+w5gpbLrK1uCGn5e4W1g+xBQSKFcuz3HAVb1Dn3unQMY8fQq4NUGN9OI+45jMti/Jm0Wdsib6OfKGAAxjrG3khQ8BpqIGb/eY9vgW40FbEr80PCCcgHDlUbvMeH52Qs0ub/ZgAlisddew=="
      )

    user
  end
end
