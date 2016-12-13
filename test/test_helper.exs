defmodule PaperTrail.Repo do
  use Ecto.Repo, otp_app: :paper_trail
end

Mix.Task.run "ecto.create", ~w(-r PaperTrail.Repo)
Mix.Task.run "ecto.migrate", ~w(-r PaperTrail.Repo)

defmodule Company do
  use Ecto.Schema

  import Ecto.Changeset

  schema "companies" do
    field :name, :string
    field :is_active, :boolean
    field :website, :string
    field :city, :string
    field :address, :string
    field :facebook, :string
    field :twitter, :string
    field :founded_in, :string

    has_many :people, Person

    timestamps
  end

  @optional_fields ~w(name is_active website city address facebook twitter founded_in)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @optional_fields)
    |> cast_assoc(:people, required: false)
  end
end

defmodule Person do
  use Ecto.Schema

  import Ecto.Changeset

  schema "people" do
    field :first_name, :string
    field :last_name, :string
    field :visit_count, :integer
    field :gender, :boolean
    field :birthdate, Ecto.Date

    belongs_to :company, Company

    timestamps
  end

  @optional_fields ~w(first_name last_name visit_count gender birthdate company_id)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @optional_fields)
    |> foreign_key_constraint(:company_id)
  end
end

PaperTrail.Repo.start_link

ExUnit.configure seed: 0

ExUnit.start()
