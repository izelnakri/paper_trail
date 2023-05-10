defmodule PaperTrailTest.MultipleItemIDTest do
  use ExUnit.Case
  import PaperTrail.RepoClient, only: [repo: 0]
  alias PaperTrail.Version
  import Ecto.Query

  setup_all do
    Application.put_env(:paper_trail, :repo, PaperTrail.MultipleItemIDRepo)
    Application.put_env(:paper_trail, :item_binary_id_field, :item_uuid)
    Application.put_env(:paper_trail, :additional_fields, item_uuid: :binary_id)

    Code.eval_file("lib/paper_trail.ex")
    Code.eval_file("lib/version.ex")

    repo().delete_all(Version)
    repo().delete_all(User)
    repo().delete_all(Product)

    :ok
  end

  test "creates versions with models that have a UUID primary key" do
    %{id: product_id} = product =
      %Product{}
      |> Product.changeset(%{name: "Hair Cream"})
      |> PaperTrail.insert!()

    version = Version |> last |> repo().one

    assert version.item_uuid == product.id
    assert version.item_type == "Product"
    assert is_nil(version.item_id)

    version = PaperTrail.get_version(product)

    assert %{
      event: "insert",
      item_type: "Product",
      item_id: nil,
      item_changes: %{
        "id" => ^product_id,
        "name" => "Hair Cream"
      },
      originator_id: nil,
      item_uuid: ^product_id,
      origin: nil,
      meta: nil,
    } = version
  end

  test "creates versions with models that have an integer primary key" do
    %{id: user_id} = user =
      %User{}
      |> User.changeset(%{username: "unknown", token: "fake-token"})
      |> PaperTrail.insert!()

    version = Version |> last |> repo().one

    assert version.item_id == user.id
    assert version.item_type == "User"
    assert is_nil(version.item_uuid)

    version = PaperTrail.get_version(user)

    assert %{
      event: "insert",
      item_type: "User",
      item_id: ^user_id,
      item_changes: %{
        "id" => ^user_id,
        "token" => "fake-token",
        "username" => "unknown"
      },
      originator_id: nil,
      item_uuid: nil,
      origin: nil,
      meta: nil,
    } = version
  end
end
