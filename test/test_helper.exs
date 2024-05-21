Application.start(:postgrex)

Mix.Task.run("ecto.drop")
Mix.Task.run("ecto.create")
Mix.Task.run("ecto.migrate")

PaperTrail.Repo.start_link()
PaperTrail.UUIDRepo.start_link()
PaperTrail.UUIDWithCustomNameRepo.start_link()

ExUnit.configure(seed: 0)

ExUnit.start(capture_log: true)
