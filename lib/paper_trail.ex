defmodule PaperTrail do
  alias PaperTrail.Version
  alias PaperTrail.Serializer

  defdelegate get_version(record), to: PaperTrail.VersionQueries
  defdelegate get_version(model_or_record, id_or_options), to: PaperTrail.VersionQueries
  defdelegate get_version(model, id, options), to: PaperTrail.VersionQueries
  defdelegate get_versions(record), to: PaperTrail.VersionQueries
  defdelegate get_versions(model_or_record, id_or_options), to: PaperTrail.VersionQueries
  defdelegate get_versions(model, id, options), to: PaperTrail.VersionQueries
  defdelegate get_current_model(version), to: PaperTrail.VersionQueries
  defdelegate make_version_struct(version, model, options), to: Serializer
  defdelegate serialize(data), to: Serializer
  defdelegate get_sequence_id(table_name), to: Serializer
  defdelegate add_prefix(schema, prefix), to: Serializer
  defdelegate get_item_type(data), to: Serializer
  defdelegate get_model_id(model), to: Serializer

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  @spec insert(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def insert(
        changeset,
        options \\ [
          origin: nil,
          meta: nil,
          originator: nil,
          prefix: nil,
          model_key: :model,
          version_key: :version,
          ecto_options: []
        ]
      ) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.insert(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as insert/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec insert!(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) :: model
        when model: struct
  def insert!(
        changeset,
        options \\ [
          origin: nil,
          meta: nil,
          originator: nil,
          prefix: nil,
          model_key: :model,
          version_key: :version,
          ecto_options: []
        ]
      ) do
    changeset
    |> insert(options)
    |> model_or_error(:insert)
  end

  @doc """
  Upserts a record to the database with a related version insertion in one transaction.
  """
  @spec insert_or_update(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def insert_or_update(
        changeset,
        options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]
      ) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.insert_or_update(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as insert_or_update/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec insert_or_update!(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) :: model
        when model: struct
  def insert_or_update!(
        changeset,
        options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]
      ) do
    changeset
    |> insert_or_update(options)
    |> model_or_error(:insert_or_update)
  end

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  @spec update(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) ::
          {:ok, %{model: model, version: Version.t()}} | {:error, Ecto.Changeset.t(model) | term}
        when model: struct
  def update(changeset, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.update(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as update/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec update!(changeset :: Ecto.Changeset.t(model), options :: Keyword.t()) :: model
        when model: struct
  def update!(changeset, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
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
  def delete(
        model_or_changeset,
        options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]
      ) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.delete(model_or_changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as delete/2 but returns only the model struct or raises if the changeset is invalid.
  """
  @spec delete!(model_or_changeset :: model | Ecto.Changeset.t(model), options :: Keyword.t()) ::
          model
        when model: struct
  def delete!(
        model_or_changeset,
        options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]
      ) do
    model_or_changeset
    |> delete(options)
    |> model_or_error(:delete)
  end

  @spec model_or_error(
          result :: {:ok, %{required(:model) => model, optional(any()) => any()}},
          action :: :insert | :insert_or_update | :update | :delete
        ) ::
          model
        when model: struct()
  defp model_or_error({:ok, %{model: model}}, _action) do
    model
  end

  @spec model_or_error(
          result :: {:error, reason :: term},
          action :: :insert | :insert_or_update | :update | :delete
        ) ::
          no_return
  defp model_or_error({:error, %Ecto.Changeset{} = changeset}, action) do
    raise Ecto.InvalidChangesetError, action: action, changeset: changeset
  end

  defp model_or_error({:error, reason}, _action) do
    raise reason
  end
end
