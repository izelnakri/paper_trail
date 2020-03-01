[![Hex Version](http://img.shields.io/hexpm/v/paper_trail.svg?style=flat)](https://hex.pm/packages/paper_trail) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/paper_trail/PaperTrail.html)

# How does it work?

PaperTrail lets you record every change in your database in a separate database table called ```versions```. Library generates a new version record with associated data every time you run ```PaperTrail.insert/2```, ```PaperTrail.update/2``` or ```PaperTrail.delete/2``` functions. Simply these functions wrap your Repo insert, update or destroy actions in a database transaction, so if your database action fails you won't get a new version.

PaperTrail is assailed with hundreds of test assertions for each release. Data integrity is an important aim of this project, please refer to the strict_mode if you want to ensure data correctness and integrity of your versions. For simpler use cases the default mode of PaperTrail should suffice.

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
  #     content: "You should try it now!", id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #     updated_at: ~N[2016-09-15 21:42:38]},
  #    version: %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #     event: "insert", id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #     item_changes: %{title: "Word on the street is Elixir got its own database versioning library",
  #       content: "You should try it now!", id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #       updated_at: ~N[2016-09-15 21:42:38]},
  #     item_id: 1, item_type: "Post", originator_id: nil, originator: nil, meta: nil}}}

  # => on error(it matches Repo.insert/2):
  # {:error, Ecto.Changeset<action: :insert,
  #  changes: %{title: "Word on the street is Elixir got its own database versioning library", content: "You should try it now!"},
  #  errors: [content: {"is too short", []}], data: #Post<>,
  #  valid?: false>, %{}}

  post = Repo.get!(Post, 1)
  edit_changeset = Post.changeset(post, %{
    title: "Elixir matures fast",
    content: "Future is already here, Elixir is the next step!"
  })

  PaperTrail.update(edit_changeset)
  # => on success:
  # {:ok,
  #  %{model: %Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
  #     title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!",
  #     id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #     updated_at: ~N[2016-09-15 22:00:59]},
  #    version: %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #     event: "update", id: 2, inserted_at: ~N[2016-09-15 22:00:59],
  #     item_changes: %{title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!"},
  #     item_id: 1, item_type: "Post", originator_id: nil, originator: nil
  #     meta: nil}}}

  # => on error(it matches Repo.update/2):
  # {:error, Ecto.Changeset<action: :update,
  #  changes: %{title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!"},
  #  errors: [title: {"is too short", []}], data: #Post<>,
  #  valid?: false>, %{}}

  PaperTrail.get_version(post)
  #  %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "update", id: 2, inserted_at: ~N[2016-09-15 22:00:59],
  #   item_changes: %{title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!"},
  #   item_id: 1, item_type: "Post", originator_id: nil, originator: nil, meta: nil}}}

  updated_post = Repo.get!(Post, 1)

  PaperTrail.delete(updated_post)
  # => on success:
  # {:ok,
  #  %{model: %Post{__meta__: #Ecto.Schema.Metadata<:deleted, "posts">,
  #     title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!",
  #     id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #     updated_at: ~N[2016-09-15 22:00:59]},
  #    version: %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #     event: "delete", id: 3, inserted_at: ~N[2016-09-15 22:22:12],
  #     item_changes: %{title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!",
  #       id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #       updated_at: ~N[2016-09-15 22:00:59]},
  #     item_id: 1, item_type: "Post", originator_id: nil, originator: nil, meta: nil}}}

  Repo.aggregate(Post, :count, :id) # => 0
  PaperTrail.Version.count() # => 3
  # same as Repo.aggregate(PaperTrail.Version, :count, :id)

  PaperTrail.Version.last() # returns the last version in the db by inserted_at
  #  %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "delete", id: 3, inserted_at: ~N[2016-09-15 22:22:12],
  #   item_changes: %{"title" => "Elixir matures fast", content: "Future is already here, Elixir is the next step!", "id" => 1,
  #     "inserted_at" => "2016-09-15T21:42:38",
  #     "updated_at" => "2016-09-15T22:00:59"},
  #   item_id: 1, item_type: "Post", originator_id: nil, originator: nil, meta: nil}
```

PaperTrail is inspired by the ruby gem ```paper_trail```. However, unlike the ```paper_trail``` gem this library actually results in less data duplication, faster and more explicit programming model to version your record changes.

The library source code is minimal and well tested. It is suggested to read the source code.

## Installation

  1. Add paper_trail to your list of dependencies in `mix.exs`:

  ```elixir
    def deps do
      [{:paper_trail, "~> 0.8.2"}]
    end
  ```

  2. configure paper_trail to use your application repo in `config/config.exs`:

  ```elixir
  config :paper_trail, repo: YourApplicationName.Repo
  # if you don't specify this PaperTrail will assume your repo name is Repo
  ```

  3. install and compile your dependency:

  ```mix deps.get && mix compile```

  4. run this command to generate the migration:

  ```mix papertrail.install```

  You might want to edit the types for `:item_id` or `:originator_id` if you're
  using UUID or other types for your primary keys before you execute
  `mix ecto.migrate`.

  5. run the migration:

  ```mix ecto.migrate```

Your application is now ready to collect some history!

#### Does this work with phoenix?

YES! Make sure you do the steps above.

### %PaperTrail.Version{} fields:

| Column Name   | Type    | Description                | Entry Method             |
| ------------- | ------- | -------------------------- | ------------------------ |
| event         | String  | either "insert", "update" or "delete"  | Library generates |
| item_type     | String  | model name of the reference record | Library generates |
| item_id       | configurable (Integer by default) | model id of the reference record | Library generates |
| item_changes  | Map     | all the changes in this version as a map | Library generates |
| originator_id | configurable (Integer by default) | foreign key reference to the creator/owner of this change | Optionally set |
| origin        | String  | short reference to origin(eg. worker:activity-checker, migration, admin:33) | Optionally set |
| meta          | Map     | any extra optional meta information about the version(eg. %{slug: "ausername", important: true}) | Optionally set |
| inserted_at   | Date    | inserted_at timestamp       | Ecto generates |

#### Configuring the types

If you are using UUID or another type for your primary keys, you can configure
the PaperTrail.Version schema to use it.

```elixir
config :paper_trail, item_type: Ecto.UUID,
                     originator_type: Ecto.UUID
```

Remember to edit the types accordingly in the generated migration.

### Version origin references:
PaperTrail records have a string field called ```origin```. ```PaperTrail.insert/2```, ```PaperTrail.update/2```, ```PaperTrail.delete/2``` functions accept a second argument to describe the origin of this version:
```elixir
PaperTrail.update(changeset, origin: "migration")
# or:
PaperTrail.update(changeset, origin: "user:1234")
# or:
PaperTrail.delete(changeset, origin: "worker:delete_inactive_users")
# or:
PaperTrail.insert(new_user_changeset, origin: "password_registration")
# or:
PaperTrail.insert(new_user_changeset, origin: "facebook_registration")
```

### Version originator relationships
You can specify setter/originator relationship to paper_trail versions with ```originator``` assignment. This feature is only possible by specifying `:originator` keyword list for your application configuration:

```elixir
  # in your config/config.exs
  config :paper_trail, originator: [name: :user, model: YourApp.User]
  # For most applications originator should be the user since models can be updated/created/deleted by several users.
```

Note: You will need to recompile your deps after you have added the config for originator.

Then originator name could be used for querying and preloading. Originator setting must be done via ```:originator``` or originator name that is defined in the paper_trail configuration:

```elixir
user = create_user()
# all these set originator_id's for the version records
PaperTrail.insert(changeset, originator: user)
{:ok, result} = PaperTrail.update(edit_changeset, originator: user)
# or you can use :user in the params instead of :originator if this is your config:
# config :paper_trail, originator: [name: :user, model: YourApplication.User]
{:ok, result} = PaperTrail.update(edit_changeset, user: user)
result[:version] |> Repo.preload(:user) |> Map.get(:user) # we can access the user who made the change from the version thanks to originator relationships!
PaperTrail.delete(edit_changeset, user: user)
```

Also make sure you have the foreign-key constraint in the database and in your version migration file.


### Storing version meta data
You might want to add some meta data that doesn't belong to ``originator`` and ``origin`` fields. Such data could be stored in one object named ```meta``` in paper_trail versions. Meta field could be passed as the second optional parameter to PaperTrail.insert/2, PaperTrail.update/2, PaperTrail.delete/2 functions:

```elixir
company = Company.changeset(%Company{}, %{name: "Acme Inc."})
  |> PaperTrail.insert(meta: %{slug: "acme-llc"})
# you can also combine this with an origin:
edited_company = Company.changeset(company, %{name: "Acme LLC"})
  |> PaperTrail.update(origin: "documentation", meta: %{slug: "acme-llc"})
# or even with an originator:
user = create_user()
deleted_company = Company.changeset(edited_company, %{})
  |> PaperTrail.delete(origin: "worker:github", originator: user, meta: %{slug: "acme-llc", important: true})
```

# Strict mode
This is a feature more suitable for larger applications. Models can keep their version references via foreign key constraints. Therefore it would be impossible to delete the first and current version of a model if the model exists in the database, it also makes querying easier and the whole design more relational database/SQL friendly. In order to enable strict mode:

```elixir
# in your config/config.exs
config :paper_trail, strict_mode: true
```

Strict mode expects tracked models to have foreign-key reference to their first_version and current_version. These columns must be named ```first_version_id```, and ```current_version_id``` in their respective model tables. A tracked model example with a migration file:

```elixir
# in the migration file: priv/repo/migrations/create_company.exs
defmodule Repo.Migrations.CreateCompany do
  def change do
    create table(:companies) do
      add :name,       :string, null: false
      add :founded_in, :date

      # null constraints are highly suggested:
      add :first_version_id, references(:versions), null: false
      add :current_version_id, references(:versions), null: false

      timestamps()
    end

    create unique_index(:companies, [:first_version_id])
    create unique_index(:companies, [:current_version_id])
  end
end

# in the model definition:
defmodule Company do
  use Ecto.Schema

  import Ecto.Changeset

  schema "companies" do
    field :name, :string
    field :founded_in, :date

    belongs_to :first_version, PaperTrail.Version
    belongs_to :current_version, PaperTrail.Version, on_replace: :update # on_replace: is important!

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :founded_in])
  end
end
```

When you run PaperTrail.insert/2 transaction, ```first_version_id``` and ```current_version_id``` automagically gets assigned for the model. Example:

```elixir
company = Company.changeset(%Company{}, %{name: "Acme LLC"}) |> PaperTrail.insert
# {:ok,
#  %{model: %Company{__meta__: #Ecto.Schema.Metadata<:loaded, "companies">,
#     name: "Acme LLC", founded_in: nil, id: 1, inserted_at: ~N[2016-09-15 21:42:38],
#     updated_at: ~N[2016-09-15 21:42:38], first_version_id: 1, current_version_id: 1},
#    version: %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
#      event: "insert", id: 1, inserted_at: ~N[2016-09-15 22:22:12],
#      item_changes: %{name: "Acme LLC", founded_in: nil, id: 1, inserted_at: ~N[2016-09-15 21:42:38]},
#      originator_id: nil, origin: "unknown", meta: nil}}}
```

When you PaperTrail.update/2 a model, ```current_version_id``` gets updated during the transaction:

```elixir
edited_company = Company.changeset(company, %{name: "Acme Inc."}) |> PaperTrail.update(origin: "documentation")
# {:ok,
#  %{model: %Company{__meta__: #Ecto.Schema.Metadata<:loaded, "companies">,
#     name: "Acme Inc.", founded_in: nil, id: 1, inserted_at: ~N[2016-09-15 21:42:38],
#     updated_at: ~N[2016-09-15 23:22:12], first_version_id: 1, current_version_id: 2},
#    version: %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
#      event: "update", id: 2, inserted_at: ~N[2016-09-15 23:22:12],
#      item_changes: %{name: "Acme Inc."}, originator_id: nil, origin: "documentation", meta: nil}}}
```

Additionally, you can put a null constraint on ```origin``` column, you should always put an ```origin``` reference to describe who makes the change. This is important for big applications because a model can change from many sources.

### Bang(!) functions:

PaperTrail also supports ```PaperTrail.insert!```, ```PaperTrail.update!```, ```PaperTrail.delete!```. Naming of these functions intentionally match ```Repo.insert!```, ```Repo.update!```, ```Repo.delete!``` functions. If PaperTrail is on strict_mode these bang functions will update the version references of the model just like the normal PaperTrail operations.

Bang functions assume the operation will always be successful, otherwise functions will raise ```Ecto.InvalidChangesetError``` just like ```Repo.insert!```, ```Repo.update!``` and ```Repo.delete!```:

```elixir
  changeset = Post.changeset(%Post{}, %{
    title: "Word on the street is Elixir got its own database versioning library",
    content: "You should try it now!"
  })

  inserted_post = PaperTrail.insert!(changeset)
  # => on success:
  # %Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
  #   title: "Word on the street is Elixir got its own database versioning library",
  #   content: "You should try it now!", id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #   updated_at: ~N[2016-09-15 21:42:38]
  # }
  #
  # => on error raises: Ecto.InvalidChangesetError !!

  inserted_post_version = PaperTrail.get_version(inserted_post)
  # %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "insert", id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #   item_changes: %{title: "Word on the street is Elixir got its own database versioning library",
  #     content: "You should try it now!", id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #     updated_at: ~N[2016-09-15 21:42:38]},
  #   item_id: 1, item_type: "Post", originator_id: nil, originator: nil, meta: nil}

  edit_changeset = Post.changeset(inserted_post, %{
    title: "Elixir matures fast",
    content: "Future is already here, Elixir is the next step!"
  })

  updated_post = PaperTrail.update!(edit_changeset)
  # => on success:
  # %Post{__meta__: #Ecto.Schema.Metadata<:loaded, "posts">,
  #   title: "Elixir matures fast", content: "Future is already here, you deserve to be awesome!",
  #   id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #   updated_at: ~N[2016-09-15 22:00:59]}
  #
  # => on error raises: Ecto.InvalidChangesetError !!

  updated_post_version = PaperTrail.get_version(updated_post)
  # %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "update", id: 2, inserted_at: ~N[2016-09-15 22:00:59],
  #   item_changes: %{title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!"},
  #   item_id: 1, item_type: "Post", originator_id: nil, originator: nil
  #   meta: nil}

  PaperTrail.delete!(updated_post)
  # => on success:
  # %Post{__meta__: #Ecto.Schema.Metadata<:deleted, "posts">,
  #   title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!",
  #   id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #   updated_at: ~N[2016-09-15 22:00:59]}
  #
  # => on error raises: Ecto.InvalidChangesetError !!

  PaperTrail.get_version(updated_post)
  # %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "delete", id: 3, inserted_at: ~N[2016-09-15 22:22:12],
  #   item_changes: %{title: "Elixir matures fast", content: "Future is already here, Elixir is the next step!",
  #   id: 1, inserted_at: ~N[2016-09-15 21:42:38],
  #   updated_at: ~N[2016-09-15 22:00:59]},
  #   item_id: 1, item_type: "Post", originator_id: nil, originator: nil, meta: nil}

  Repo.aggregate(Post, :count, :id) # => 0
  PaperTrail.Version.count() # => 3
  # same as Repo.aggregate(PaperTrail.Version, :count, :id)

  PaperTrail.Version.last() # returns the last version in the db by inserted_at
  #  %PaperTrail.Version{__meta__: #Ecto.Schema.Metadata<:loaded, "versions">,
  #   event: "delete", id: 3, inserted_at: ~N[2016-09-15 22:22:12],
  #   item_changes: %{"title" => "Elixir matures fast", content: "Future is already here, Elixir is the next step!", "id" => 1,
  #     "inserted_at" => "2016-09-15T21:42:38",
  #     "updated_at" => "2016-09-15T22:00:59"},
  #   item_id: 1, item_type: "Post", originator_id: nil, originator: nil, meta: nil}
```

## Working with multi tenancy

Sometimes you have to deal with applications where you need multi tenancy capabilities,
and you want to keep tracking of the versions of your data on different schemas (PostgreSQL)
or databases (MySQL).

You can use the [Ecto.Query prefix](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-prefix)
in order to switch between different schemas/databases for your own data, so
you can specify in your changeset where to store your record. Example:

```elixir
tenant = "tenant_id"
changeset = User.changeset(%User{}, %{first_name: "Izel", last_name: "Nakri"})

changeset
|> Ecto.Queryable.to_query()
|> Map.put(:prefix, tenant)
|> Repo.insert()
```

PaperTrail also allows you to store the `Version` entries generated by your activity in
different schemas/databases by using the value of the element `:prefix` on the options
of the functions. Example:

```elixir
tenant = "tenant_id"

changeset =
  User.changeset(%User{}, %{first_name: "Izel", last_name: "Nakri"})
  |> Ecto.Queryable.to_query()
  |> Map.put(:prefix, tenant)

PaperTrail.insert(changeset, [prefix: tenant])
```

By doing this, you're storing the new `User` entry into the schema/database
specified by the `:prefix` value (`tenant_id`).

Note that the `User`'s changeset it's sent with the `:prefix`, so PaperTrail **will take care of the
storage of the generated `Version` entry in the desired schema/database**. Make sure
to add this prefix to your changeset before the execution of the PaperTrail function if you want to do versioning on a seperate schema.

PaperTrail can also get versions of records or models from different schemas/databases as well
by using the `:prefix` option. Example:

```elixir
tenant = "tenant_id"
id = 1

PaperTrail.get_versions(User, id, [prefix: tenant])
```

## Suggestions
- PaperTrail.Version(s) order matter,
- don't delete your paper_trail versions, instead you can merge them
- If you have a question or a problem, do not hesitate to create an issue or submit a pull request

## Contributing

```
set -a
source .env
mix test --trace
```

# Credits
Many thanks to:
- [Jose Pablo Castro](https://github.com/josepablocastro) - Built the repo configuration for paper_trail
- [Florian Gerhardt](https://github.com/FlorianGerhardt) - Fixed rare compile errors for PaperTrail repos
- [Alex Antonov](https://github.com/asiniy) - Original inventor of the originator feature
- [Moritz Schmale](https://github.com/narrowtux) - UUID primary keys feature
- [Jason Draper](https://github.com/drapergeek) - UUID primary keys feature
- [Josh Taylor](https://github.com/joshuataylor) - Maintenance and new feature suggestions
- [Mitchell Henke](https://github.com/mitchellhenke) - Fixed weird elixir compiler warnings
- [Iván González](https://github.com/dreamingechoes) - Multi tenancy feature and some minor refactors
- [Teo Choong Ping](https://github.com/seymores) - Fixed paper_trail references for newer Elixir versions
- [devvit](https://github.com/devvit) - Added non-regular primary key tracking support
- [rustamtolipov](https://github.com/rustamtolipov) - Added support for Ecto v3
- [gabrielpra1](https://github.com/gabrielpra1) - Added enhanced support for Ecto.Changeset
- [Darren Thompson](https://github.com/DiscoStarslayer) - Added PaperTrail.Multi which makes paper trail transactions more usable
- [Izel Nakri](https://github.com/izelnakri) - The Originator of this library. See what I did there ;)

Additional thanks to:
- [Ruby paper_trail gem](https://github.com/airblade/paper_trail) - Initial inspiration of this project.
- [Ecto](https://github.com/elixir-ecto/ecto) - For the great API.
