defmodule PaperTrail.Repo.Migrations.AddUniquenessConstraintToCompaniesName do
  use Ecto.Migration

  def change do
    create unique_index(:simple_companies, [:name])
    create unique_index(:strict_companies, [:name])
  end
end
