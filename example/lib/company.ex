defmodule Company do
  use Ecto.Schema

  import Ecto
  import Ecto.Changeset
  import Ecto.Query

  schema "companies" do
    field :name, :string
    field :is_active, :boolean
    field :website, :string
    field :city, :string
    field :address, :string
    field :facebook, :string
    field :twitter, :string
    field :founded_in, :string

    timestamps
  end

  @required_fields ~w()
  @optional_fields ~w(name is_active website city address facebook twitter founded_in)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
