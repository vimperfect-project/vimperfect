defmodule Vimperfect.Repo.Migrations.CreateOriginalSolutions do
  use Ecto.Migration

  def change do
    create table(:original_solutions) do
      add :keystrokes, :string, null: false
      add :score, :integer, null: false
      add :similar_count, :integer, default: 0
      add :user_id, references(:users, on_delete: :nilify_all), null: false
      add :puzzle_id, references(:puzzles, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    # Restrict creating same solutions for the same puzzle (as identical solutions should go to `solutions` table)
    create unique_index(:original_solutions, [:keystrokes, :puzzle_id])

    create index(:original_solutions, [:user_id])
    create index(:original_solutions, [:puzzle_id])

    create_pass_solution_ownership_trigger()
  end

  @doc """
  When a user owning an original solution is deleted, there may be other users that had the same solution, so immedieate deletion
  of the original solution may lead to data loss. To avoid this, database will set `user_id` to `NULL` when the whenever then
  original author is deleted. After this, a trigger created by this function will pass the ownership of the original solution
  to the next user that had the same solution, as well as decrementing the `similar_count` of the original solution.
  """
  def create_pass_solution_ownership_trigger() do
    execute """
            CREATE FUNCTION pass_solution_ownership() RETURNS trigger
            AS $$
            DECLARE
              new_owner_id INTEGER;
            BEGIN
              SELECT solutions.user_id
              INTO new_owner_id
              FROM solutions
              WHERE solutions.original_solution_id = OLD.id AND solutions.user_id != OLD.user_id
              ORDER BY created_at ASC
              LIMIT 1;

              IF new_owner_id IS NULL THEN
                DELETE FROM original_solutions WHERE id = OLD.id;
              ELSE
                UPDATE original_solutions
                SET similar_count = similar_count - 1, user_id = new_owner_id
                WHERE id = OLD.id;
              END IF;

            END; $$ LANGUAGE plpgsql
            """,
            "DROP pass_solution_ownership"

    # Runs any time a solution loses its original author
    execute """
            CREATE TRIGGER pass_solution_ownership_trigger
            AFTER UPDATE ON original_solutions
            FOR EACH ROW
            WHEN (NEW.user_id IS NULL)
            EXECUTE FUNCTION pass_solution_ownership()
            """,
            "DROP pass_solution_ownership_trigger"
  end
end
