defmodule PaperTrail.Version do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @setter PaperTrail.RepoClient.setter

  schema "versions" do
    field :event, :string
    field :item_type, :string
    field :item_id, :integer
    field :item_changes, :map
    field :setter_id, :integer
    field :set_by,   :string
    field :meta, :map

    if @setter do
      belongs_to @setter[:name], @setter[:model], define_field: false, foreign_key: :originator_id
    end

    timestamps(updated_at: false)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:item_type, :item_id, :item_changes, :set_by, :setter_id, :meta])
    |> validate_required([:event, :item_type, :item_id, :item_changes])
  end

  def count do
    from(version in __MODULE__, select: count(version.id)) |> PaperTrail.RepoClient.repo.all
  end
end
