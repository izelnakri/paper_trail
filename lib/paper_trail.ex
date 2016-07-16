defmodule PaperTrail do
  alias Ecto.Multi
  import Ecto.Query
  alias PaperTrail.Version

  @doc """
  Gets all the versions of a record given a module and its id
  """
  def get_versions(model, id) do
    item_type = model |> Module.split |> List.last
    version_query(item_type, id) |> Repo.all
  end

  @doc """
  Gets all the versions of a record
  """
  def get_versions(record) do
    item_type = record.__struct__ |> Module.split |> List.last
    version_query(item_type, record.id) |> Repo.all
  end

  @doc """
  Gets the last version of a record given its module reference and its id
  """
  def get_version(model, id) do
    item_type = Module.split(model) |> List.last
    last(version_query(item_type, id)) |> Repo.one
  end

  @doc """
  Gets the last version of a record
  """
  def get_version(record) do
    item_type = record.__struct__ |> Module.split |> List.last
    last(version_query(item_type, record.id)) |> Repo.one
  end

  defp version_query(item_type, id) do
    from v in Version,
    where: v.item_type == ^item_type and v.item_id == ^id
  end

  # changeset = Model.changeset(Ecto.Repo.get(Model, id), params)

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  def insert(changeset, meta \\ nil) do
    Multi.new
    |> Multi.insert(:model, changeset)
    |> Multi.run(:version, fn %{model: model} ->
        version = make_version_struct(%{event: "create"}, model, meta)
        Repo.insert(version)
      end)
    |> Repo.transaction
  end

  defp make_version_struct(%{event: "create"}, model, meta) do
    IO.puts "make_version_struct called"
    filter_item_changes(model) |> inspect |> IO.puts
    %Version{
      event: "create",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: filter_item_changes(model),
      meta: meta
    }
  end

  defp filter_item_changes(model) do
    relationships = model.__struct__.__schema__(:associations)

    Map.drop(model, [:__struct__, :__meta__] ++ relationships)
  end

  # might make the changeset version

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  def update(changeset, meta \\ nil) do
    Multi.new
    |> Multi.update(:model, changeset)
    |> Multi.run(:version, fn %{model: model} ->
        version = make_version_struct(%{event: "update"}, changeset, meta)
        Repo.insert(version)
      end)
    |> Repo.transaction
  end

  defp make_version_struct(%{event: "update"}, changeset, meta) do
    %Version{
      event: "update",
      item_type: changeset.data.__struct__ |> Module.split |> List.last,
      item_id: changeset.data.id,
      item_changes: changeset.changes,
      meta: meta
    }
  end

  @doc """
  Deletes a record from the database with a related version insertion in one transaction
  """
  def delete(struct, meta \\ nil) do
    Multi.new
    |> Multi.delete(:model, struct)
    |> Multi.run(:version, fn %{model: model} ->
        version = make_version_struct(%{event: "destroy"}, model, meta)
        Repo.insert(version)
      end)
    |> Repo.transaction
  end

  defp make_version_struct(%{event: "destroy"}, model, meta) do
    %Version{
      event: "destroy",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: filter_item_changes(model),
      meta: meta
    }
  end
end
