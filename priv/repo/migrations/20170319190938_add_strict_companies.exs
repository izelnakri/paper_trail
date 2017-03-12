defmodule Repo.Migrations.CreateStrictCompanies do
  use Ecto.Migration

  def change do
    create table(:strict_companies) do
      add :name,       :string
      add :is_active,  :boolean
      add :website,    :string
      add :city,       :string
      add :address,    :string
      add :facebook,   :string
      add :twitter,    :string
      add :founded_in, :string

      add :first_version_id, references(:versions), null: false
      add :current_version_id, references(:versions), null: false

      timestamps()
    end

    create index(:strict_companies, [:first_version_id])
    create index(:strict_companies, [:current_version_id])
  end
end
