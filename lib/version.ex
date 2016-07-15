defmodule PaperTrail.Version do
  use Ecto.Schema

  import Ecto
  import Ecto.Changeset
  import Ecto.Query

  # how to record column changes in migration ?

  schema "versions" do
    field :event, :string
    field :item_type, :string
    field :item_id, :integer
    field :item_changes, :map
    field :meta, :map

    timestamps(updated_at: false)
  end

  @required_fields ~w(event item_type item_id created_at)
  @optional_fields ~w(meta)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
