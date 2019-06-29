defmodule PaperTrail.VersionQueries do
  import Ecto.Query
  alias PaperTrail.Version

  @doc """
  Gets all the versions of a record.
  """
  @spec get_versions(record :: Ecto.Schema.t()) :: Ecto.Query.t()
  def get_versions(record), do: get_versions(record, [])

  @doc """
  Gets all the versions of a record given a module and its id
  """
  @spec get_versions(model :: module, id :: pos_integer) :: Ecto.Query.t()
  def get_versions(model, id) when is_atom(model) and is_integer(id),
    do: get_versions(model, id, [])

  @doc """
  Gets all the versions of a record.

  A list of options is optional, so you can set for example the :prefix of the query,
  wich allows you to change between different tenants.

  # Usage example:

    iex(1)> PaperTrail.VersionQueries.get_versions(record, [prefix: "tenant_id"])
  """
  @spec get_versions(record :: Ecto.Schema.t(), options :: []) :: Ecto.Query.t()
  def get_versions(record, options) when is_map(record) do
    item_type = record.__struct__ |> Module.split() |> List.last()

    version_query(item_type, PaperTrail.get_model_id(record), options)
    |> PaperTrail.RepoClient.repo().all
  end

  @doc """
  Gets all the versions of a record given a module and its id.

  A list of options is optional, so you can set for example the :prefix of the query,
  wich allows you to change between different tenants.

  # Usage example:

    iex(1)> PaperTrail.VersionQueries.get_versions(ModelName, id, [prefix: "tenant_id"])
  """
  @spec get_versions(model :: module, id :: pos_integer, options :: []) :: Ecto.Query.t()
  def get_versions(model, id, options) do
    item_type = model |> Module.split() |> List.last()
    version_query(item_type, id, options) |> PaperTrail.RepoClient.repo().all
  end

  @doc """
  Gets the last version of a record.
  """
  @spec get_version(record :: Ecto.Schema.t()) :: Ecto.Query.t()
  def get_version(record), do: get_version(record, [])

  @doc """
  Gets the last version of a record given its module reference and its id.
  """
  @spec get_version(model :: module, id :: pos_integer) :: Ecto.Query.t()
  def get_version(model, id) when is_atom(model) and is_integer(id),
    do: get_version(model, id, [])

  @doc """
  Gets the last version of a record.

  A list of options is optional, so you can set for example the :prefix of the query,
  wich allows you to change between different tenants.

  # Usage example:

    iex(1)> PaperTrail.VersionQueries.get_version(record, [prefix: "tenant_id"])
  """
  @spec get_version(record :: Ecto.Schema.t(), options :: []) :: Ecto.Query.t()
  def get_version(record, options) when is_map(record) do
    item_type = record.__struct__ |> Module.split() |> List.last()

    last(version_query(item_type, PaperTrail.get_model_id(record), options))
    |> PaperTrail.RepoClient.repo().one
  end

  @doc """
  Gets the last version of a record given its module reference and its id.

  A list of options is optional, so you can set for example the :prefix of the query,
  wich allows you to change between different tenants.

  # Usage example:

    iex(1)> PaperTrail.VersionQueries.get_version(ModelName, id, [prefix: "tenant_id"])
  """
  @spec get_version(model :: module, id :: pos_integer, options :: []) :: Ecto.Query.t()
  def get_version(model, id, options) do
    item_type = model |> Module.split() |> List.last()
    last(version_query(item_type, id, options)) |> PaperTrail.RepoClient.repo().one
  end

  @doc """
  Gets the current model record/struct of a version
  """
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
