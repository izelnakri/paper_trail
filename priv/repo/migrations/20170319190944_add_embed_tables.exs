defmodule Repo.Migrations.CreateEmbedTables do
  use Ecto.Migration

  def change do
    create table(:embed_makes) do
      add :name, :string

      timestamps()
    end

    create table(:embed_cars) do
      add :model, :string
      add :make_id, references(:embed_makes), on_delete: :nilify_all
      add :extras, {:array, :map}, default: []

      timestamps()
    end
  end
end
