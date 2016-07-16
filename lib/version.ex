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

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> validate_required(~w(event item_type item_id created_at))
    |> cast(params, ~w(meta))
  end
end
