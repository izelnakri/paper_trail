defmodule PaperTrail do
  alias Ecto.Multi
  import Ecto.Query
  alias Model.Version

  def get_versions(model, id) do
    item_type = model |> Module.split |> List.last
    version_query(item_type, id) |> Application.Repo.all
  end

  def get_versions(changeset) do
    item_type = changeset.__struct__ |> Module.split |> List.last
    version_query(item_type, changeset.id) |> Application.Repo.all
  end

  def get_version(model, id) do
    item_type = Module.split(model) |> List.last
    last(version_query(item_type, id)) |> Application.Repo.one
  end

  def get_version(changeset) do
    item_type = changeset.__struct__ |> Module.split |> List.last
    last(version_query(item_type, changeset.id)) |> Application.Repo.one
  end

  defp version_query(item_type, id) do
    from v in Version,
    where: v.item_type == ^item_type and v.item_id == ^id
  end
  
  # changeset = Model.changeset(Ecto.Repo.get(Model, id), params)

  def insert(struct, meta \\ nil) do
    Multi.new
    |> Multi.insert(:model, struct)
    |> Multi.run(:version, fn %{model: model} ->
        version = make_version_struct(%{event: "create"}, model, meta)
        Application.Repo.insert(version)
      end)
    |> Application.Repo.transaction
  end

  def update(changeset, meta \\ nil) do
    Multi.new
    |> Multi.update(:model, changeset)
    |> Multi.run(:version, fn %{model: model} ->
        version = make_version_struct(%{event: "update"}, changeset, meta)
        Application.Repo.insert(version)
      end)
    |> Application.Repo.transaction
  end

  def delete(struct, meta \\ nil) do
    Multi.new
    |> Multi.delete(:model, struct)
    |> Multi.run(:version, fn %{model: model} ->
        version = make_version_struct(%{event: "destroy"}, model, meta)
        Application.Repo.insert(version)
      end)
    |> Application.Repo.transaction
  end

  def make_version_struct(%{event: "create"}, model, meta) do
    %Version{
      event: "create",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: Map.drop(model, [:__struct__, :__meta__]),
      meta: meta
    }
  end

  def make_version_struct(%{event: "update"}, changeset, meta) do
    %Version{
      event: "update",
      item_type: changeset.data.__struct__ |> Module.split |> List.last,
      item_id: changeset.data.id,
      item_changes: changeset.changes,
      meta: meta
    }
  end

  def make_version_struct(%{event: "destroy"}, model, meta) do
    %Version{
      event: "destroy",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: Map.drop(model, [:__struct__, :__meta__]),
      meta: meta
    }
  end
end
