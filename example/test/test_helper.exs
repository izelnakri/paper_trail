ExUnit.configure seed: 0

Mix.Task.run "ecto.create", ~w(-r Repo)
Mix.Task.run "ecto.migrate", ~w(-r Repo)

ExUnit.start
