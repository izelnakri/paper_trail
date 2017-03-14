TODO: update the example, update the code examples, setter relationships

[![Build Status](https://circleci.com/gh/izelnakri/paper_trail.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/izelnakri/paper_trail) [![Hex Version](http://img.shields.io/hexpm/v/paper_trail.svg?style=flat)](https://hex.pm/packages/paper_trail) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/paper_trail/PaperTrail.html)

# How does it work?

PaperTrail lets you record every change in your database in a separate database table called ```versions```. Library generates a new version record with associated data every time you run ```PaperTrail.insert/1```, ```PaperTrail.update/1``` or ```PaperTrail.delete/1``` functions. Simply these functions wrap your Repo insert, update or destroy actions in a database transaction, so if your database action fails you won't get a new version.

PaperTrail is assailed with tests for each release. Data integrity is an important purpose of this project, please refer to the strict_mode if you want to ensure data correctness and integrity of your versions. For simpler use cases the default mode of PaperTrail should suffice.

## Example

```elixir
  changeset = Post.changeset(%Post{}, %{
    title: "Word on the street is Elixir got its own database versioning library",
    content: "You should try it now!"
  })

  PaperTrail.insert(changeset)
  # => on success:
  # {:ok,
  #  %{model: %Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
  #     title: "Word on the street is Elixir got its own database versioning library",
  #     content: "You should try it now!", id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #     updated_at: #Ecto.DateTime<2016-09-15 21:42:38>},
  #    version: %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #     event: "insert", id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #     item_changes: %{title: "Word on the street is Elixir got its own database versioning library",
  #       content: "You should try it now!", id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #       updated_at: #Ecto.DateTime<2016-09-15 21:42:38>},
  #     item_id: 1, item_type: "Post", meta: nil}}}

  # => on error(it matches Repo.insert\2):
  # {:error, Ecto.Changeset<action: :insert,
  #  changes: %{title: "Word on the street is Elixir got its own database versioning library", content: "You should try it now!"},
  #  errors: [content: {"is too short", []}], data: #Post<>,
  #  valid?: false>, %{}}

  post = Repo.get!(Post, 1)
  edit_changeset = Post.changeset(post, %{
    title: "Elixir matures fast",
    content: "Future is already here, you deserve to be awesome!"
  })

  PaperTrail.update(edit_changeset)
  # => on success:
  # {:ok,
  #  %{model: %Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
  #     title: "Elixir matures fast", content: "Future is already here, you deserve to be awesome!",
  #     id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #     updated_at: #Ecto.DateTime<2016-09-15 22:00:59>},
  #    version: %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #     event: "update", id: 2, inserted_at: #Ecto.DateTime<2016-09-15 22:00:59>,
  #     item_changes: %{title: "Elixir matures fast", content: "Future is already here, you deserve to be awesome!"},
  #     item_id: 1, item_type: "Post",
  #     meta: nil}}}

  # => on error(it matches Repo.update\2):
  # {:error, Ecto.Changeset<action: :update,
  #  changes: %{title: "Elixir matures fast", content: "Future is already here, you deserve to be awesome!"},
  #  errors: [title: {"is too short", []}], data: #Post<>,
  #  valid?: false>, %{}}

  PaperTrail.get_version(post)
  #  %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "update", id: 2, inserted_at: #Ecto.DateTime<2016-09-15 22:00:59>,
  #   item_changes: %{title: "Elixir matures fast", content: "Future is already here, you deserve to be awesome!"},
  #   item_id: 1, item_type: "Post", meta: nil}}}

  updated_post = Repo.get!(Post, 1)

  PaperTrail.delete(updated_post)
  # => on success:
  # {:ok,
  #  %{model: %Post{__meta__: #Ecto.Schema.Metadata<:deleted, "posts">,
  #     title: "Elixir matures fast", content: "Future is already here, you deserve to be awesome!",
  #     id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #     updated_at: #Ecto.DateTime<2016-09-15 22:00:59>},
  #    version: %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #     event: "delete", id: 3, inserted_at: #Ecto.DateTime<2016-09-15 22:22:12>,
  #     item_changes: %{title: "Elixir matures fast", content: "Future is already here, you deserve to be awesome!",
  #       id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #       updated_at: #Ecto.DateTime<2016-09-15 22:00:59>},
  #     item_id: 1, item_type: "Post", meta: nil}}}

  Repo.aggregate(Post, :count, :id) # => 0
  Repo.aggregate(PaperTrail.Version, :count, :id) # => 3

  last(PaperTrail.Version, :id) |> Repo.one
  #  %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "delete", id: 3, inserted_at: #Ecto.DateTime<2016-09-15 22:22:12>,
  #   item_changes: %{"title" => "Elixir matures fast", content: "Future is already here, you deserve to be awesome!", "id" => 1,
  #     "inserted_at" => "2016-09-15T21:42:38",
  #     "updated_at" => "2016-09-15T22:00:59"},
  #   item_id: 1, item_type: "Post", meta: nil}
```

PaperTrail is inspired by the ruby gem ```paper_trail```. However, unlike the ```paper_trail``` gem this library actually results in less data duplication, faster and more explicit programming model to version your record changes.

The library source code is minimal and tested. It is highly suggested that you check it out.

## Installation

  1. Add paper_trail to your list of dependencies in `mix.exs`:

  ```elixir
    def deps do
      [{:paper_trail, "~> 0.5.0"}]
    end
  ```

  2. configure paper_trail to use your application repo in `config/config.exs`:

  ```elixir
  config :paper_trail, repo: YourApplicationName.Repo
  ```

  3. install and compile your dependency:

  ```mix deps.compile```

  4. run this command to generate the migration:

  ```mix papertrail.install```

  5. run the migration:

  ```mix ecto.migrate```

Your application is now ready to collect some history!

## Does this work with phoenix?

YES! Make sure you do the steps.

## %PaperTrail.Version{} fields:

Explain the fields:


## Version set_by references:
PaperTrail records have a string field called ````set_by```. PaperTrail.insert/1, PaperTrail.update/1, PaperTrail.delete/1 functions accepts a second argument for the originator. Example:
```elixir
PaperTrail.update(changeset, set_by: "migration")
# or:
PaperTrail.update(changeset, set_by: "user:1234")
# or:
PaperTrail.delete(changeset, set_by: "worker:delete_inactive_users")
```

## Storing setter relationships
You could specify setter relationship to `paper_trail` versions. This is doable by specifying `:setter` keyword list for your application:

```elixir
  config :paper_trail, setter: [name: :user, model: YourApp.User]
  # For most application setter will be user, models can be updated/created/deleted by several users.
```

```elixir

```

# Strict mode
This is a feature more suitable for larger applications where models keep their version references via foreign key constraints. Thus it would be impossible to delete the first and current version of a model. In order to enable this:

```elixir
# in your config/config.exs
config :paper_trail, strict_mode: true
```
Strict mode expects tracked models to have foreign-key reference to their first_version and current_version. These columns should be named ```first_version_id```, and ```current_version_id``` in their respective model tables. A tracked model example with a migration file:

```elixir
# in the migration file: priv/repo/migrations/create_company.exs
defmodule Repo.Migrations.AddVersions do
  def change do
    create table(:companies) do
      add :name,       :string, null: false
      add :founded_in, :string

      add :first_version_id, references(:versions), null: false
      add :current_version_id, references(:versions), null: false

      timestamps()
    end

    create index(:companies, [:first_version_id])
    create index(:companies, [:current_version_id])
  end
end

# in the model definition:
defmodule StrictCompany do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :name, :string
    field :founded_in, :string

    belongs_to :first_version, PaperTrail.Version
    belongs_to :current_version, PaperTrail.Version, on_replace: :update

    timestamps()
  end
end
```

When you run PaperTrail.insert/1 transaction, insert_version_id and current_version_id gets assigned for the model. Example:

```elixir

```

When you update a model, current_version_id gets updated during the transaction. Example:

```elixir

```

If the version set_by field isn't provided with a value default set_by be "unknown". Set_by column has a null constraint on strict_mode on purpose, you should really put a set_by to reference who initiated this change in the database.

## Storing version meta data
You might want to add some meta data that doesnt belong to ``setter_id``, ``set_by`` fields. Such data could be stored in one object name meta in papertrail versions. Meta field could be passed as the second optional parameter to PaperTrail.insert || PaperTrail.update || PaperTrail.delete functions:

```elixir

```

## Suggestions
- PaperTrail.Version(s) order matter,
- don't delete your paper_trail versions, instead you can merge them

## TODO
** remove wrong Elixir compiler errors
** explain the columns
