Application.start(:postgrex)

Mix.Task.run("ecto.drop")
Mix.Task.run("ecto.create")
Mix.Task.run("ecto.migrate")

PaperTrail.Repo.start_link()
PaperTrail.UUIDRepo.start_link()
PaperTrail.UUIDWithCustomNameRepo.start_link()

Code.require_file("test/support/multi_tenant_helper.exs")
Code.require_file("test/support/simple_models.exs")
Code.require_file("test/support/strict_models.exs")
Code.require_file("test/support/uuid_models.exs")
Code.require_file("test/support/uuid_with_custom_name_models.exs")

ExUnit.configure(seed: 0)

ExUnit.start(capture_log: true)
