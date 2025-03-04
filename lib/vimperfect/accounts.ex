defmodule Vimperfect.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Vimperfect.Accounts.PublicKey
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
  @spec update_user(User.t(), user_attrs()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc """
  Gets a user by public key

  ## Examples
    iex> Accounts.get_user_by_public_key("ssh-rsa ...")
    %User{}

    iex> Accounts.get_user_by_public_key("ssh-rsa does not exist")
    nil
  """
  @spec get_user_by_public_key(String.t()) :: User.t() | nil
  def get_user_by_public_key(public_key) do
    query =
      from u in User, join: p in PublicKey, on: u.id == p.user_id, where: p.key == ^public_key

    Repo.one(query)
  end

  defp get_by_username_and_provider(username, provider) do
    Repo.get_by(User, username: username, provider: provider)
  end

  @doc """
  Preloads user's public keys relation
  """
  def load_public_keys(%User{} = user) do
    user
    |> Repo.preload(:public_keys)
  end

  @doc """
  Adds a public key to a user

  ## Examples
      iex> Accounts.add_public_key(%User{}, "ssh-rsa ...")
      {:ok, %User{}}

      iex> Accounts.add_public_key(%User{}, "non-key")
      {:error, %Ecto.Changeset{}}
  """
  @spec add_public_key(User.t(), String.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def add_public_key(%User{} = user, public_key) do
    public_key =
      Vimperfect.Util.strip_openssh_public_key_comment(public_key)

    insert_res =
      PublicKey.changeset(%PublicKey{}, %{user_id: user.id, key: public_key})
      |> Repo.insert()

    case insert_res do
      {:ok, _} ->
        {:ok, Repo.reload(user) |> load_public_keys()}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Removes a public key by it's ID
  """
  def delete_public_key(%User{} = user, public_key_id) do
    {:ok, _} = %PublicKey{id: public_key_id} |> Repo.delete()
    Repo.reload(user) |> load_public_keys()
  end
end
