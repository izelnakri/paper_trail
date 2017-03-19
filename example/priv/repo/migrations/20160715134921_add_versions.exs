defmodule Repo.Migrations.AddVersions do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add :event,        :string
      add :item_type,    :string
      add :item_id,      :integer
      add :item_changes, :map
      add :origin,       :string
      add :originator_id, references(:people)
      add :meta,         :map

      add :inserted_at,  :utc_datetime, null: false
    end

    create index(:versions, [:originator_id])
  end
end
