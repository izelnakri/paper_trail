defmodule PaperTrail.UUIDWithCustomNameRepo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :uuid, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps()
    end
  end
end
