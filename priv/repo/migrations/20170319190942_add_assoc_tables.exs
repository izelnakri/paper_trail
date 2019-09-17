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

    create table(:assoc_tags) do
      add :name, :string
      timestamps()
    end

    create table(:assoc_posts_tags) do
      add :post_id, references(:assoc_posts), on_delete: :delete_all, on_replace: :delete
      add :tag_id, references(:assoc_tags), on_delete: :delete_all, on_replace: :delete
    end
  end
end
