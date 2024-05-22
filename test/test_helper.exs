Application.start(:postgrex)

Mix.Task.run("ecto.drop")
Mix.Task.run("ecto.create")
Mix.Task.run("ecto.migrate")

PaperTrail.Repo.start_link()
PaperTrail.UUIDRepo.start_link()
PaperTrail.UUIDWithCustomNameRepo.start_link()

ExUnit.configure(seed: 0)

Ecto.Adapters.SQL.Sandbox.mode(PaperTrail.Repo, :auto)
Ecto.Adapters.SQL.Sandbox.mode(PaperTrail.UUIDRepo, :auto)
Ecto.Adapters.SQL.Sandbox.mode(PaperTrail.UUIDWithCustomNameRepo, :auto)

ExUnit.start(capture_log: true)
