# How does it work?

PaperTrail lets you record every change in your database in a seperate database table called ```versions```. Library generates a new version record with associated data every time you run ```PaperTrail.insert/1```, ```PaperTrail.update/1``` or ```PaperTrail.destroy/1``` functions. Simply these functions wrap your Repo insert, update or destroy actions in a database transaction, so if your database action fails you won't get a new version.

```elixir

```

PaperTrail is inspired by the ruby gem ```paper_trail```. However, unlike the ```paper_trail``` gem this library actually results in less data duplication, faster and more explicit programming model to version your record changes.

The library source code is minimal and tested. It is highly suggested that you check it out, there is nothing magical really.

## Installation

  1. Add paper_trail to your list of dependencies in `mix.exs`:

    def deps do
      [{:paper_trail, "~> 0.0.1"}]
    end

  2. install and compile your dependency:

  ```mix deps.compile```

  3. run this command to generate the migration:

  ```mix papertrail.install```

  4. run the migration:

  ```mix ecto.migrate```

Your application is now ready to collect some history!


TODO AREA:

** explain the columns

## Storing version meta data

give originator example


Your versions don't need a model lifecycle callbacks like before_create or before_update for any extra meta data, all your meta data could be stored in one object and that object could be passed as the second optional parameter to PaperTrail.create

## Suggestions

order matter,
don't delete your versions merge them


## Examples

PaperTrail.create/1, PaperTrail.update/1, PaperTrail.destroy/1

every operation has to go through the changeset function

PaperTrail.get_version\2, PaperTrail.get_version\1 PaperTrail.get_versions\2, PaperTrail.get_versions\1

PaperTrail.get_current
