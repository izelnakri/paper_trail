defmodule Repo.Migrations.AddPeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :first_name, :string
      add :last_name, :string
      add :visit_count, :integer
      add :gender, :boolean
      add :birthdate, :date

      timestamps
    end
  end
end
