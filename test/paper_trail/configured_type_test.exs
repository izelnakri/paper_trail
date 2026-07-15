defmodule PaperTrailTest.ConfiguredTypeTest do
  @moduledoc """
  Custom Ecto types for `item_id`/`originator_id` must be resolved from config at runtime, so that types provided by other libraries work regardless of dependency compilation order.
  See https://github.com/izelnakri/paper_trail/issues/235
  """
  use ExUnit.Case

  defmodule DowncasedString do
    use Ecto.Type
    def type, do: :string
    def cast(value) when is_binary(value), do: {:ok, String.downcase(value)}
    def cast(_), do: :error
    def load(value), do: {:ok, value}
    def dump(value) when is_binary(value), do: {:ok, value}
    def dump(_), do: :error
  end

  defmodule ParameterizedDowncasedString do
    use Ecto.ParameterizedType
    def init(opts), do: Map.new(opts)
    def type(_params), do: :string
    def cast(value, _params) when is_binary(value), do: {:ok, String.downcase(value)}
    def cast(_, _params), do: :error
    def load(value, _loader, _params), do: {:ok, value}
    def dump(value, _dumper, _params) when is_binary(value), do: {:ok, value}
    def dump(_, _dumper, _params), do: :error
  end

  setup do
    original = Application.fetch_env(:paper_trail, :item_type)

    on_exit(fn ->
      case original do
        {:ok, value} -> Application.put_env(:paper_trail, :item_type, value)
        :error -> Application.delete_env(:paper_trail, :item_type)
      end
    end)

    :ok
  end

  defp item_id_type, do: PaperTrail.Version.__schema__(:type, :item_id)

  test "item_id defaults to :integer" do
    Application.delete_env(:paper_trail, :item_type)

    assert {:ok, 42} = Ecto.Type.cast(item_id_type(), "42")
    assert {:ok, 42} = Ecto.Type.dump(item_id_type(), 42)
  end

  test "item_id casts through an Ecto.Type module configured at runtime" do
    Application.put_env(:paper_trail, :item_type, DowncasedString)

    assert {:ok, "abc"} = Ecto.Type.cast(item_id_type(), "ABC")
  end

  test "item_id casts through an Ecto.ParameterizedType module configured at runtime" do
    Application.put_env(:paper_trail, :item_type, ParameterizedDowncasedString)

    assert {:ok, "abc"} = Ecto.Type.cast(item_id_type(), "ABC")
  end
end