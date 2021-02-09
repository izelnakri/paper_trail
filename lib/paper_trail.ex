defmodule PaperTrail do
  import Ecto.Query, only: [from: 2, last: 1]

  alias PaperTrail.Version
  alias PaperTrail.Serializer

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Internal API"
  defdelegate make_version_struct(version, model, options), to: Serializer

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Internal API"
  defdelegate serialize(data), to: Serializer

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Internal API"
  defdelegate get_sequence_id(table_name), to: Serializer

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Internal API"
  defdelegate add_prefix(schema, prefix), to: Serializer

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Internal API"
  defdelegate get_item_type(data), to: Serializer

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Internal API"
  defdelegate get_model_id(model), to: Serializer

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  @spec insert(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def insert(changeset, options \\ []) do
    Ecto.Multi.new()
    |> PaperTrail.Multi.insert(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as insert/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec insert!(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) :: model
        when model: struct
  def insert!(changeset, options \\ []) do
    changeset
    |> insert(options)
    |> model_or_error(:insert)
  end

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  @spec update(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def update(changeset, options \\ []) do
    Ecto.Multi.new()
    |> PaperTrail.Multi.update(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as update/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec update!(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) :: model
        when model: struct
  def update!(changeset, options \\ []) do
    changeset
    |> update(options)
    |> model_or_error(:update)
  end

  @doc """
  Deletes a record from the database with a related version insertion in one transaction
  """
  @spec delete(model_or_changeset :: model | Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def delete(model_or_changeset, options \\ []) do
    Ecto.Multi.new()
    |> PaperTrail.Multi.delete(model_or_changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as delete/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec delete!(model_or_changeset :: model | Ecto.Changeset.t(model), options :: Keyword.t()) ::
          model
        when model: struct
  def delete!(model_or_changeset, options \\ []) do
    model_or_changeset
    |> delete(options)
    |> model_or_error(:delete)
  end

  @doc """
  Gets all the versions of a record.

  A list of options is optional, so you can set for example the :prefix of the query,
  wich allows you to change between different tenants.

  # Usage examples:

      iex> PaperTrail.VersionQueries.get_versions(record)
      iex> PaperTrail.VersionQueries.get_versions(record, [prefix: "tenant_id"])
      iex> PaperTrail.VersionQueries.get_versions(ModelName, id)
      iex> PaperTrail.VersionQueries.get_versions(ModelName, id, [prefix: "tenant_id"])
  """
  @spec get_versions(record :: Ecto.Schema.t()) :: [Version.t()]
  def get_versions(record), do: get_versions(record, [])

  @doc """
  Gets all the versions of a record given a module and its id
  """
  @spec get_versions(model :: module, id :: pos_integer) :: [Version.t()]
  def get_versions(model, id) when is_atom(model) and is_integer(id),
    do: get_versions(model, id, [])

  @spec get_versions(record :: Ecto.Schema.t(), options :: Keyword.t()) :: [Version.t()]
  def get_versions(record, options) when is_map(record) do
    item_type = record.__struct__ |> Module.split() |> List.last()

    version_query(item_type, Serializer.get_model_id(record), options)
    |> PaperTrail.RepoClient.repo().all
  end

  @spec get_versions(model :: module, id :: pos_integer, options :: Keyword.t()) :: [Version.t()]
  def get_versions(model, id, options) do
    item_type = model |> Module.split() |> List.last()
    version_query(item_type, id, options) |> PaperTrail.RepoClient.repo().all
  end

  @doc """
  Gets the last version of a record.

  A list of options is optional, so you can set for example the :prefix of the query,
  wich allows you to change between different tenants.

  # Usage examples:

      iex> PaperTrail.VersionQueries.get_version(record, id)
      iex> PaperTrail.VersionQueries.get_version(record, [prefix: "tenant_id"])
      iex> PaperTrail.VersionQueries.get_version(ModelName, id)
      iex> PaperTrail.VersionQueries.get_version(ModelName, id, [prefix: "tenant_id"])
  """
  @spec get_version(record :: Ecto.Schema.t()) :: Version.t() | nil
  def get_version(record), do: get_version(record, [])

  @spec get_version(model :: module, id :: pos_integer) :: Version.t() | nil
  def get_version(model, id) when is_atom(model) and is_integer(id),
    do: get_version(model, id, [])

  @spec get_version(record :: Ecto.Schema.t(), options :: Keyword.t()) :: Version.t() | nil
  def get_version(record, options) when is_map(record) do
    item_type = record.__struct__ |> Module.split() |> List.last()

    last(version_query(item_type, Serializer.get_model_id(record), options))
    |> PaperTrail.RepoClient.repo().one
  end

  @spec get_version(model :: module, id :: pos_integer, options :: []) :: Version.t() | nil
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

  @spec model_or_error(result :: {:ok, %{model: model}}, action :: :insert | :update | :delete) ::
          model
        when model: struct()
  defp model_or_error({:ok, %{model: model}}, _action) do
    model
  end

  @spec model_or_error(result :: {:error, reason :: term}, action :: :insert | :update | :delete) ::
          no_return
  defp model_or_error({:error, %Ecto.Changeset{} = changeset}, action) do
    raise Ecto.InvalidChangesetError, action: action, changeset: changeset
  end

  defp model_or_error({:error, reason}, _action) do
    raise reason
  end
end
