defmodule MultiTenantPersonTest do
  use ExUnit.Case
  import Ecto.Query

  setup_all do
    MultiTenantHelper.setup_tenant(Repo)

    %{name: "Acme LLC", website: "http://www.acme.com"}
    |> new_company()
    |> Repo.insert()

    %{name: "Another Company Corp.", is_active: true, address: "Sesame street 100/3, 101010"}
    |> new_company()
    |> Repo.insert()

    :ok
  end

  test "[multi tenant] creating a person with meta tag creates a person version with correct attributes" do
    company = first_company() |> Repo.one()

    {:ok, result} =
      %{first_name: "Izel", last_name: "Nakri", gender: true, company_id: company.id}
      |> new_person()
      |> PaperTrail.insert(origin: "admin", meta: %{}, prefix: MultiTenantHelper.tenant())

    person_count = person_count() |> Repo.all()
    version_count = version_count() |> Repo.all()

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    first_person = first_person() |> Repo.one()

    assert person_count == [1]
    assert version_count == [1]

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
    first_person = first_person() |> Repo.one()

    target_company =
      [name: "Another Company Corp.", limit: 1]
      |> filter_company()
      |> Repo.one()

    {:ok, result} =
      update_person(first_person, %{
        first_name: "Isaac",
        visit_count: 10,
        birthdate: ~D[1992-04-01],
        company_id: target_company.id
      })
      |> PaperTrail.update([origin: "user:1", meta: %{linkname: "izelnakri"},
        prefix: MultiTenantHelper.tenant()])

    person_count = person_count() |> Repo.all()
    version_count = version_count() |> Repo.all()

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert person_count == [1]
    assert version_count == [2]

    assert Map.drop(person, [:company]) == %{
      company_id: target_company.id,
      first_name: "Isaac",
      visit_count: 10,
      birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1), #  this is the only problem
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
        birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1),
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
    person = first_person() |> Repo.one()

    {:ok, result} =
      person
      |> PaperTrail.delete(prefix: MultiTenantHelper.tenant())

    person_count = person_count() |> Repo.all()
    version_count = version_count() |> Repo.all()

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert person_count == [0]
    assert version_count == [3]

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
        birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1),
        company_id: person.company.id
      },
      origin: nil,
      originator_id: nil,
      meta: nil
    }
  end

  # Person related functions
  def person_count() do
    (from person in Person, select: count(person.id))
    |> MultiTenantHelper.add_prefix_to_query()
  end
  def first_person() do
    (first(Person, :id) |> preload(:company))
    |> MultiTenantHelper.add_prefix_to_query()
  end
  def new_person(attrs) do
    Person.changeset(%Person{}, attrs)
    |> MultiTenantHelper.add_prefix_to_changeset()
  end
  def update_person(person, attrs) do
    Person.changeset(person, attrs)
    |> MultiTenantHelper.add_prefix_to_changeset()
  end

  # Company related functions
  def first_company() do
    (first(Company, :id)
    |> preload(:people))
    |> MultiTenantHelper.add_prefix_to_query()
  end
  def new_company(attrs) do
    Company.changeset(%Company{}, attrs)
    |> MultiTenantHelper.add_prefix_to_changeset()
  end
  def filter_company(opts) do
    (from c in Company, where: c.name == ^opts[:name], limit: ^opts[:limit])
    |> MultiTenantHelper.add_prefix_to_query()
  end

  # Version related functions
  def version_count() do
    (from version in PaperTrail.Version, select: count(version.id))
    |> MultiTenantHelper.add_prefix_to_query()
  end
end
