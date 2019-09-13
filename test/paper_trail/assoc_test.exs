defmodule PaperTrailTest.AssocTest do
  use ExUnit.Case
  import Ecto.Query
  alias PaperTrail.Repo
  alias PaperTrail.Version

  @repo Repo

  setup_all do
    Application.put_env(:paper_trail, :strict_mode, false)
    Application.put_env(:paper_trail, :repo, PaperTrail.Repo)
    Application.put_env(:paper_trail, :item_type, :integer)

    Code.compiler_options(ignore_module_conflict: true)
    Code.eval_file("lib/paper_trail.ex")
    Code.eval_file("lib/version.ex")
    Code.eval_file("test/support/assoc_models.ex")
    Code.compiler_options(ignore_module_conflict: false)
    :ok
  end

  setup do
    @repo.delete_all(Version)
    on_exit fn ->
      @repo.delete_all(Version)
    end
    :ok
  end

  test "for module existence" do
    assert &Assoc.Post.changeset/1
  end

  test "inserting nested assocs should create a version for each" do
    params = %{
      name: "My first post",
      content: "lorem ipsum",
      comments: [%{
        content: "This is a nice post!"
      }, %{
        content: "First!1!!!1eleven1"
      }]
    }

    changeset = Assoc.Post.changeset(%Assoc.Post{}, params)

    case PaperTrail.insert(changeset) do
      {:ok, %{model: %{id: post_id, comments: comments}}} ->
        comment_ids = Enum.map(comments, &(&1.id))

        # check if the models were inserted into the DB
        query = from p in Assoc.Post, where: p.id == ^post_id
        assert Repo.one(query)
        query = from c in Assoc.Comment, where: c.id in ^comment_ids
        assert query |> Repo.all() |> length() == 2

        # check if version entries were created for all of them
        query = from v in PaperTrail.Version,
                  where: v.item_type == "Post" and v.item_id == ^post_id
        assert Repo.one(query)
        query = from v in PaperTrail.Version,
                  where: v.item_type == "Comment" and v.item_id in ^comment_ids
        assert query |> Repo.all() |> length() == 2
      {:error, _} ->
        assert false
    end
  end

  test "deleting a post should create deletion records for its comments" do
    params = %{
      name: "Shitpost",
      content: "Emacs is better than vi",
      comments: [%{
        content: "I respectfully disagree."
      }, %{
        content: "Just because you can't quit vi?"
      }]
    }

    changeset = Assoc.Post.changeset(%Assoc.Post{}, params)

    case PaperTrail.insert(changeset) do
      {:ok, %{model: %{id: post_id, comments: comments}}} ->
        comment_ids = Enum.map(comments, &(&1.id))

        post = Repo.get(Assoc.Post, post_id)

        PaperTrail.delete(post)

        query = from v in PaperTrail.Version,
          where: v.item_id in ^comment_ids,
          where: v.item_type == "Comment",
          where: v.event == "delete"

        assert query |> Repo.all() |> length() == 2
      {:error, _} ->
        assert false
    end
  end

  test "deleting a make should only nilify the car's make" do
    params = %{
      name: "Tesla Motors",
      cars: [
        %{
          model: "Model S"
        }, %{
          model: "Model X"
        }, %{
          model: "Model 3"
        }, %{
          model: "Roadster"
        }
      ]
    }

    %Embed.Make{}
    |> Embed.Make.changeset(params)
    |> PaperTrail.insert()
    |> case do
      {:ok, %{model: %{cars: cars} = make}} ->
        car_ids = Enum.map(cars, &(&1.id))

        assert length(cars) == 4

        PaperTrail.delete(make)

        query = from v in PaperTrail.Version,
          where: v.item_id in ^car_ids,
          where: v.item_type == "Car",
          where: v.event == "update"

        updated_car_versions = Repo.all(query)

        assert length(updated_car_versions) == 4

        assert Enum.at(updated_car_versions, 0).item_changes["make_id"] == nil
      _ ->
        assert false
    end
  end

  test "using embeds without UUID should render inside item_changes" do
    params = %{
      model: "Model S",
      extras: [
        %{name: "Ludicrous mode", price: 10_000},
        %{name: "Autopilot", price: 5_000}
      ]
    }

    %Embed.Car{}
    |> Embed.Car.changeset(params)
    |> PaperTrail.insert()
    |> case do
      {:ok, %{version: version}} ->
        assert version.item_changes.extras |> length() == 2
      _ ->
        assert false
    end
  end
end
