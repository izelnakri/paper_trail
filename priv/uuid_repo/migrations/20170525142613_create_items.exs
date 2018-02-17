defmodule PaperTrail.UUIDRepo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :item_id,      :binary_id, null: false, primary_key: true
      add :title,        :string, null: false

      add :inserted_at,  :utc_datetime, null: false
      add :updated_at,  :utc_datetime, null: false
    end
  end
end
