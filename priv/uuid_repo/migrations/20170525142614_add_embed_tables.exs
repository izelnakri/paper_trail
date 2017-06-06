defmodule Repo.Migrations.CreateEmbedTables do
  use Ecto.Migration

  def change do
    create table(:embed_makes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      timestamps()
    end

    create table(:embed_cars, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :model, :string
      add :make_id, references(:embed_makes, type: :binary_id), on_delete: :nilify_all
      add :extras, {:array, :map}, default: []

      timestamps()
    end
  end
end
