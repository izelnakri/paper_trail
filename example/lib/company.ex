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

    timestamps()
  end

  @optional_fields ~w(name is_active website city address facebook twitter founded_in)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @optional_fields)
    |> cast_assoc(:people, required: false)
  end
end
