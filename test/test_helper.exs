# TODO: strict_mode(check the current_version_id changes on next versions), Test error cases, producer_id, PaperTrail.insert_all

defmodule PaperTrail.Repo do
  use Ecto.Repo, otp_app: :paper_trail
end

defmodule User do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "users" do
    field :token, :string
    field :username, :string

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:token, :username])
    |> validate_required([:token, :username])
  end
end

Mix.Task.run "ecto.create", ~w(-r PaperTrail.Repo)
Mix.Task.run "ecto.migrate", ~w(-r PaperTrail.Repo)

PaperTrail.Repo.start_link

Code.require_file("test/helpers/simple_model_definitions.exs")
Code.require_file("test/helpers/strict_model_definitions.exs")

ExUnit.configure seed: 0

ExUnit.start()
