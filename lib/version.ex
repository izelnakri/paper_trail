defmodule PaperTrail.Version do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @setter PaperTrail.RepoClient.originator || nil

  @item_type Application.get_env(:paper_trail, :item_type, :integer)
  @originator_type Application.get_env(:paper_trail, :originator_type, :integer)

  schema "versions" do
    field :event, :string
    field :item_type, :string
    field :item_id, @item_type
    field :item_changes, :map
    field :originator_id, @originator_type
    field :origin, :string, read_after_writes: true
    field :meta, :map

    if @setter do
      belongs_to @setter[:name], @setter[:model], define_field: false, foreign_key: :originator_id, type: @originator_type
    end

    timestamps(updated_at: false)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:item_type, :item_id, :item_changes, :origin, :originator_id, :meta])
    |> validate_required([:event, :item_type, :item_id, :item_changes])
  end

  @doc """
  Returns the count of all version records in the database
  """
  def count do
    from(version in __MODULE__, select: count(version.id)) |> PaperTrail.RepoClient.repo.one
  end

  @doc """
  Returns the first version record in the database by :inserted_at
  """
  def first do
    from(record in __MODULE__, limit: 1, order_by: [asc: :inserted_at])
    |> PaperTrail.RepoClient.repo.one
  end

  @doc """
  Returns the last version record in the database by :inserted_at
  """
  def last do
    from(record in __MODULE__, limit: 1, order_by: [desc: :inserted_at])
    |> PaperTrail.RepoClient.repo.one
  end
end
