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
