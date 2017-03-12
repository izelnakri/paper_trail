defmodule Repo.Migrations.AddVersions do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add :event,        :string
      add :item_type,    :string
      add :item_id,      :integer
      add :item_changes, :map
      # add :producer_id # in future
      add :produced_by,   :string, size: 50
      add :meta,         :map

      add :inserted_at,  :utc_datetime, null: false
    end
  end
end
