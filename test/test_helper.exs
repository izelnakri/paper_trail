Application.start(:postgrex)

Application.put_env(:paper_trail, :ecto_repos, [
  PaperTrail.Repo,
  PaperTrail.UUIDRepo,
  PaperTrail.UUIDWithCustomNameRepo
])

Application.put_env(:paper_trail, :repo, PaperTrail.Repo)
Application.put_env(:paper_trail, :originator, name: :user, model: User)

Mix.Task.run("ecto.drop")
Mix.Task.run("ecto.create")
Mix.Task.run("ecto.migrate")

PaperTrail.Repo.start_link()
PaperTrail.UUIDRepo.start_link()
PaperTrail.UUIDWithCustomNameRepo.start_link()

ExUnit.configure(seed: 0)

ExUnit.start(capture_log: true)
