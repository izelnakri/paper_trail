defmodule PaperTrail.Serializer do
  @moduledoc """
  Serialization functions to create a version struct
  """

  alias PaperTrail.RepoClient
  alias PaperTrail.Version

  @type model :: struct() | Ecto.Changeset.t()
  @type options :: Keyword.t()
  @type primary_key :: integer() | String.t()

  @doc """
  Creates a version struct for a model and a specific changeset action
  """
  @spec make_version_struct(map(), model(), options()) :: Version.t()
  def make_version_struct(%{event: "insert"}, model, options) do
    originator = RepoClient.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    %Version{
      event: "insert",
      item_type: get_item_type(model),
      item_id: get_model_id(model),
      item_changes: serialize(model),
      originator_id:
        case originator_ref do
          nil -> nil
          %{id: id} -> id
          model when is_struct(model) -> get_model_id(originator_ref)
        end,
      origin: options[:origin],
      meta: options[:meta]
    }
    |> add_prefix(options[:prefix])
  end

  def make_version_struct(%{event: "update"}, changeset, options) do
    originator = RepoClient.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    %Version{
      event: "update",
      item_type: get_item_type(changeset),
      item_id: get_model_id(changeset),
      item_changes: serialize_changes(changeset),
      originator_id:
        case originator_ref do
          nil -> nil
          %{id: id} -> id
          model when is_struct(model) -> get_model_id(originator_ref)
        end,
      origin: options[:origin],
      meta: options[:meta]
    }
    |> add_prefix(options[:prefix])
  end

  def make_version_struct(%{event: "delete"}, model_or_changeset, options) do
    originator = RepoClient.originator()
    originator_ref = options[originator[:name]] || options[:originator]

    %Version{
      event: "delete",
      item_type: get_item_type(model_or_changeset),
      item_id: get_model_id(model_or_changeset),
      item_changes: serialize(model_or_changeset),
      originator_id:
        case originator_ref do
          nil -> nil
          %{id: id} -> id
          model when is_struct(model) -> get_model_id(originator_ref)
        end,
      origin: options[:origin],
      meta: options[:meta]
    }
    |> add_prefix(options[:prefix])
  end

  @doc """
  Returns the last primary key value of a table
  """
  @spec get_sequence_id(model() | String.t()) :: primary_key()
  def get_sequence_id(%Ecto.Changeset{data: data}) do
    get_sequence_id(data)
  end

  def get_sequence_id(%schema{}) do
    :source
    |> schema.__schema__()
    |> get_sequence_id()
  end

  def get_sequence_id(table_name) when is_binary(table_name) do
    Ecto.Adapters.SQL.query!(RepoClient.repo(), "select last_value FROM #{table_name}_id_seq").rows
    |> List.first()
    |> List.first()
  end

  @doc """
  Shows DB representation of an Ecto model, filters relationships and virtual attributes from an Ecto.Changeset or %ModelStruct{}
  """
  @spec serialize(nil | Ecto.Changeset.t() | struct()) :: nil | map()
  def serialize(nil), do: nil
  def serialize(%Ecto.Changeset{data: data}), do: serialize(data)
  def serialize(%_schema{} = model), do: Ecto.embedded_dump(model, :json)

  @doc """
  Dumps changes using Ecto fields
  """
  @spec serialize_changes(Ecto.Changeset.t()) :: map()
  def serialize_changes(%Ecto.Changeset{data: %schema{}, changes: changes}) do
    changes
    |> schema.__struct__()
    |> serialize()
    |> Map.take(Map.keys(changes))
  end

  @doc """
  Adds a prefix to the Ecto schema
  """
  @spec add_prefix(Ecto.Schema.schema(), nil | String.t()) :: Ecto.Schema.schema()
  def add_prefix(schema, nil), do: schema
  def add_prefix(schema, prefix), do: Ecto.put_meta(schema, prefix: prefix)

  @doc """
  Returns the model type, which is the last module name
  """
  @spec get_item_type(model()) :: String.t()
  def get_item_type(%Ecto.Changeset{data: data}), do: get_item_type(data)
  def get_item_type(%schema{}), do: schema |> Module.split() |> List.last()

  @doc """
  Returns the model primary id
  """
  @spec get_model_id(model()) :: primary_key()
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
