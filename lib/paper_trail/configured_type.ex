defmodule PaperTrail.ConfiguredType do
  @moduledoc """
  An `Ecto.ParameterizedType` that delegates to the type configured against the `:paper_trail` app, resolved at runtime. For example, with:

      config :paper_trail, item_type: Needle.ULID

  the `versions` table's `item_id` field (declared as `field(:item_id, PaperTrail.ConfiguredType, configured_as: :item_type)`) will cast/dump/load through the configured type.

  Because the configured module is only looked up when the type is used, and not while `PaperTrail.Version` is being compiled, custom Ecto types provided by other libraries can be configured without PaperTrail needing a compile-time dependency on them (which used to make compilation fail with `unknown type ... for field :item_id` depending on dependency compilation order). See https://github.com/izelnakri/paper_trail/issues/235

  The configured type may be a base Ecto type (e.g. the default `:integer`), an `Ecto.Type` module, or an `Ecto.ParameterizedType` module.
  """
  use Ecto.ParameterizedType

  alias PaperTrail.RepoClient

  # `PaperTrail.RepoClient` getters that may be delegated to
  # NOTE: validated as a static list because `init/1` runs while `PaperTrail.Version` compiles, when other modules of this library may not be loadable yet
  @configurable [:item_type, :originator_type]

  @impl true
  def init(opts) do
    key = Keyword.fetch!(opts, :configured_as)

    unless key in @configurable do
      raise ArgumentError,
            "expected `configured_as:` to be one of #{inspect(@configurable)}, got: #{inspect(key)}"
    end

    %{key: key, field_opts: Keyword.drop(opts, [:configured_as])}
  end

  @impl true
  def type(params), do: Ecto.Type.type(delegate(params))

  @impl true
  def cast(value, params), do: Ecto.Type.cast(delegate(params), value)

  @impl true
  def load(value, _loader, params), do: Ecto.Type.load(delegate(params), value)

  @impl true
  def dump(value, _dumper, params), do: Ecto.Type.dump(delegate(params), value)

  @impl true
  def equal?(value1, value2, params), do: Ecto.Type.equal?(delegate(params), value1, value2)

  @impl true
  def embed_as(_format, _params), do: :self

  # Resolves the configured type into a type spec that the `Ecto.Type`
  # functions accept, building an `Ecto.ParameterizedType` spec when the
  # configured module requires it.
  defp delegate(%{key: key, field_opts: field_opts}) do
    type = apply(RepoClient, key, [])

    if not Ecto.Type.base?(type) and Code.ensure_loaded?(type) and
         function_exported?(type, :init, 1) do
      Ecto.ParameterizedType.init(type, field_opts)
    else
      type
    end
  end
end