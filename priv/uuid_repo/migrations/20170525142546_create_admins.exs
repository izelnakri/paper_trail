defmodule PaperTrail.UUIDRepo.Migrations.CreateAdmins do
  use Ecto.Migration

  def change do
    create table(:admins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false

      timestamps()
    end
  end
end
