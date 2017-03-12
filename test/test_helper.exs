# TODO: strict_mode, Test error cases, producer_id, PaperTrail.insert_all

defmodule PaperTrail.Repo do
  use Ecto.Repo, otp_app: :paper_trail
end

Mix.Task.run "ecto.create", ~w(-r PaperTrail.Repo)
Mix.Task.run "ecto.migrate", ~w(-r PaperTrail.Repo)

PaperTrail.Repo.start_link

Code.require_file("test/helpers/simple_model_definitions.exs")

ExUnit.configure seed: 0

ExUnit.start()
