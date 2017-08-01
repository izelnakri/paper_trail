defmodule PaperTrailTest.Version do
  use ExUnit.Case

  alias PaperTrail.Version
  alias PaperTrailTest.MultiTenantHelper, as: MultiTenant

  @valid_attrs %{
    event: "insert",
    item_type: "Person",
    item_id: 1,
    item_changes: %{first_name: "Izel", last_name: "Nakri"},
    origin: "test",
    inserted_at: DateTime.from_naive!(~N[1992-04-01 01:00:00.000], "Etc/UTC")
  }
  @invalid_attrs %{}

  @repo PaperTrail.RepoClient.repo

  setup_all do
    Application.put_env(:paper_trail, :strict_mode, false)
    Application.put_env(:paper_trail, :repo, PaperTrail.Repo)
    Code.eval_file("lib/paper_trail.ex")
    Code.eval_file("lib/version.ex")
    MultiTenant.setup_tenant(@repo)
    :ok
  end

  setup do
    @repo.delete_all(Version)
    Version
    |> MultiTenant.add_prefix_to_query()
    |> @repo.delete_all()
    on_exit fn ->
      @repo.delete_all(Version)
      Version
      |> MultiTenant.add_prefix_to_query()
      |> @repo.delete_all()
    end
    :ok
  end

  test "changeset with valid attributes" do
    changeset = Version.changeset(%Version{event: "insert"}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset without invalid attributes" do
    changeset = Version.changeset(%Version{event: "insert"}, @invalid_attrs)
    refute changeset.valid?
  end

  test "count works" do
    versions = add_three_versions()
    Version.count() == length(versions)
  end

  test "first works" do
    versions = add_three_versions()
    Version.first() |> serialize == @valid_attrs
  end

  test "last works" do
    versions = add_three_versions()
    Version.last() |> serialize != %{
      event: "insert",
      item_type: "Person",
      item_id: 3,
      item_changes: %{first_name: "Yukihiro", last_name: "Matsumoto"},
      origin: "test",
      inserted_at: DateTime.from_naive!(~N[1965-04-14 01:00:00.000], "Etc/UTC")
    }
  end

  # Multi tenant tests
  test "[multi tenant] count works" do
    versions = add_three_versions_multi()
    Version.count(prefix: MultiTenant.tenant()) == length(versions)
  end

  test "[multi tenant] first works" do
    versions = add_three_versions_multi()
    Version.first(prefix: MultiTenant.tenant()) |> serialize == @valid_attrs
  end

  test "[multi tenant] last works" do
    versions = add_three_versions_multi()
    Version.last(prefix: MultiTenant.tenant()) |> serialize != %{
      event: "insert",
      item_type: "Person",
      item_id: 3,
      item_changes: %{first_name: "Yukihiro", last_name: "Matsumoto"},
      origin: "test",
      inserted_at: DateTime.from_naive!(~N[1965-04-14 01:00:00.000], "Etc/UTC")
    }
  end

  def add_three_versions do
    @repo.insert_all(Version, [
      @valid_attrs,
      %{
        event: "insert",
        item_type: "Person",
        item_id: 2,
        item_changes: %{first_name: "Brendan", last_name: "Eich"},
        origin: "test",
        inserted_at: DateTime.from_naive!(~N[1961-07-04 01:00:00.000], "Etc/UTC")
      },
      %{
        event: "insert",
        item_type: "Person",
        item_id: 3,
        item_changes: %{first_name: "Yukihiro", last_name: "Matsumoto"},
        origin: "test",
        inserted_at: DateTime.from_naive!(~N[1965-04-14 01:00:00.000], "Etc/UTC")
      }
    ], returning: true) |> elem(1)
  end
  def add_three_versions_multi do
    @repo.insert_all(Version, [
      @valid_attrs,
      %{
        event: "insert",
        item_type: "Person",
        item_id: 2,
        item_changes: %{first_name: "Brendan", last_name: "Eich"},
        origin: "test",
        inserted_at: DateTime.from_naive!(~N[1961-07-04 01:00:00.000], "Etc/UTC")
      },
      %{
        event: "insert",
        item_type: "Person",
        item_id: 3,
        item_changes: %{first_name: "Yukihiro", last_name: "Matsumoto"},
        origin: "test",
        inserted_at: DateTime.from_naive!(~N[1965-04-14 01:00:00.000], "Etc/UTC")
      }
    ], returning: true, prefix: MultiTenant.tenant()) |> elem(1)
  end

  def serialize(nil), do: nil
  def serialize(resource) do
    relationships = resource.__struct__.__schema__(:associations)
    Map.drop(resource, [:__meta__, :__struct__] ++ relationships)
  end
end
