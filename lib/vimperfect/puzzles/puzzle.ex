defmodule Vimperfect.Puzzles.Puzzle do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :slug}
  schema("puzzles") do
    field :slug, :string
    field :name, :string
    field :description, :string
    field :initial_content, :string
    field :expected_content, :string
    field :filename, :string

    belongs_to :author, Vimperfect.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(puzzle, attrs) do
    # Note: there's no validate for slug since it's going to be generated by the system
    puzzle
    |> cast(attrs, [:name, :slug, :description, :initial_content, :expected_content, :author_id])
    # although author_id can be nil, it cannot be empty when updating from the app
    |> validate_required([:name, :description, :author_id])
    |> validate_length(:name, min: 3, max: 50)
    |> validate_length(:description, min: 30, max: 500)
    |> validate_length(:initial_content, min: 1, max: 5000)
    |> validate_length(:expected_content, max: 5000)
    |> validate_change(:filename, fn :filename, filename ->
      if Vimperfect.Util.valid_filename?(filename) do
        []
      else
        [filename: "not a valid public key"]
      end
    end)
  end
end