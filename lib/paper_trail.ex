defmodule PaperTrail do
  import PaperTrail.VersionQueries

  alias Ecto.Multi
  alias PaperTrail.Version

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

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  def update(changeset, meta \\ nil) do
    Multi.new
    |> Multi.update(:model, changeset)
    |> Multi.run(:version, fn %{model: _model} ->
        version = make_version_struct(%{event: "update"}, changeset, meta)
        Repo.insert(version)
      end)
    |> Repo.transaction
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

  defp make_version_struct(%{event: "create"}, model, meta) do
    %Version{
      event: "create",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: filter_item_changes(model),
      meta: meta
    }
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

  defp make_version_struct(%{event: "destroy"}, model, meta) do
    %Version{
      event: "destroy",
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
end
