defmodule Vimperfect.Repo.Migrations.CreatePuzzles do
  use Ecto.Migration

  def change do
    create table(:puzzles) do
      add :slug, :string, null: false
      add :name, :string, null: false, size: 50
      add :description, :text, null: false
      add :initial_content, :text, null: false
      add :expected_content, :text, null: false
      add :filename, :string, size: 30

      # Using nilify all will allow to keep their puzzles even if they are deleted
      # A puzzle without an author belongs to the system
      add :author_id, references(:users, on_delete: :nilify_all),
        null: true,
        comment: "The user who created the puzzle"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:puzzles, [:name])
    create unique_index(:puzzles, [:slug])
    create index(:puzzles, [:author_id])
  end
end
