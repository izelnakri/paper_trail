defmodule PaperTrailTest.VersionQueries do
  use ExUnit.Case
  alias PaperTrail.Version
  import Ecto.Query

  setup_all do
    Repo.delete_all(Person)
    Repo.delete_all(Company)
    Repo.delete_all(PaperTrail.Version)

    Company.changeset(%Company{}, %{
      name: "Acme LLC", is_active: true, city: "Greenwich", people: []
    }) |> PaperTrail.insert

    old_company = first(Company, :id) |> preload(:people) |> Repo.one

    Company.changeset(old_company, %{
      city: "Hong Kong",
      website: "http://www.acme.com",
      facebook: "acme.llc"
    }) |> PaperTrail.update

    first(Company, :id) |> preload(:people) |> Repo.one |> PaperTrail.delete

    Company.changeset(%Company{}, %{
      name: "Acme LLC",
      website: "http://www.acme.com"
    }) |> PaperTrail.insert

    Company.changeset(%Company{}, %{
      name: "Another Company Corp.",
      is_active: true,
      address: "Sesame street 100/3, 101010"
    }) |> PaperTrail.insert

    company = first(Company, :id) |> Repo.one

    new_person = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: company.id
    }) |> PaperTrail.insert(%{originator: "admin"}) # add link name later on

    another_company = Repo.one(
      from c in Company,
      where: c.name == "Another Company Corp.",
      limit: 1
    )

    Person.changeset(first(Person, :id) |> Repo.one, %{
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01],
      company_id: another_company.id
    }) |> PaperTrail.update(%{ originator: "user:1", linkname: "izelnakri" })

    :ok
  end

  test "get_version gives us the right version" do
    last_person = last(Person, :id) |> Repo.one
    target_version = last(Version, :id) |> Repo.one

    assert PaperTrail.get_version(last_person) == target_version
    assert PaperTrail.get_version(Person, last_person.id) == target_version
  end

  test "get_versions gives us the right versions" do
    last_person = last(Person, :id) |> Repo.one
    target_versions = Repo.all(
      from version in Version,
      where: version.item_type == "Person" and version.item_id == ^last_person.id
    )

    assert PaperTrail.get_versions(last_person) == target_versions
    assert PaperTrail.get_versions(Person, last_person.id) == target_versions
  end

  test "get_current gives us the current record of a version" do
    person = first(Person, :id) |> Repo.one
    first_version = Version |> where([v], v.item_type == "Person" and v.item_id == ^person.id) |> first |> Repo.one

    assert PaperTrail.get_current(first_version) == person
  end
  # query meta data!!

end
