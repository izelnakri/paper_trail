defmodule PaperTrail.UUIDRepo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :item_id,      :binary_id, null: false, primary_key: true
      add :title,        :string, null: false

      timestamps()
    end

    create table(:foo_items) do
      add :title, :string, null: false

      timestamps()
    end

    create table(:bar_items, primary_key: false) do
      add :item_id, :string, primary_key: true
      add :title, :string, null: false

      timestamps()
    end
  end
end
