defmodule PaperTrail.Version do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  # @setter PaperTrail.RepoClient.originator()
  # @item_type Application.get_env(:paper_trail, :item_type, :integer)
  # @originator_type Application.get_env(:paper_trail, :originator_type, :integer)

  schema "versions" do
    field(:event, :string)
    field(:item_type, :string)
    field(:item_id, Application.get_env(:paper_trail, :item_type, :integer))
    field(:item_changes, :map)
    field(:originator_id, Application.get_env(:paper_trail, :originator_type, :integer))

    field(:origin, :string,
      read_after_writes: Application.get_env(:paper_trail, :origin_read_after_writes, true)
    )

    field(:meta, :map)

    if PaperTrail.RepoClient.originator() do
      belongs_to(
        PaperTrail.RepoClient.originator()[:name],
        PaperTrail.RepoClient.originator()[:model],
        define_field: false,
        foreign_key: :originator_id,
        type: Application.get_env(:paper_trail, :originator_type, :integer)
      )
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
    from(version in __MODULE__, select: count(version.id)) |> PaperTrail.RepoClient.repo().one()
  end

  def count(options) do
    from(version in __MODULE__, select: count(version.id))
    |> Ecto.Queryable.to_query()
    |> Map.put(:prefix, options[:prefix])
    |> PaperTrail.RepoClient.repo().one
  end

  @doc """
  Returns the first version record in the database by :inserted_at
  """
  def first do
    from(record in __MODULE__, limit: 1, order_by: [asc: :inserted_at])
    |> PaperTrail.RepoClient.repo().one
  end

  def first(options) do
    from(record in __MODULE__, limit: 1, order_by: [asc: :inserted_at])
    |> Ecto.Queryable.to_query()
    |> Map.put(:prefix, options[:prefix])
    |> PaperTrail.RepoClient.repo().one
  end

  @doc """
  Returns the last version record in the database by :inserted_at
  """
  def last do
    from(record in __MODULE__, limit: 1, order_by: [desc: :inserted_at])
    |> PaperTrail.RepoClient.repo().one
  end

  def last(options) do
    from(record in __MODULE__, limit: 1, order_by: [desc: :inserted_at])
    |> Ecto.Queryable.to_query()
    |> Map.put(:prefix, options[:prefix])
    |> PaperTrail.RepoClient.repo().one
  end
end
