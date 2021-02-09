defmodule PaperTrail.Multi do
  @moduledoc false
  # TODO: Will be documented again as soon as the insert / update / delete
  # functions are overhauled

  import Ecto.Changeset

  alias PaperTrail
  alias PaperTrail.Version
  alias PaperTrail.RepoClient
  alias PaperTrail.Serializer

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.new/0"
  defdelegate new(), to: Ecto.Multi

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.append/2"
  defdelegate append(lhs, rhs), to: Ecto.Multi

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.error/3"
  defdelegate error(multi, name, value), to: Ecto.Multi

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.merge/2"
  defdelegate merge(multi, merge), to: Ecto.Multi

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.merge/4"
  defdelegate merge(multi, mod, fun, args), to: Ecto.Multi

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.prepend/2"
  defdelegate prepend(lhs, rhs), to: Ecto.Multi

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.run/3"
  defdelegate run(multi, name, run), to: Ecto.Multi

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.run/5"
  defdelegate run(multi, name, mod, fun, args), to: Ecto.Multi

  # TODO: Remove Function with next major release
  @doc false
  @deprecated "Use Ecto.Multi.to_list/1"
  defdelegate to_list(multi), to: Ecto.Multi

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

  def insert(%Ecto.Multi{} = multi, changeset, options \\ []) do
    model_key = options[:model_key] || :model
    version_key = options[:version_key] || :version
    ecto_options = options[:ecto_options] || []

    case RepoClient.strict_mode() do
      true ->
        multi
        |> Ecto.Multi.run(:initial_version, fn repo, %{} ->
          version_id = get_sequence_id("versions") + 1

          changeset_data =
            Map.get(changeset, :data, changeset)
            |> Map.merge(%{
              id: get_sequence_id(changeset) + 1,
              first_version_id: version_id,
              current_version_id: version_id
            })

          initial_version = make_version_struct(%{event: "insert"}, changeset_data, options)
          repo.insert(initial_version)
        end)
        |> Ecto.Multi.run(model_key, fn repo, %{initial_version: initial_version} ->
          updated_changeset =
            changeset
            |> change(%{
              first_version_id: initial_version.id,
              current_version_id: initial_version.id
            })

          repo.insert(updated_changeset, ecto_options)
        end)
        |> Ecto.Multi.run(version_key, fn repo,
                                          %{initial_version: initial_version, model: model} ->
          target_version = make_version_struct(%{event: "insert"}, model, options) |> serialize()

          Version.changeset(initial_version, target_version) |> repo.update
        end)

      _ ->
        multi
        |> Ecto.Multi.insert(model_key, changeset, ecto_options)
        |> Ecto.Multi.run(version_key, fn repo, %{^model_key => model} ->
          version = make_version_struct(%{event: "insert"}, model, options)
          repo.insert(version)
        end)
    end
  end

  def update(%Ecto.Multi{} = multi, changeset, options \\ []) do
    case RepoClient.strict_mode() do
      true ->
        multi
        |> Ecto.Multi.run(:initial_version, fn repo, %{} ->
          version_data =
            changeset.data
            |> Map.merge(%{
              current_version_id: get_sequence_id("versions")
            })

          target_changeset = changeset |> Map.merge(%{data: version_data})
          target_version = make_version_struct(%{event: "update"}, target_changeset, options)
          repo.insert(target_version)
        end)
        |> Ecto.Multi.run(:model, fn repo, %{initial_version: initial_version} ->
          updated_changeset = changeset |> change(%{current_version_id: initial_version.id})
          repo.update(updated_changeset, Keyword.take(options, [:returning]))
        end)
        |> Ecto.Multi.run(:version, fn repo, %{initial_version: initial_version} ->
          new_item_changes =
            initial_version.item_changes
            |> Map.merge(%{
              current_version_id: initial_version.id
            })

          initial_version |> change(%{item_changes: new_item_changes}) |> repo.update
        end)

      _ ->
        multi
        |> Ecto.Multi.update(:model, changeset, Keyword.take(options, [:returning]))
        |> Ecto.Multi.run(:version, fn repo, %{model: _model} ->
          version = make_version_struct(%{event: "update"}, changeset, options)
          repo.insert(version)
        end)
    end
  end

  def delete(%Ecto.Multi{} = multi, struct, options \\ []) do
    multi
    |> Ecto.Multi.delete(:model, struct, options)
    |> Ecto.Multi.run(:version, fn repo, %{} ->
      version = make_version_struct(%{event: "delete"}, struct, options)
      repo.insert(version, options)
    end)
  end

  def commit(%Ecto.Multi{} = multi) do
    repo = RepoClient.repo()

    transaction = repo.transaction(multi)

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
          _ -> transaction
        end
    end
  end
end
