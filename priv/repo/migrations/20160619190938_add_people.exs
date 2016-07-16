defmodule Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :first_name, :string
      add :last_name, :string
      add :visit_count, :integer
      add :gender, :boolean
      add :birthdate, :date

      add :company_id, references(:companies), null: false

      timestamps
    end

    create index(:people, [:company_id])
  end
end
