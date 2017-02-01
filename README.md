[![Build Status](https://circleci.com/gh/izelnakri/paper_trail.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/izelnakri/paper_trail) [![Hex Version](http://img.shields.io/hexpm/v/paper_trail.svg?style=flat)](https://hex.pm/packages/paper_trail) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/paper_trail/PaperTrail.html)

# How does it work?

PaperTrail lets you record every change in your database in a seperate database table called ```versions```. Library generates a new version record with associated data every time you run ```PaperTrail.insert/1```, ```PaperTrail.update/1``` or ```PaperTrail.delete/1``` functions. Simply these functions wrap your Repo insert, update or destroy actions in a database transaction, so if your database action fails you won't get a new version.

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
  #     event: "create", id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #     item_changes: %{title: "Word on the street is Elixir got its own database versioning library",
  #       content: "You should try it now!", id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #       updated_at: #Ecto.DateTime<2016-09-15 21:42:38>},
  #     item_id: 1, item_type: "Post", meta: nil}}}

  # => on error:
  # {:error, :model,
  #  Ecto.Changeset<action: :insert,
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

  # => on error:
  # {:error, :model,
  #  Ecto.Changeset<action: :update,
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
  #     event: "destroy", id: 3, inserted_at: #Ecto.DateTime<2016-09-15 22:22:12>,
  #     item_changes: %{title: "Elixir matures fast", content: "Future is already here, you deserve to be awesome!",
  #       id: 1, inserted_at: #Ecto.DateTime<2016-09-15 21:42:38>,
  #       updated_at: #Ecto.DateTime<2016-09-15 22:00:59>},
  #     item_id: 1, item_type: "Post", meta: nil}}}

  Repo.aggregate(Post, :count, :id) # => 0
  Repo.aggregate(PaperTrail.Version, :count, :id) # => 3

  last(PaperTrail.Version, :id) |> Repo.one
  #  %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "destroy", id: 3, inserted_at: #Ecto.DateTime<2016-09-15 22:22:12>,
  #   item_changes: %{"title" => "Elixir matures fast", content: "Future is already here, you deserve to be awesome!", "id" => 1,
  #     "inserted_at" => "2016-09-15T21:42:38",
  #     "updated_at" => "2016-09-15T22:00:59"},
  #   item_id: 1, item_type: "Post", meta: nil}
```

PaperTrail is inspired by the ruby gem ```paper_trail```. However, unlike the ```paper_trail``` gem this library actually results in less data duplication, faster and more explicit programming model to version your record changes.

The library source code is minimal and tested. It is highly suggested that you check it out, it isn't rocket science.

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

  5. If you do not wish to use `:utc_datetime` for storing your timestamps, change the migration to `:naive_datetime`.
     This was changed in Ecto 2.1, see the [CHANGELOG.md](https://github.com/elixir-ecto/ecto/blob/v2.1/CHANGELOG.md) for
     more details.

  5. run the migration:

  ```mix ecto.migrate```

Your application is now ready to collect some history!

## Does this work with phoenix?

YES! Make sure you do the steps.

TODO AREA:

** remove wrong Elixir compiler errors

** explain the columns

## Storing version meta data

Your versions don't need a model lifecycle callbacks like before_create or before_update for any extra meta data, all your meta data could be stored in one object and that object could be passed as the second optional parameter to PaperTrail.insert || PaperTrail.update || PaperTrail.delete

## Suggestions

- PaperTrail.Version(s) order matter,
- don't delete your paper_trail versions, instead you can merge them
