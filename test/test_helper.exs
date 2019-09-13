Mix.Task.run("ecto.drop")
Mix.Task.run("ecto.create")
Mix.Task.run("ecto.migrate")

PaperTrail.Repo.start_link()
PaperTrail.UUIDRepo.start_link()

Code.require_file("test/support/simple_models.ex")
Code.require_file("test/support/strict_models.ex")
Code.require_file("test/support/uuid_models.ex")
Code.require_file("test/support/multi_tenant_helper.exs")
Code.require_file("test/support/assoc_models.ex")

ExUnit.configure(seed: 0)

ExUnit.start()
