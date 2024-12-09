defmodule Vimperfect.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoCommons.EmailValidator

  schema "users" do
    field :username, :string
    field :provider, Ecto.Enum, values: [:github]
    field :email, :string

    has_many :public_keys, Vimperfect.Accounts.PublicKey

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :provider])
    |> validate_required([:email, :username, :provider])
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_email(:email)
  end
end
