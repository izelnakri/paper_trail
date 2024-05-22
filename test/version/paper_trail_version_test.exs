defmodule PaperTrailTest.Version do
  use ExUnit.Case

  alias PaperTrail.Version
  alias PaperTrailTest.MultiTenantHelper, as: MultiTenant
  alias PaperTrail.RepoClient
  alias PaperTrail.Serializer

  @valid_attrs %{
    event: "insert",
    item_type: "Person",
    item_id: 1,
    item_changes: %{first_name: "Izel", last_name: "Nakri"},
    origin: "test",
    inserted_at: DateTime.from_naive!(~N[1952-04-01 01:00:00], "Etc/UTC")
  }
  @invalid_attrs %{}

  defdelegate repo, to: RepoClient
  defdelegate serialize(data), to: Serializer

  setup_all do
    Application.put_env(:paper_trail, :strict_mode, false)
    Application.put_env(:paper_trail, :repo, PaperTrail.Repo)
    Application.put_env(:paper_trail, :originator_type, :integer)
    Code.eval_file("lib/paper_trail.ex")
    Code.eval_file("lib/version.ex")
    MultiTenant.setup_tenant(repo())
    :ok
  end

  setup do
    Version
    |> MultiTenant.add_prefix_to_query()
    |> repo().delete_all()

    on_exit(fn ->
      repo().delete_all(Version)

      Version
      |> MultiTenant.add_prefix_to_query()
      |> repo().delete_all()
    end)

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
    assert Version.count() == length(versions)
  end

  test "first works" do
    add_three_versions()

    target_model =
      @valid_attrs
      |> Map.delete(:inserted_at)
      |> Map.merge(%{
        item_changes: %{"first_name" => "Izel", "last_name" => "Nakri"}
      })

    target_version =
      Version.first()
      |> serialize
      |> Map.drop([
        :id,
        :meta,
        :originator_id,
        :inserted_at
      ])

    assert target_version == target_model
  end

  test "last works" do
    add_three_versions()

    assert Version.last() |> serialize != %{
             event: "insert",
             item_type: "Person",
             item_id: 3,
             item_changes: %{first_name: "Yukihiro", last_name: "Matsumoto"},
             origin: "test",
             inserted_at: DateTime.from_naive!(~N[1965-04-14 01:00:00], "Etc/UTC")
           }
  end

  # Multi tenant tests
  test "[multi tenant] count works" do
    versions = add_three_versions(MultiTenant.tenant())
    assert Version.count(prefix: MultiTenant.tenant()) == length(versions)
    assert Version.count() != length(versions)
  end

  test "[multi tenant] first works" do
    add_three_versions(MultiTenant.tenant())

    target_version =
      Version.first(prefix: MultiTenant.tenant())
      |> serialize
      |> Map.drop([
        :id,
        :meta,
        :originator_id,
        :inserted_at
      ])

    target_model =
      @valid_attrs
      |> Map.delete(:inserted_at)
      |> Map.merge(%{
        item_changes: %{"first_name" => "Izel", "last_name" => "Nakri"}
      })

    assert target_version == target_model
    assert Version.first() == nil
  end

  test "[multi tenant] last works" do
    add_three_versions(MultiTenant.tenant())

    assert Version.last(prefix: MultiTenant.tenant()) |> serialize != %{
             event: "insert",
             item_type: "Person",
             item_id: 3,
             item_changes: %{first_name: "Yukihiro", last_name: "Matsumoto"},
             origin: "test",
             inserted_at: DateTime.from_naive!(~N[1965-04-14 01:00:00], "Etc/UTC")
           }

    assert Version.last() == nil
  end

  def add_three_versions(prefix \\ nil) do
    repo().insert_all(
      Version,
      [
        @valid_attrs,
        %{
          event: "insert",
          item_type: "Person",
          item_id: 2,
          item_changes: %{first_name: "Brendan", last_name: "Eich"},
          origin: "test",
          inserted_at: DateTime.from_naive!(~N[1961-07-04 01:00:00], "Etc/UTC")
        },
        %{
          event: "insert",
          item_type: "Person",
          item_id: 3,
          item_changes: %{first_name: "Yukihiro", last_name: "Matsumoto"},
          origin: "test",
          inserted_at: DateTime.from_naive!(~N[1965-04-14 01:00:00], "Etc/UTC")
        }
      ],
      returning: true,
      prefix: prefix
    )
    |> elem(1)
  end
end
