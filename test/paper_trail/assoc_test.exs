defmodule PaperTrailTest.AssocTest do
  use ExUnit.Case
  import Ecto.Query
  alias PaperTrail.Repo
  alias PaperTrail.Version

  @repo Repo

  setup_all do
    Application.put_env(:paper_trail, :strict_mode, false)
    Application.put_env(:paper_trail, :repo, PaperTrail.Repo)
    Code.eval_file("lib/paper_trail.ex")
    Code.eval_file("lib/version.ex")
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
end
