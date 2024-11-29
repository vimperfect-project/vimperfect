defmodule Vimperfect.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Vimperfect.Repo

  alias Vimperfect.Accounts.User
  @type user_attrs :: %{username: String.t(), provider: atom(), email: String.t()}

  @doc """
  Finds a user based on username and provider, creates the user in case it doesn't exist.

  ## Examples

      iex> {:ok, user1} = Vimperfect.Accounts.find_or_create_user(%{username: "kwinso", provider: :github, email: "email@example.com"})
      {:ok, %Vimperfect.Accounts.User{}}

      iex> {:ok, user1} = Vimperfect.Accounts.find_or_create_user(%{username: "bob", provider: :github, email: "bob@example.com"})
      ...> {:ok, user2} = Vimperfect.Accounts.find_or_create_user(%{username: "bob", provider: :github, email: "bob@example.com"})
      ...> user1.id == user2.id
      true

  """
  @spec find_or_create_user(user_attrs()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create_user(attrs) do
    case get_by_username_and_provider(attrs.username, attrs.provider) do
      nil ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end

  @doc """
  Updates a user, raises if attrs are invalid.
  """
  @spec update_user(User.t(), user_attrs()) :: User.t()
  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  defp get_by_username_and_provider(username, provider) do
    Repo.get_by(User, username: username, provider: provider)
  end
end
