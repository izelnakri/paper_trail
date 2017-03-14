defmodule Repo.Migrations.AddVersions do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add :event,        :string, null: false
      add :item_type,    :string, null: false
      add :item_id,      :integer, null: false
      add :item_changes, :map, null: false
      add :originator_id, references(:users) # you can change users to your own foreign key constraint
      add :origin,   :string, size: 50
      add :meta,         :map

      add :inserted_at,  :utc_datetime, null: false
    end

    create index(:versions, [:originator_id])
    create index(:versions, [:item_type, :item_id])
    create index(:versions, [:item_type, :inserted_at])
    # create index(:versions, [:event, :item_type])
  end
end
