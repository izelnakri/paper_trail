Mix.Task.run "ecto.create"
Mix.Task.run "ecto.migrate"

PaperTrail.Repo.start_link
PaperTrail.UUIDRepo.start_link

Code.require_file("test/support/simple_models.exs")
Code.require_file("test/support/strict_models.exs")
Code.require_file("test/support/uuid_models.exs")

ExUnit.configure seed: 0

ExUnit.start()
