defmodule PersonTest do
  use ExUnit.Case
  import Ecto.Query

  doctest Person

  setup_all do
    Repo.delete_all(Person)
    Repo.delete_all(Company)
    Repo.delete_all(PaperTrail.Version)

    %Company{}
    |> Company.changeset(%{name: "Acme LLC", website: "http://www.acme.com"})
    |> Repo.insert()

    %Company{}
    |> Company.changeset(%{name: "Another Company Corp.", is_active: true, address: "Sesame street 100/3, 101010"})
    |> Repo.insert()

    :ok
  end

  test "creating a person with meta tag creates a person version with correct attributes" do
    company =
      first(Company, :id)
      |> preload(:people)
      |> Repo.one()

    {:ok, result} =
      %Person{}
      |> Person.changeset(%{first_name: "Izel", last_name: "Nakri", gender: true, company_id: company.id})
      |> PaperTrail.insert(origin: "admin", meta: %{})

    person_count =
      from(person in Person, select: count(person.id))
      |> Repo.all()
    version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> Repo.all()

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    first_person =
      first(Person, :id)
      |> preload(:company)
      |> Repo.one()

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

  test "updating a person creates a person version with correct attributes" do
    first_person =
      first(Person, :id)
      |> preload(:company)
      |> Repo.one()

    target_company =
      from(c in Company, where: c.name == "Another Company Corp.", limit: 1)
      |> Repo.one()

    {:ok, result} =
      first_person
      |> Person.changeset(%{
        first_name: "Isaac",
        visit_count: 10,
        birthdate: ~D[1992-04-01],
        company_id: target_company.id
      }) |> PaperTrail.update(origin: "user:1", meta: %{linkname: "izelnakri"})

    person_count =
      from(person in Person, select: count(person.id))
      |> Repo.all()
    version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> Repo.all()

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert person_count == [1]
    assert version_count == [2]

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

  test "deleting a person creates a person version with correct attributes" do
    person =
      first(Person, :id)
      |> preload(:company)
      |> Repo.one()

    {:ok, result} =
      person
      |> PaperTrail.delete()

    person_count =
      from(person in Person, select: count(person.id))
      |> Repo.all()
    version_count =
      from(version in PaperTrail.Version, select: count(version.id))
      |> Repo.all()

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
        birthdate: ~D[1992-04-01],
        company_id: person.company.id
      },
      origin: nil,
      originator_id: nil,
      meta: nil
    }
  end
end
