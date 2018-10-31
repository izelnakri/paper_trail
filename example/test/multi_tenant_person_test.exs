defmodule MultiTenantPersonTest do
  use ExUnit.Case
  import Ecto.Query

  setup_all do
    Repo.delete_all(PaperTrail.Version)
    MultiTenantHelper.setup_tenant(Repo)

    %Company{}
    |> Company.changeset(%{name: "Acme LLC", website: "http://www.acme.com"})
    |> MultiTenantHelper.add_prefix_to_changeset()
    |> Repo.insert()

    %Company{}
    |> Company.changeset(%{name: "Another Company Corp.", is_active: true, address: "Sesame street 100/3, 101010"})
    |> MultiTenantHelper.add_prefix_to_changeset()
    |> Repo.insert()

    :ok
  end

  test "[multi tenant] creating a person with meta tag creates a person version with correct attributes" do
    company =
      first(Company, :id)
      |> preload(:people)
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.one()

    {:ok, result} =
      %Person{}
      |> Person.changeset(%{first_name: "Izel", last_name: "Nakri", gender: true, company_id: company.id})
      |> MultiTenantHelper.add_prefix_to_changeset()
      |> PaperTrail.insert(origin: "admin", meta: %{}, prefix: MultiTenantHelper.tenant())

    person_count =
      from(person in Person, select: count(person.id))
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.all()
    version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.all()
    regular_version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> Repo.all()

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    first_person =
      first(Person, :id)
      |> preload(:company)
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.one()

    assert person_count == [1]
    assert version_count == [1]
    assert regular_version_count == [0]

    assert Map.drop(person, [:company]) == %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      visit_count: nil,
      birthdate: nil,
      company_id: company.id
    }

    assert Map.drop(version, [:id]) == %{
      event: "insert",
      item_type: "Person",
      item_id: first_person.id,
      item_changes: Map.drop(result[:model], [:__meta__, :__struct__, :company]),
      origin: "admin",
      originator_id: nil,
      meta: %{}
    }
  end

  test "[multi tenant] updating a person creates a person version with correct attributes" do
    first_person =
      first(Person, :id)
      |> preload(:company)
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.one()

    target_company =
      from(c in Company, where: c.name == "Another Company Corp.", limit: 1)
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.one()

    {:ok, result} =
      first_person
      |> Person.changeset(%{
        first_name: "Isaac",
        visit_count: 10,
        birthdate: ~D[1992-04-01],
        company_id: target_company.id
      })
      |> MultiTenantHelper.add_prefix_to_changeset()
      |> PaperTrail.update([origin: "user:1", meta: %{linkname: "izelnakri"},
        prefix: MultiTenantHelper.tenant()])

    person_count =
      from(person in Person, select: count(person.id))
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.all()
    version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.all()
    regular_version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> Repo.all()

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert person_count == [1]
    assert version_count == [2]
    assert regular_version_count == [0]

    assert Map.drop(person, [:company]) == %{
      company_id: target_company.id,
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01], #  this is the only problem
      last_name: "Nakri",
      gender: true
    }

    assert Map.drop(version, [:id]) == %{
      event: "update",
      item_type: "Person",
      item_id: first_person.id,
      item_changes: %{
        first_name: "Isaac",
        visit_count: 10,
        birthdate: ~D[1992-04-01],
        company_id: target_company.id
      },
      origin: "user:1",
      originator_id: nil,
      meta: %{
        linkname: "izelnakri"
      }
    }
  end

  test "[multi tenant] deleting a person creates a person version with correct attributes" do
    person =
      first(Person, :id)
      |> preload(:company)
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.one()

    {:ok, result} =
      person
      |> PaperTrail.delete(prefix: MultiTenantHelper.tenant())

    person_count =
      from(person in Person, select: count(person.id))
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.all()
    version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> MultiTenantHelper.add_prefix_to_query()
      |> Repo.all()
    regular_version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> Repo.all()

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert person_count == [0]
    assert version_count == [3]
    assert regular_version_count == [0]

    assert Map.drop(version, [:id]) == %{
      event: "delete",
      item_type: "Person",
      item_id: person.id,
      item_changes: %{
        id: person.id,
        inserted_at: person.inserted_at,
        updated_at: person.updated_at,
        first_name: "Isaac",
        last_name: "Nakri",
        gender: true,
        visit_count: 10,
        birthdate: ~D[1992-04-01],
        company_id: person.company.id
      },
      origin: nil,
      originator_id: nil,
      meta: nil
    }
  end
end
