defmodule Repo.Migrations.CreateSimpleCompanies do
  use Ecto.Migration

  def change do
    create table(:simple_companies) do
      add :name,       :string, null: false
      add :is_active,  :boolean
      add :website,    :string
      add :city,       :string
      add :address,    :string
      add :facebook,   :string
      add :twitter,    :string
      add :founded_in, :string
      add :location,   :map

      timestamps()
    end
  end
end
