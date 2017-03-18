Mix.Task.run "ecto.create", ~w(-r PaperTrail.Repo)
Mix.Task.run "ecto.migrate", ~w(-r PaperTrail.Repo)

PaperTrail.Repo.start_link

Code.require_file("test/support/simple_models.exs")
Code.require_file("test/support/strict_models.exs")

ExUnit.configure seed: 0

ExUnit.start()
