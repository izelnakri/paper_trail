defmodule PaperTrail.Version do
  use Ecto.Schema

  import Ecto.Changeset

  @originator PaperTrail.OriginatorClient.originator

  schema "versions" do
    field :event, :string
    field :item_type, :string
    field :item_id, :integer
    field :item_changes, :map
    field :meta, :map
    field :originator_id, :integer

    if @originator do
      belongs_to @originator[:name], @originator[:model], foreign_key: :originator_id, define_field: false
    end

    timestamps(updated_at: false)
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> validate_required(~w(event item_type item_id))
    |> cast(params, ~w(meta inserted_at))
  end
end
