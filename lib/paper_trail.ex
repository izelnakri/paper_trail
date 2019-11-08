defmodule PaperTrail do
  import Ecto.Changeset

  alias PaperTrail.Version
  alias PaperTrail.RepoClient

  defdelegate get_version(record), to: PaperTrail.VersionQueries
  defdelegate get_version(model_or_record, id_or_options), to: PaperTrail.VersionQueries
  defdelegate get_version(model, id, options), to: PaperTrail.VersionQueries
  defdelegate get_versions(record), to: PaperTrail.VersionQueries
  defdelegate get_versions(model_or_record, id_or_options), to: PaperTrail.VersionQueries
  defdelegate get_versions(model, id, options), to: PaperTrail.VersionQueries
  defdelegate get_current_model(version), to: PaperTrail.VersionQueries

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  def insert(changeset, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.insert(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as insert/2 but returns only the model struct or raises if the changeset is invalid.
  """
  def insert!(changeset, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    repo = RepoClient.repo()

    repo.transaction(fn ->
      case RepoClient.strict_mode() do
        true ->
          version_id = get_sequence_id("versions") + 1

          changeset_data =
            Map.get(changeset, :data, changeset)
            |> Map.merge(%{
              id: get_sequence_from_model(changeset) + 1,
              first_version_id: version_id,
              current_version_id: version_id
            })

          initial_version =
            make_version_struct(%{event: "insert"}, changeset_data, options)
            |> repo.insert!

          updated_changeset =
            changeset
            |> change(%{
              first_version_id: initial_version.id,
              current_version_id: initial_version.id
            })

          model = repo.insert!(updated_changeset)
          target_version = make_version_struct(%{event: "insert"}, model, options) |> serialize()
          Version.changeset(initial_version, target_version) |> repo.update!
          model

        _ ->
          model = repo.insert!(changeset)
          make_version_struct(%{event: "insert"}, model, options) |> repo.insert!
          model
      end
    end)
    |> elem(1)
  end

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  def update(changeset, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.update(changeset, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as update/2 but returns only the model struct or raises if the changeset is invalid.
  """
  def update!(changeset, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    repo = PaperTrail.RepoClient.repo()
    client = PaperTrail.RepoClient

    repo.transaction(fn ->
      case client.strict_mode() do
        true ->
          version_data =
            changeset.data
            |> Map.merge(%{
              current_version_id: get_sequence_id("versions")
            })

          target_changeset = changeset |> Map.merge(%{data: version_data})
          target_version = make_version_struct(%{event: "update"}, target_changeset, options)
          initial_version = repo.insert!(target_version)
          updated_changeset = changeset |> change(%{current_version_id: initial_version.id})
          model = repo.update!(updated_changeset)

          new_item_changes =
            initial_version.item_changes
            |> Map.merge(%{
              current_version_id: initial_version.id
            })

          initial_version |> change(%{item_changes: new_item_changes}) |> repo.update!
          model

        _ ->
          model = repo.update!(changeset)
          version_struct = make_version_struct(%{event: "update"}, changeset, options)
          repo.insert!(version_struct)
          model
      end
    end)
    |> elem(1)
  end

  @doc """
  Deletes a record from the database with a related version insertion in one transaction
  """
  def delete(struct, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    PaperTrail.Multi.new()
    |> PaperTrail.Multi.delete(struct, options)
    |> PaperTrail.Multi.commit()
  end

  @doc """
  Same as delete/2 but returns only the model struct or raises if the changeset is invalid.
  """
  def delete!(struct, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    repo = PaperTrail.RepoClient.repo()

    repo.transaction(fn ->
      model = repo.delete!(struct, options)
      version_struct = make_version_struct(%{event: "delete"}, struct, options)
      repo.insert!(version_struct, options)
      model
    end)
    |> elem(1)
  end

  defp make_version_struct(%{event: "insert"}, model, options) do
    originator = PaperTrail.RepoClient.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    %Version{
      event: "insert",
      item_type: get_item_type(model),
      item_id: get_model_id(model),
      item_changes: serialize(model),
      originator_id:
        case originator_ref do
          nil -> nil
          _ -> originator_ref |> Map.get(:id)
        end,
      origin: options[:origin],
      meta: options[:meta]
    }
    |> add_prefix(options[:prefix])
  end

  defp make_version_struct(%{event: "update"}, changeset, options) do
    originator = PaperTrail.RepoClient.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    %Version{
      event: "update",
      item_type: get_item_type(changeset),
      item_id: get_model_id(changeset),
      item_changes: changeset.changes,
      originator_id:
        case originator_ref do
          nil -> nil
          _ -> originator_ref |> Map.get(:id)
        end,
      origin: options[:origin],
      meta: options[:meta]
    }
    |> add_prefix(options[:prefix])
  end

  defp make_version_struct(%{event: "delete"}, model_or_changeset, options) do
    originator = PaperTrail.RepoClient.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    %Version{
      event: "delete",
      item_type: get_item_type(model_or_changeset),
      item_id: get_model_id(model_or_changeset),
      item_changes: serialize(model_or_changeset),
      originator_id:
        case originator_ref do
          nil -> nil
          _ -> originator_ref |> Map.get(:id)
        end,
      origin: options[:origin],
      meta: options[:meta]
    }
    |> add_prefix(options[:prefix])
  end

  defp get_sequence_from_model(changeset) do
    table_name =
      case Map.get(changeset, :data) do
        nil -> changeset.__struct__.__schema__(:source)
        _ -> changeset.data.__struct__.__schema__(:source)
      end

    get_sequence_id(table_name)
  end

  defp get_sequence_id(table_name) do
    Ecto.Adapters.SQL.query!(RepoClient.repo(), "select last_value FROM #{table_name}_id_seq").rows
    |> List.first()
    |> List.first()
  end

  defp serialize(%Ecto.Changeset{data: data}), do: serialize(data)

  defp serialize(model) do
    relationships = model.__struct__.__schema__(:associations)
    Map.drop(model, [:__struct__, :__meta__] ++ relationships)
  end

  defp add_prefix(changeset, nil), do: changeset
  defp add_prefix(changeset, prefix), do: Ecto.put_meta(changeset, prefix: prefix)

  defp get_item_type(%Ecto.Changeset{data: data}), do: get_item_type(data)
  defp get_item_type(model), do: model.__struct__ |> Module.split() |> List.last()

  def get_model_id(%Ecto.Changeset{data: data}), do: get_model_id(data)

  def get_model_id(model) do
    {_, model_id} = List.first(Ecto.primary_key(model))

    case PaperTrail.Version.__schema__(:type, :item_id) do
      :integer ->
        model_id
      _ ->
        "#{model_id}"
    end
  end
end
