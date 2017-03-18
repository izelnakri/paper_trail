defmodule PaperTrailTest.VersionQueries do
  use ExUnit.Case

  alias PaperTrail.Version
  alias SimpleCompany, as: Company
  alias SimplePerson, as: Person

  import Ecto.Query

  @repo PaperTrail.RepoClient.repo

  setup_all do
    @repo.delete_all(Person)
    @repo.delete_all(Company)
    @repo.delete_all(Version)

    Company.changeset(%Company{}, %{
      name: "Acme LLC", is_active: true, city: "Greenwich"
    }) |> PaperTrail.insert

    old_company = first(Company, :id) |> @repo.one

    Company.changeset(old_company, %{
      city: "Hong Kong",
      website: "http://www.acme.com",
      facebook: "acme.llc"
    }) |> PaperTrail.update

    first(Company, :id) |> @repo.one |> PaperTrail.delete

    Company.changeset(%Company{}, %{
      name: "Acme LLC",
      website: "http://www.acme.com"
    }) |> PaperTrail.insert

    Company.changeset(%Company{}, %{
      name: "Another Company Corp.",
      is_active: true,
      address: "Sesame street 100/3, 101010"
    }) |> PaperTrail.insert

    company = first(Company, :id) |> @repo.one

    Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: company.id
    }) |> PaperTrail.insert(set_by: "admin") # add link name later on

    another_company = @repo.one(
      from c in Company,
      where: c.name == "Another Company Corp.",
      limit: 1
    )

    Person.changeset(first(Person, :id) |> @repo.one, %{
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01],
      company_id: another_company.id
    }) |> PaperTrail.update(set_by: "user:1", meta: %{linkname: "izelnakri"})

    :ok
  end

  test "get_version gives us the right version" do
    last_person = last(Person, :id) |> @repo.one
    target_version = last(Version, :id) |> @repo.one

    assert PaperTrail.get_version(last_person) == target_version
    assert PaperTrail.get_version(Person, last_person.id) == target_version
  end

  test "get_versions gives us the right versions" do
    last_person = last(Person, :id) |> @repo.one
    target_versions = @repo.all(
      from version in Version,
      where: version.item_type == "SimplePerson" and version.item_id == ^last_person.id
    )

    assert PaperTrail.get_versions(last_person) == target_versions
    assert PaperTrail.get_versions(Person, last_person.id) == target_versions
  end

  test "get_current_model/1 gives us the current record of a version" do
    person = first(Person, :id) |> @repo.one
    first_version = Version |> where([v], v.item_type == "SimplePerson" and v.item_id == ^person.id) |> first |> @repo.one

    assert PaperTrail.get_current_model(first_version) == person
  end
  # query meta data!!
end
