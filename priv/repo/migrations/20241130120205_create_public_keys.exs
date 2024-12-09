defmodule Vimperfect.Repo.Migrations.CreatePublicKeys do
  use Ecto.Migration

  def change do
    create table(:public_keys) do
      add :key, :string, null: false
      add :user_id, references(:users, validate: true, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:public_keys, [:user_id])
    create unique_index(:public_keys, [:key])
  end
end
