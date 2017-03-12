defmodule PaperTrail do
  import Ecto.Changeset

  alias PaperTrail.VersionQueries

  alias Ecto.Multi
  alias PaperTrail.Version

  @repo PaperTrail.RepoClient.repo
  @client PaperTrail.RepoClient

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
  Gets the current record of a version
  """
  def get_current(version) do
    VersionQueries.get_current(version)
  end

  @doc """
  Inserts a record to the database with a related version insertion in one transaction
  """
  def insert(changeset, options \\ [sourced_by: nil, meta: nil]) do
    case @client.strict_mode() do
      true ->
        Multi.new
        |> Multi.run(:initial_version, fn %{} ->
          version_id = get_sequence_id("versions") + 1
          changeset_data = changeset.data |> Map.merge(%{
            id: get_sequence_from_model(changeset) + 1,
            first_version_id: version_id,
            current_version_id: version_id
          })
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
        |> @repo.transaction
      _ ->
        Multi.new
        |> Multi.insert(:model, changeset)
        |> Multi.run(:version, fn %{model: model} ->
            version = make_version_struct(%{event: "insert"}, model, options)
            @repo.insert(version)
          end)
        |> @repo.transaction
    end
  end

  @doc """
  Updates a record from the database with a related version insertion in one transaction
  """
  def update(changeset, options \\ [sourced_by: nil, meta: nil]) do
    case @client.strict_mode() do
      true ->
        Multi.new
        |> Multi.run(:version, fn %{} ->
          version_data = changeset.data |> Map.merge(%{current_version_id: get_sequence_id("versions")})
          target_changeset = changeset |> Map.merge(%{data: version_data})
          target_version = make_version_struct(%{event: "update"}, target_changeset, options)
          @repo.insert(target_version)
        end)
        |> Multi.run(:model, fn %{version: version} ->
          updated_changeset = changeset |> change(%{current_version_id: version.id})
          @repo.update(updated_changeset)
        end)
        |> @repo.transaction
      _ ->
        Multi.new
        |> Multi.update(:model, changeset)
        |> Multi.run(:version, fn %{model: _model} ->
            version = make_version_struct(%{event: "update"}, changeset, options)
            @repo.insert(version)
          end)
        |> @repo.transaction
    end
  end

  @doc """
  Deletes a record from the database with a related version insertion in one transaction
  """
  def delete(struct, options \\ [sourced_by: nil, meta: nil]) do
    Multi.new
    |> Multi.delete(:model, struct)
    |> Multi.run(:version, fn %{} ->
      version = make_version_struct(%{event: "delete"}, struct, options)
      @repo.insert(version)
    end)
    |> @repo.transaction
  end

  defp make_version_struct(event_list, model, options \\ [])
  defp make_version_struct(%{event: "insert"}, model, options) do
    %Version{
      event: "insert",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: serialize(model),
      sourced_by: options[:sourced_by],
      meta: options[:meta]
    }
  end
  defp make_version_struct(%{event: "update"}, changeset, options) do
    %Version{
      event: "update",
      item_type: changeset.data.__struct__ |> Module.split |> List.last,
      item_id: changeset.data.id,
      item_changes: changeset.changes,
      sourced_by: options[:sourced_by],
      meta: options[:meta]
    }
  end
  defp make_version_struct(%{event: "delete"}, model, options) do
    %Version{
      event: "delete",
      item_type: model.__struct__ |> Module.split |> List.last,
      item_id: model.id,
      item_changes: serialize(model),
      sourced_by: options[:sourced_by],
      meta: options[:meta]
    }
  end

  defp get_sequence_from_model(changeset) do
    table_name = changeset.data.__struct__.__schema__(:source)
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
