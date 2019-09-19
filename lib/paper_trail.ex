defmodule PaperTrail do
  import Ecto.Changeset

  alias Ecto.Multi
  alias PaperTrail.Version
  alias PaperTrail.RepoClient

  defdelegate get_version(record), to: PaperTrail.VersionQueries
  defdelegate get_version(model_or_record, id_or_options), to: PaperTrail.VersionQueries
  defdelegate get_version(model, id, options), to: PaperTrail.VersionQueries
  defdelegate get_versions(record), to: PaperTrail.VersionQueries
  defdelegate get_versions(model_or_record, id_or_options), to: PaperTrail.VersionQueries
  defdelegate get_versions(model, id, options), to: PaperTrail.VersionQueries
  defdelegate get_current_model(version), to: PaperTrail.VersionQueries

  @embed_mode (case Application.get_env(:paper_trail, :item_type, :integer) do
    Ecto.UUID ->
      :extract_version
    _ ->
      :embed_into_item_changes
  end)
  @embed_mode Application.get_env(:paper_trail, :embed_mode, @embed_mode)

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  def insert(changeset, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    repo = RepoClient.repo()

    transaction_order =
      case RepoClient.strict_mode() do
        true ->
          Multi.new()
          |> Multi.run(:initial_version, fn repo, %{} ->
            version_id = get_sequence_id("versions") + 1

            changeset_data =
              Map.get(changeset, :data, changeset)
              |> Map.merge(%{
                id: get_sequence_from_model(changeset) + 1,
                first_version_id: version_id,
                current_version_id: version_id
              })
            initial_version = make_version_struct(%{event: "insert"}, changeset_data, options)
            repo.insert(initial_version)
          end)
          |> Multi.run(:model, fn repo, %{initial_version: initial_version} ->
            updated_changeset =
              changeset
              |> change(%{
                first_version_id: initial_version.id,
                current_version_id: initial_version.id
              })

            repo.insert(updated_changeset)
          end)
          |> Multi.run(:version, fn repo, %{initial_version: initial_version, model: model} ->
            target_version =
              make_version_struct(%{event: "insert"}, model, options) |> serialize()

            Version.changeset(initial_version, target_version) |> repo.update
          end)

        _ ->
          Multi.new()
          |> Multi.insert(:model, changeset)
          |> Multi.run(:version, fn repo, %{model: model} ->
            versions = make_version_structs(%{event: "insert"}, model, changeset, options)

            results = case versions do
                [nil | rest] -> [{:ok, nil} | Enum.map(rest, &repo.insert/1)]
                _ -> Enum.map(versions, &repo.insert/1)
              end

            format_multiple_results(results)
          end)
      end

    transaction = repo.transaction(transaction_order)

    case RepoClient.strict_mode() do
      true ->
        case transaction do
          {:error, :model, changeset, %{}} ->
            filtered_changes =
              Map.drop(changeset.changes, [:current_version_id, :first_version_id])

            {:error, Map.merge(changeset, %{repo: repo, changes: filtered_changes})}

          {:ok, map} ->
            {:ok, Map.drop(map, [:initial_version])}
        end

      _ ->
        case transaction do
          {:error, :model, changeset, %{}} -> {:error, Map.merge(changeset, %{repo: repo})}
          {:ok, map} ->
            versions = Map.get(map, :version)

            map =
              map
              |> Map.put(:version, hd(versions))
              |> Map.put(:assoc_versions, tl(versions))
            {:ok, map}
          _ -> transaction
        end
    end
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
          %{event: "insert"}
          |> make_version_structs(model, changeset, options)
          |> Enum.each(&repo.insert!/1)
          model
      end
    end)
    |> elem(1)
  end

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  def update(changeset, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    repo = PaperTrail.RepoClient.repo()
    client = PaperTrail.RepoClient

    transaction_order =
      case client.strict_mode() do
        true ->
          Multi.new()
          |> Multi.run(:initial_version, fn repo, %{} ->
            version_data =
              changeset.data
              |> Map.merge(%{
                current_version_id: get_sequence_id("versions")
              })

            target_changeset = changeset |> Map.merge(%{data: version_data})
            target_version = make_version_struct(%{event: "update"}, target_changeset, options)
            repo.insert(target_version)
          end)
          |> Multi.run(:model, fn repo, %{initial_version: initial_version} ->
            updated_changeset = changeset |> change(%{current_version_id: initial_version.id})
            repo.update(updated_changeset)
          end)
          |> Multi.run(:version, fn repo, %{initial_version: initial_version} ->
            new_item_changes =
              initial_version.item_changes
              |> Map.merge(%{
                current_version_id: initial_version.id
              })

            initial_version |> change(%{item_changes: new_item_changes}) |> repo.update
          end)

        _ ->
          Multi.new()
          |> Multi.update(:model, changeset)
          |> Multi.run(:version, fn repo, %{model: model} ->
            versions = make_version_structs(%{event: "update"}, model, changeset, options)

            results = case versions do
                [nil | rest] -> [{:ok, nil} | Enum.map(rest, &repo.insert/1)]
                _ -> Enum.map(versions, &repo.insert/1)
              end

            format_multiple_results(results)
          end)
      end

    transaction = repo.transaction(transaction_order)

    case client.strict_mode() do
      true ->
        case transaction do
          {:error, :model, changeset, %{}} ->
            filtered_changes = Map.drop(changeset.changes, [:current_version_id])
            {:error, Map.merge(changeset, %{repo: repo, changes: filtered_changes})}

          {:ok, map} ->
            {:ok, Map.delete(map, :initial_version)}
        end

      _ ->
        case transaction do
          {:error, :model, changeset, %{}} -> {:error, Map.merge(changeset, %{repo: repo})}
          {:ok, map} ->
            versions = Map.get(map, :version)

            map =
              map
              |> Map.put(:version, hd(versions))
              |> Map.put(:assoc_versions, tl(versions))
            {:ok, map}
          _ -> transaction
        end
    end
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
          %{event: "update"}
          |> make_version_structs(model, changeset, options)
          |> Enum.each(&repo.insert!/1)
          model
      end
    end)
    |> elem(1)
  end

  @doc """
  Deletes a record from the database with a related version insertion in one transaction
  """
  def delete(struct, options \\ [origin: nil, meta: nil, originator: nil, prefix: nil]) do
    repo = PaperTrail.RepoClient.repo()
    deleted_assocs = PaperTrail.AssociationUtils.get_all_children(struct)

    transaction =
      Multi.new()
      |> Multi.delete(:model, struct, options)
      |> Multi.run(:version, fn repo, %{model: model} ->
        version = make_version_struct(%{event: "delete"}, model, options)
        repo.insert(version, options)
      end)
      |> Multi.run(:assoc_versions, fn repo, %{} ->
        results =
          deleted_assocs
          |> Enum.map(fn
            {:delete_all, _, struct} ->
              make_version_struct(%{event: "delete"}, struct, options)
            {:nilify_all, owner_field, struct} ->
              changeset = Ecto.Changeset.change(struct, [{owner_field, nil}])
              make_version_struct(%{event: "update"}, changeset, options)
          end)
          |> Enum.map(&repo.insert/1)

        format_multiple_results(results)
      end)
      |> repo.transaction(options)

    case transaction do
      {:error, :model, changeset, %{}} -> {:error, Map.merge(changeset, %{repo: repo})}
      _ -> transaction
    end
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

  defp make_version_structs(%{event: event}, model, changeset, options) do
    model_version = case event do
      "update" -> make_version_struct(%{event: event}, changeset, options)
      _ -> make_version_struct(%{event: event}, model, options)
    end

    assoc_versions =
      changeset.changes
      |> Enum.flat_map(fn {key, value} ->
        model = Map.get(model, key)
        case value do
          %Ecto.Changeset{} = changeset ->
            {changeset, model}
          list when is_list(list) ->
            [list, model]
            |> List.zip()
            |> Enum.filter(fn
              {%Ecto.Changeset{}, _} -> true
              _ -> false
            end)
            |> Enum.filter(fn
              {_, %{__struct__: schema}} -> not(is_embed?(schema)) or @embed_mode == :extract_version
              _ -> false
            end)
          _ -> []
        end
      end)
      |> Enum.flat_map(fn {changeset, model} ->
        make_version_structs(
          %{event: changeset.action |> Atom.to_string},
          model,
          changeset,
          options
        )
      end)

    [ model_version | assoc_versions ]
  end

  defp make_version_struct(%{event: event}, model, options) when event in ~w[insert delete update replace] do
    changes = serialize(model)

    case Enum.count(changes) do
      0 ->
        nil
      _ ->
        originator = PaperTrail.RepoClient.originator()
        originator_ref = options[originator[:name]] || options[:originator]

        %Version{
          event: event,
          item_type: get_item_type(model),
          item_id: get_model_id(model),
          item_changes: changes,
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
  end

  defp format_multiple_results(results) do
    case Keyword.get_values(results, :error) do
      [] -> {:ok, Keyword.get_values(results, :ok)}
      errors -> {:error, errors}
    end
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

  defp serialize(%Ecto.Changeset{action: :update, changes: %{}} = changeset) do
    serialize(changeset.data.__struct__, changeset.data)
  end
  defp serialize(%Ecto.Changeset{} = changeset) do
    model = case changeset.action do
      :update -> changeset.changes
      :insert -> changeset.changes
      :delete -> changeset.data
      :replace -> changeset.data
      nil -> changeset.changes
    end
    serialize(changeset.data.__struct__, model)
  end
  defp serialize(model) do
    serialize(model.__struct__, model)
  end
  defp serialize(struct, model) do
    relationships = struct.__schema__(:associations) ++ struct.__schema__(:embeds)

    model
    |> Map.drop([:__struct__, :__meta__] ++ relationships)
    |> Enum.filter(fn
      {_, %Ecto.Association.NotLoaded{}} -> false
      _ -> true
    end)
    |> Enum.into(%{}, fn
      {key, %Ecto.Changeset{} = changeset} ->
        {key, serialize(changeset)}
      {key, %{__struct__: struct} = model} ->
        if is_schema?(struct) do
          {key, serialize(model)}
        else
          {key, model}
        end
      {key, list} when is_list(list) ->
        list = Enum.map(list, fn
          %Ecto.Changeset{} = changeset ->
            serialize(changeset)
          %{__struct__: struct} = model ->
            if is_schema?(struct) do
              serialize(model)
            else
              model
            end
          value ->
            value
        end)
        {key, list}
      other -> other
    end)
  end

  defp add_prefix(changeset, nil), do: changeset
  defp add_prefix(changeset, prefix), do: Ecto.put_meta(changeset, prefix: prefix)

  defp get_item_type(%Ecto.Changeset{data: data}), do: get_item_type(data)
  defp get_item_type(model), do: model.__struct__ |> Module.split() |> Enum.join(".")

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

  defp is_schema?(struct) do
    :functions |> struct.__info__ |> Keyword.get(:__schema__, :undef) != :undef
  end

  defp is_embed?(schema), do: is_nil(schema.__schema__(:source))
end
