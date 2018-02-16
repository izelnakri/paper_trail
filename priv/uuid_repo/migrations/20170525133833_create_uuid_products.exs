defmodule PaperTrail.UUIDRepo.Migrations.CreateUuidProducts do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps()
    end

    create table(:items, primary_key: false) do
      add :item_id, :binary_id, primary_key: true
      add :title, :string, null: false

      timestamps()
    end
  end
end
