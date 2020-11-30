defmodule Repo.Migrations.CreateSimplePeople do
  use Ecto.Migration

  def change do
    create table(:simple_people) do
      add :first_name, :string, null: false
      add :last_name, :string
      add :visit_count, :integer
      add :gender, :boolean
      add :birthdate, :date
      add :singular, :map
      add :plural, {:array, :map}

      add :company_id, references(:simple_companies), null: false

      timestamps()
    end

    create index(:simple_people, [:company_id])
  end
end
