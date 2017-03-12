defmodule PaperTrail.Version do
  use Ecto.Schema

  import Ecto.Changeset

  schema "versions" do
    field :event, :string
    field :item_type, :string
    field :item_id, :integer
    field :item_changes, :map
    field :created_by, :string
    field :meta, :map

    timestamps(updated_at: false)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:item_changes, :meta])
    |> validate_required([:event, :item_type, :item_id, :item_changes])
  end
end
