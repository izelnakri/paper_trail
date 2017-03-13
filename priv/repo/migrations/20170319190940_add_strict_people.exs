defmodule Repo.Migrations.CreateStrictPeople do
  use Ecto.Migration

  def change do
    create table(:strict_people) do
      add :first_name, :string, null: false
      add :last_name, :string
      add :visit_count, :integer
      add :gender, :boolean
      add :birthdate, :date

      add :company_id, references(:strict_companies), null: false
      add :first_version_id, references(:versions), null: false
      add :current_version_id, references(:versions), null: false

      timestamps()
    end

    create index(:strict_people, [:company_id])
    create index(:strict_people, [:first_version_id])
    create index(:strict_people, [:current_version_id])
  end
end
