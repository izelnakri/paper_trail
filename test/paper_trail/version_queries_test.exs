defmodule PaperTrailTest.VersionQueries do
  use ExUnit.Case

  alias PaperTrail.Version
  alias SimpleCompany, as: Company
  alias SimplePerson, as: Person
  alias PaperTrailTest.MultiTenantHelper, as: MultiTenant

  import Ecto.Query

  @repo PaperTrail.RepoClient.repo()

  setup_all do
    MultiTenant.setup_tenant(@repo)
    reset_all_data()

    Company.changeset(%Company{}, %{
      name: "Acme LLC",
      is_active: true,
      city: "Greenwich"
    })
    |> PaperTrail.insert()

    old_company = first(Company, :id) |> @repo.one

    Company.changeset(old_company, %{
      city: "Hong Kong",
      website: "http://www.acme.com",
      facebook: "acme.llc"
    })
    |> PaperTrail.update()

    first(Company, :id) |> @repo.one |> PaperTrail.delete()

    Company.changeset(%Company{}, %{
      name: "Acme LLC",
      website: "http://www.acme.com"
    })
    |> PaperTrail.insert()

    Company.changeset(%Company{}, %{
      name: "Another Company Corp.",
      is_active: true,
      address: "Sesame street 100/3, 101010"
    })
    |> PaperTrail.insert()

    company = first(Company, :id) |> @repo.one

    # add link name later on
    Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: company.id
    })
    |> PaperTrail.insert(set_by: "admin")

    another_company =
      @repo.one(
        from(
          c in Company,
          where: c.name == "Another Company Corp.",
          limit: 1
        )
      )

    Person.changeset(first(Person, :id) |> @repo.one, %{
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01],
      company_id: another_company.id
    })
    |> PaperTrail.update(set_by: "user:1", meta: %{linkname: "izelnakri"})

    # Multi tenant
    Company.changeset(%Company{}, %{
      name: "Acme LLC",
      is_active: true,
      city: "Greenwich"
    })
    |> MultiTenant.add_prefix_to_changeset()
    |> PaperTrail.insert(prefix: MultiTenant.tenant())

    company_multi =
      first(Company, :id)
      |> MultiTenant.add_prefix_to_query()
      |> @repo.one

    Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: company_multi.id
    })
    |> MultiTenant.add_prefix_to_changeset()
    |> PaperTrail.insert(set_by: "admin", prefix: MultiTenant.tenant())

    :ok
  end

  test "get_version gives us the right version" do
    tenant = MultiTenant.tenant()
    last_person = last(Person, :id) |> @repo.one
    target_version = last(Version, :id) |> @repo.one

    last_person_multi =
      last(Person, :id)
      |> MultiTenant.add_prefix_to_query()
      |> @repo.one

    target_version_multi =
      last(Version, :id)
      |> MultiTenant.add_prefix_to_query()
      |> @repo.one

    assert PaperTrail.get_version(last_person) == target_version
    assert PaperTrail.get_version(Person, last_person.id) == target_version
    assert PaperTrail.get_version(last_person_multi, prefix: tenant) == target_version_multi

    assert PaperTrail.get_version(Person, last_person_multi.id, prefix: tenant) ==
             target_version_multi

    assert target_version != target_version_multi
  end

  test "get_versions gives us the right versions" do
    tenant = MultiTenant.tenant()
    last_person = last(Person, :id) |> @repo.one

    target_versions =
      @repo.all(
        from(
          version in Version,
          where: version.item_type == "SimplePerson" and version.item_id == ^last_person.id
        )
      )

    last_person_multi =
      last(Person, :id)
      |> MultiTenant.add_prefix_to_query()
      |> @repo.one

    target_versions_multi =
      from(
        version in Version,
        where: version.item_type == "SimplePerson" and version.item_id == ^last_person_multi.id
      )
      |> MultiTenant.add_prefix_to_query()
      |> @repo.all

    assert PaperTrail.get_versions(last_person) == target_versions
    assert PaperTrail.get_versions(Person, last_person.id) == target_versions
    assert PaperTrail.get_versions(last_person_multi, prefix: tenant) == target_versions_multi

    assert PaperTrail.get_versions(Person, last_person_multi.id, prefix: tenant) ==
             target_versions_multi

    assert target_versions != target_versions_multi
  end

  test "get_current_model/1 gives us the current record of a version" do
    person = first(Person, :id) |> @repo.one

    first_version =
      Version |> where([v], v.item_type == "SimplePerson" and v.item_id == ^person.id) |> first
      |> @repo.one

    assert PaperTrail.get_current_model(first_version) == person
  end

  # query meta data!!

  # Functions
  defp reset_all_data() do
    @repo.delete_all(Person)
    @repo.delete_all(Company)
    @repo.delete_all(Version)

    Person
    |> MultiTenant.add_prefix_to_query()
    |> @repo.delete_all()

    Company
    |> MultiTenant.add_prefix_to_query()
    |> @repo.delete_all()

    Version
    |> MultiTenant.add_prefix_to_query()
    |> @repo.delete_all()
  end
end
