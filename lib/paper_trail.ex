defmodule PaperTrail do
  import Ecto.Changeset

  alias PaperTrail.VersionQueries

  alias Ecto.Multi
  alias PaperTrail.Version

  @client PaperTrail.RepoClient
  @originator @client.originator()
  @repo @client.repo()

  @doc """
  Gets all the versions of a record given a module and its id
  """
  def get_versions(model, id) do
    VersionQueries.get_versions(model, id)
  end

  @doc """
  Gets all the versions of a record
  """
  def get_versions(record) do
    VersionQueries.get_versions(record)
  end

  @doc """
  Gets the last version of a record given its module reference and its id
  """
  def get_version(model, id) do
    VersionQueries.get_version(model, id)
  end

  @doc """
  Gets the last version of a record
  """
  def get_version(record) do
    VersionQueries.get_version(record)
  end

  @doc """
  Gets the current model record/struct of a version
  """
  def get_current_model(version) do
    VersionQueries.get_current_model(version)
  end

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  def insert(changeset, options \\ [origin: nil, meta: nil, originator: nil]) do
    transaction_order = case @client.strict_mode() do
      true ->
        Multi.new
        |> Multi.run(:initial_version, fn %{} ->
          version_id = get_sequence_id("versions") + 1
          changeset_data = case Map.get(changeset, :data) do
            nil -> changeset |> Map.merge(%{
              id: get_sequence_from_model(changeset) + 1,
              first_version_id: version_id,
              current_version_id: version_id
            })
            _ -> changeset.data |> Map.merge(%{
              id: get_sequence_from_model(changeset) + 1,
              first_version_id: version_id,
              current_version_id: version_id
            })
          end
          initial_version = make_version_struct(%{event: "insert"}, changeset_data, options)
          @repo.insert(initial_version)
        end)
        |> Multi.run(:model, fn %{initial_version: initial_version} ->
          updated_changeset = changeset |> change(%{
            first_version_id: initial_version.id, current_version_id: initial_version.id
          })
          @repo.insert(updated_changeset)
        end)
        |> Multi.run(:version, fn %{initial_version: initial_version, model: model} ->
          target_version = make_version_struct(%{event: "insert"}, model, options) |> serialize()
          Version.changeset(initial_version, target_version) |> @repo.update
        end)
      _ ->
        Multi.new
        |> Multi.insert(:model, changeset)
        |> Multi.run(:version, fn %{model: model} ->
          results = make_version_structs(%{event: "insert"}, model, changeset, options)
          |> Enum.map(&@repo.insert/1)

          case Keyword.get_values(results, :error) do
            [] -> {:ok, Keyword.get_values(results, :ok)}
            errors -> {:error, errors}
          end
        end)
    end

    transaction = @repo.transaction(transaction_order)

    case @client.strict_mode() do
      true ->
        case transaction do
          {:error, :model, changeset, %{}} ->
            filtered_changes = Map.drop(changeset.changes, [:current_version_id, :first_version_id])
            {:error, Map.merge(changeset, %{repo: @repo, changes: filtered_changes})}
          {:ok, map} -> {:ok, Map.drop(map, [:initial_version])}
        end
      _ ->
        case transaction do
          {:error, :model, changeset, %{}} -> {:error, Map.merge(changeset, %{repo: @repo})}
          _ -> transaction
        end
    end
  end

  @doc """
  Same as insert/2 but returns only the model struct or raises if the changeset is invalid.
  """
  def insert!(changeset, options \\ [origin: nil, meta: nil, originator: nil]) do
    @repo.transaction(fn ->
      case @client.strict_mode() do
        true ->
          version_id = get_sequence_id("versions") + 1
          changeset_data = case Map.get(changeset, :data) do
            nil -> changeset |> Map.merge(%{
              id: get_sequence_from_model(changeset) + 1,
              first_version_id: version_id,
              current_version_id: version_id
            })
            _ -> changeset.data |> Map.merge(%{
              id: get_sequence_from_model(changeset) + 1,
              first_version_id: version_id,
              current_version_id: version_id
            })
          end
          initial_version = make_version_struct(%{event: "insert"}, changeset_data, options)
            |> @repo.insert!
          updated_changeset = changeset |> change(%{
            first_version_id: initial_version.id, current_version_id: initial_version.id
          })
          model = @repo.insert!(updated_changeset)
          target_version = make_version_struct(%{event: "insert"}, model, options) |> serialize()
          Version.changeset(initial_version, target_version) |> @repo.update!
          model
        _ ->
          model = @repo.insert!(changeset)
          make_version_struct(%{event: "insert"}, model, options) |> @repo.insert!
          model
      end
    end) |> elem(1)
  end

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  def update(changeset, options \\ [origin: nil, meta: nil, originator: nil]) do
    transaction_order = case @client.strict_mode() do
      true ->
        Multi.new
        |> Multi.run(:initial_version, fn %{} ->
          version_data = changeset.data |> Map.merge(%{
            current_version_id: get_sequence_id("versions")
          })
          target_changeset = changeset |> Map.merge(%{data: version_data})
          target_version = make_version_struct(%{event: "update"}, target_changeset, options)
          @repo.insert(target_version)
        end)
        |> Multi.run(:model, fn %{initial_version: initial_version} ->
          updated_changeset = changeset |> change(%{current_version_id: initial_version.id})
          @repo.update(updated_changeset)
        end)
        |> Multi.run(:version, fn %{initial_version: initial_version} ->
          new_item_changes = initial_version.item_changes |> Map.merge(%{
            current_version_id: initial_version.id
          })
          initial_version |> change(%{item_changes: new_item_changes}) |> @repo.update
        end)
      _ ->
        Multi.new
        |> Multi.update(:model, changeset)
        |> Multi.run(:version, fn %{model: _model} ->
          version = make_version_struct(%{event: "update"}, changeset, options)
          @repo.insert(version)
        end)
    end

    transaction = @repo.transaction(transaction_order)

    case @client.strict_mode() do
      true ->
        case transaction do
          {:error, :model, changeset, %{}} ->
            filtered_changes = Map.drop(changeset.changes, [:current_version_id])
            {:error, Map.merge(changeset, %{repo: @repo, changes: filtered_changes})}
          {:ok, map} -> {:ok, Map.delete(map, :initial_version)}
        end
      _ ->
        case transaction do
          {:error, :model, changeset, %{}} -> {:error, Map.merge(changeset, %{repo: @repo})}
          _ -> transaction
        end
    end
  end

  @doc """
  Same as update/2 but returns only the model struct or raises if the changeset is invalid.
  """
  def update!(changeset, options \\ [origin: nil, meta: nil, originator: nil]) do
    @repo.transaction(fn ->
      case @client.strict_mode() do
        true ->
          version_data = changeset.data |> Map.merge(%{
            current_version_id: get_sequence_id("versions")
          })
          target_changeset = changeset |> Map.merge(%{data: version_data})
          target_version = make_version_struct(%{event: "update"}, target_changeset, options)
          initial_version = @repo.insert!(target_version)
          updated_changeset = changeset |> change(%{current_version_id: initial_version.id})
          model = @repo.update!(updated_changeset)
          new_item_changes = initial_version.item_changes |> Map.merge(%{
            current_version_id: initial_version.id
          })
          initial_version |> change(%{item_changes: new_item_changes}) |> @repo.update!
          model
        _ ->
          model = @repo.update!(changeset)
          version_struct = make_version_struct(%{event: "update"}, changeset, options)
          @repo.insert!(version_struct)
          model
      end
    end) |> elem(1)
  end

  @doc """
  Deletes a record from the database with a related version insertion in one transaction
  """
  def delete(struct, options \\ [origin: nil, meta: nil, originator: nil]) do
    transaction = Multi.new
      |> Multi.delete(:model, struct)
      |> Multi.run(:version, fn %{} ->
        version = make_version_struct(%{event: "delete"}, struct, options)
        @repo.insert(version)
      end)
      |> @repo.transaction

    case transaction do
      {:error, :model, changeset, %{}} -> {:error, Map.merge(changeset, %{repo: @repo})}
      _ -> transaction
    end
  end

  @doc """
  Same as delete/2 but returns only the model struct or raises if the changeset is invalid.
  """
  def delete!(struct, options \\ [origin: nil, meta: nil, originator: nil]) do
    @repo.transaction(fn ->
      model = @repo.delete!(struct)
      version_struct = make_version_struct(%{event: "delete"}, struct, options)
      @repo.insert!(version_struct)
      model
    end) |> elem(1)
  end

  defp make_version_structs(%{event: event}, model, changeset, options) do
    model_version = make_version_struct(%{event: event}, model, options)

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

  defp make_version_struct(%{event: "insert"}, model, options) do
    originator_ref = options[@originator[:name]] || options[:originator]
    %Version{
      event: "insert",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: serialize(model),
      originator_id: case originator_ref do
        nil -> nil
        _ -> originator_ref |> Map.get(:id)
      end,
      origin: options[:origin],
      meta: options[:meta]
    }
  end
  defp make_version_struct(%{event: "update"}, changeset, options) do
    originator_ref = options[@originator[:name]] || options[:originator]
    %Version{
      event: "update",
      item_type: changeset.data.__struct__ |> Module.split |> List.last,
      item_id: changeset.data.id,
      item_changes: changeset.changes,
      originator_id: case originator_ref do
        nil -> nil
        _ -> originator_ref |> Map.get(:id)
      end,
      origin: options[:origin],
      meta: options[:meta]
    }
  end
  defp make_version_struct(%{event: "delete"}, model, options) do
    originator_ref = options[@originator[:name]] || options[:originator]
    %Version{
      event: "delete",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: serialize(model),
      originator_id: case originator_ref do
        nil -> nil
        _ -> originator_ref |> Map.get(:id)
      end,
      origin: options[:origin],
      meta: options[:meta]
    }
  end

  defp get_sequence_from_model(changeset) do
    table_name = case Map.get(changeset, :data) do
      nil -> changeset.__struct__.__schema__(:source)
      _ -> changeset.data.__struct__.__schema__(:source)
    end
    get_sequence_id(table_name)
  end

  defp get_sequence_id(table_name) do
    Ecto.Adapters.SQL.query!(@repo, "select last_value FROM #{table_name}_id_seq").rows
    |> List.first
    |> List.first
  end

  defp serialize(model) do
    relationships = model.__struct__.__schema__(:associations)
    Map.drop(model, [:__struct__, :__meta__] ++ relationships)
  end
end
