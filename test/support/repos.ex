defmodule PaperTrail.Repo do
  use Ecto.Repo, otp_app: :paper_trail, adapter: Ecto.Adapters.Postgres
end

defmodule PaperTrail.UUIDRepo do
  use Ecto.Repo, otp_app: :paper_trail, adapter: Ecto.Adapters.Postgres
end

defmodule User do
  use Ecto.Schema

  import Ecto.Changeset

  schema "users" do
    field(:token, :string)
    field(:username, :string)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:token, :username])
    |> validate_required([:token, :username])
  end
end
