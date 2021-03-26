defmodule PaperTrail.VersionQueries do
  import Ecto.Query
  alias PaperTrail.Version

  @doc """
  Gets all the versions of a record.

  A list of options is optional, so you can set for example the :prefix of the query,
  wich allows you to change between different tenants.

  # Usage examples:

    iex(1)> PaperTrail.VersionQueries.get_versions(record)
    iex(1)> PaperTrail.VersionQueries.get_versions(record, [prefix: "tenant_id"])
    iex(1)> PaperTrail.VersionQueries.get_versions(ModelName, id)
    iex(1)> PaperTrail.VersionQueries.get_versions(ModelName, id, [prefix: "tenant_id"])
  """
  @spec get_versions(record :: Ecto.Schema.t()) :: [Version.t()]
  def get_versions(record), do: get_versions(record, [])

  @doc """
  Gets all the versions of a record given a module and its id
  """
  @spec get_versions(model :: module, id :: pos_integer) :: [Version.t()]
  def get_versions(model, id) when is_atom(model) and is_integer(id),
    do: get_versions(model, id, [])

  @spec get_versions(record :: Ecto.Schema.t(), options :: keyword | []) :: [Version.t()]
  def get_versions(record, options) when is_map(record) do
    item_type = record.__struct__ |> Module.split() |> List.last()

    version_query(item_type, PaperTrail.get_model_id(record), options)
    |> PaperTrail.RepoClient.repo().all
  end

  @spec get_versions(model :: module, id :: pos_integer, options :: keyword | []) :: [Version.t()]
  def get_versions(model, id, options) do
    item_type = model |> Module.split() |> List.last()
    version_query(item_type, id, options) |> PaperTrail.RepoClient.repo().all
  end

  @doc """
  Gets the last version of a record.

  A list of options is optional, so you can set for example the :prefix of the query,
  wich allows you to change between different tenants.

  # Usage examples:

    iex(1)> PaperTrail.VersionQueries.get_version(record, id)
    iex(1)> PaperTrail.VersionQueries.get_version(record, [prefix: "tenant_id"])
    iex(1)> PaperTrail.VersionQueries.get_version(ModelName, id)
    iex(1)> PaperTrail.VersionQueries.get_version(ModelName, id, [prefix: "tenant_id"])
  """
  @spec get_version(record :: Ecto.Schema.t()) :: Version.t() | nil
  def get_version(record), do: get_version(record, [])

  @spec get_version(model :: module, id :: pos_integer) :: Version.t() | nil
  def get_version(model, id) when is_atom(model) and is_integer(id),
    do: get_version(model, id, [])

  @spec get_version(record :: Ecto.Schema.t(), options :: keyword | []) :: Version.t() | nil
  def get_version(record, options) when is_map(record) do
    item_type = record.__struct__ |> Module.split() |> List.last()

    last(version_query(item_type, PaperTrail.get_model_id(record), options))
    |> PaperTrail.RepoClient.repo().one
  end

  @spec get_version(model :: module, id :: pos_integer, options :: keyword | []) :: Version.t() | nil
  def get_version(model, id, options) do
    item_type = model |> Module.split() |> List.last()
    last(version_query(item_type, id, options)) |> PaperTrail.RepoClient.repo().one
  end

  @doc """
  Gets the current model record/struct of a version
  """
  @spec get_current_model(version :: Version.t()) :: Ecto.Schema.t() | nil
  def get_current_model(version) do
    PaperTrail.RepoClient.repo().get(
      ("Elixir." <> version.item_type) |> String.to_existing_atom(),
      version.item_id
    )
  end

  defp version_query(item_type, id) do
    from(v in Version, where: v.item_type == ^item_type and v.item_id == ^id)
  end

  defp version_query(item_type, id, options) do
    with opts <- Enum.into(options, %{}) do
      version_query(item_type, id)
      |> Ecto.Queryable.to_query()
      |> Map.merge(opts)
    end
  end
end
