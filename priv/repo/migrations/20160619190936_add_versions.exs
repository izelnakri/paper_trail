defmodule Repo.Migrations.AddVersions do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add :event,        :string, null: false
      add :item_type,    :string, null: false
      add :item_id,      :integer, null: false
      add :item_changes, :map, null: false
      # add :owner_id # in future
      add :set_by,   :string, size: 50
      add :meta,         :map

      add :inserted_at,  :utc_datetime, null: false
    end

    create index(:versions, [:item_type, :item_id])
    create index(:versions, [:event, :item_type])
    create index(:versions, [:item_type, :inserted_at])
  end
end
