defmodule MultiTenantHelper do
  alias Ecto.Adapters.SQL
  alias Ecto.Changeset

  import Mix.Ecto, only: [build_repo_priv: 1]

  @migrations_path "migrations"
  @tenant "tenant_id"

  def add_prefix_to_changeset(%Changeset{} = changeset) do
    %{changeset | data: add_prefix_to_struct(changeset.data)}
  end

  def add_prefix_to_query(query) do
    query |> Ecto.Queryable.to_query() |> Map.put(:prefix, @tenant)
  end

  def add_prefix_to_struct(%{__struct__: _} = model) do
    Ecto.put_meta(model, prefix: @tenant)
  end

  def setup_tenant(repo, direction \\ :up, opts \\ [all: true]) do
    # Drop the previous tenant to reset the data
    SQL.query(repo, "DROP SCHEMA \"#{@tenant}\" CASCADE", [])

    opts_with_prefix = Keyword.put(opts, :prefix, @tenant)

    # Create new tenant
    SQL.query(repo, "CREATE SCHEMA \"#{@tenant}\"", [])
    Ecto.Migrator.run(repo, migrations_path(repo), direction, opts_with_prefix)
  end

  def tenant(), do: @tenant

  defp migrations_path(repo), do: Path.join(build_repo_priv(repo), @migrations_path)
end
