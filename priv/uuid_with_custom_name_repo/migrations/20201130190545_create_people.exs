defmodule PaperTrail.UUIDWithCustomNameRepo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people, primary_key: false) do
      add :uuid, :binary_id, primary_key: true
      add :email, :string, null: false

      timestamps()
    end
  end
end
