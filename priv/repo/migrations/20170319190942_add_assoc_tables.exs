defmodule Repo.Migrations.CreateAssocTables do
  use Ecto.Migration

  def change do
    create table(:assoc_posts) do
      add :name, :string
      add :content, :string

      timestamps()
    end

    create table(:assoc_comments) do
      add :content, :string
      add :post_id, references(:assoc_posts), on_delete: :delete_all

      timestamps()
    end
  end
end
