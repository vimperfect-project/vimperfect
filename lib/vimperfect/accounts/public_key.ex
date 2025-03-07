defmodule Vimperfect.Accounts.PublicKey do
  @moduledoc """
  Used to represent a public key for a user.
  The public key format will be checked by the `Vimperfect.Util.valid_openssh_public_key?/1` function.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "public_keys" do
    field :key, :string
    field :name, :string

    belongs_to :user, Vimperfect.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(public_key, attrs) do
    public_key
    |> cast(attrs, [:name, :key, :user_id])
    |> validate_required([:name, :key, :user_id])
    |> assoc_constraint(:user)
    |> validate_change(:key, fn :key, key ->
      if Vimperfect.Util.valid_openssh_public_key?(key) do
        []
      else
        [key: "not a valid public key"]
      end
    end)
    |> unique_constraint([:name, :user_id],
      message: "you already have a key named this way"
    )
    |> unique_constraint(:key,
      message: "this key is already used"
    )
  end
end
