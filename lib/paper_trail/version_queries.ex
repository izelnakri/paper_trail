defmodule PaperTrail.VersionQueries do
  import Ecto.Query
  alias PaperTrail.Version

  @repo PaperTrail.RepoClient.repo

  @doc """
  Gets all the versions of a record given a module and its id
  """
  def get_versions(model, id) do
    item_type = model |> Module.split |> List.last
    version_query(item_type, id) |> @repo.all
  end

  @doc """
  Gets all the versions of a record
  """
  def get_versions(record) do
    item_type = record.__struct__ |> Module.split |> List.last
    version_query(item_type, record.id) |> @repo.all
  end

  @doc """
  Gets the last version of a record given its module reference and its id
  """
  def get_version(model, id) do
    item_type = Module.split(model) |> List.last
    last(version_query(item_type, id)) |> @repo.one
  end

  @doc """
  Gets the last version of a record
  """
  def get_version(record) do
    item_type = record.__struct__ |> Module.split |> List.last
    last(version_query(item_type, record.id)) |> @repo.one
  end

  @doc """
  Gets the current model record/struct of a version
  """
  def get_current_model(version) do
    @repo.get("Elixir." <> version.item_type |> String.to_existing_atom, version.item_id)
  end


  defp version_query(item_type, id) do
    from v in Version,
    where: v.item_type == ^item_type and v.item_id == ^id
  end
end
