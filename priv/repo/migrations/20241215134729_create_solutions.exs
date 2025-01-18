defmodule Vimperfect.Repo.Migrations.CreateSolutions do
  use Ecto.Migration

  def change do
    create table(:solutions) do
      add :original_solution_id, references(:original_solutions, on_delete: :nilify_all)
      add :puzzle_id, references(:puzzles, on_delete: :restrict)
      add :user_id, references(:puzzles, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    # Make sure that a user solution can only be linked once to the same original solution
    create unique_index(:solutions, [:user_id, :original_solution_id])
    create index(:solutions, [:original_solution_id])
    create index(:solutions, [:puzzle_id])
    create index(:solutions, [:user_id])

    create_count_triggers()
  end

  @doc """
  To save computation time, the `similar_count` of the original solution will be updated when a solution is inserted or deleted.
  """
  defp create_count_triggers do
    execute """
            CREATE FUNCTION update_similar_count() RETURNS trigger
            AS $$
            DECLARE
              original_solution_id INTEGER;
              delta INTEGER;
            BEGIN
              IF TG_OP = 'INSERT' THEN
                original_solution_id := NEW.original_solution_id;
                delta := 1;
              ELSIF TG_OP = 'DELETE' THEN
                original_solution_id := OLD.original_solution_id;
                delta := -1;
              ELSIF TG_OP = 'UPDATE' THEN
                RAISE EXCEPTION 'original solution id cannot be changed, you must delete and insert the solution';
              END IF;

              UPDATE original_solutions
              SET similar_count = similar_count + delta
              WHERE id = original_solution_id;

              RETURN NULL;
            END; $$ LANGUAGE plpgsql
            """,
            "DROP update_similar_count"

    execute """
            CREATE TRIGGER increase_simiar_count_on_insert
            AFTER INSERT OR UPDATE OR DELETE ON solutions
            FOR EACH ROW
            EXECUTE FUNCTION update_similar_count()
            """,
            "DROP update_similar_count_on_insert"
  end
end
