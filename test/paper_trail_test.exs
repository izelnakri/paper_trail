defmodule PaperTrailTest do
  use ExUnit.Case
  doctest PaperTrail

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
    @optional_fields ~w()

    def changeset(model, params \\ :empty) do
      model
      |> cast(params, @required_fields, @optional_fields)
    end
  end

  defmodule Person do
    use Ecto.Schema

    import Ecto
    import Ecto.Changeset
    import Ecto.Query

    schema "people" do
      field :first_name, :string
      field :last_name, :string
      field :visit_count, :integer
      field :gender, :boolean
      field :birthdate, Ecto.Date

      timestamps
    end

    @required_fields ~w()
    @optional_fields ~w()

    def changeset(model, params \\ :empty) do
      model
      |> cast(params, @required_fields, @optional_fields)
    end
  end

  test "" do
    assert 1 + 1 == 2
  end
end
