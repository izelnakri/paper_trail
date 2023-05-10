defmodule Repo.Migrations.AddUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :token, :string, null: false
      add :username, :string, null: false

      timestamps()
    end

    create index(:users, [:token])
  end
end
