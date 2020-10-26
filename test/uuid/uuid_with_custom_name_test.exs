defmodule PaperTrailTest.UUIDWithCustomNameTest do
  use ExUnit.Case
  import PaperTrail.RepoClient, only: [repo: 0]
  alias PaperTrail.Version
  import Ecto.Query

  setup_all do
    Application.put_env(:paper_trail, :repo, PaperTrail.UUIDWithCustomNameRepo)
    Application.put_env(:paper_trail, :originator, name: :originator, model: Person)
    Application.put_env(:paper_trail, :originator_type, Ecto.UUID)
    Application.put_env(:paper_trail, :originator_relationship_options, references: :uuid)

    Application.put_env(
      :paper_trail,
      :item_type,
      if(System.get_env("STRING_TEST") == nil, do: Ecto.UUID, else: :string)
    )

    Code.eval_file("lib/paper_trail.ex")
    Code.eval_file("lib/version.ex")

    repo().delete_all(Version)
    repo().delete_all(Person)
    repo().delete_all(Project)
    :ok
  end

  describe "PaperTrailTest.UUIDWithCustomNameTest" do
    test "handles originators with a UUID primary key" do
      person =
        %Person{}
        |> Person.changeset(%{email: "admin@example.com"})
        |> repo().insert!

      %Project{}
      |> Project.changeset(%{name: "Interesting Stuff"})
      |> PaperTrail.insert!(originator: person)

      version =
        Version
        |> last
        |> repo().one
        |> repo().preload(:originator)

      assert version.originator == person
    end
  end
end
