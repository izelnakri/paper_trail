defmodule Example.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name,       :string
      add :is_active,  :string
      add :website,    :string
      add :city,       :string
      add :address,    :string
      add :facebook,   :string
      add :twitter,    :string
      add :founded_in, :string

      timestamps
    end
  end
end
