defmodule PersonTest do
  use ExUnit.Case
  import Ecto.Query

  doctest Person

  setup_all do
    Repo.delete_all(Person)
    Repo.delete_all(Company)
    Repo.delete_all(PaperTrail.Version)

    Company.changeset(%Company{}, %{
      name: "Acme LLC",
      website: "http://www.acme.com"
    }) |> Repo.insert

    Company.changeset(%Company{}, %{
      name: "Another Company Corp.",
      is_active: true,
      address: "Sesame street 100/3, 101010"
    }) |> Repo.insert

    :ok
  end

  test "creating a person with meta tag creates a person version with correct attributes" do
    company = first(Company, :id) |> Repo.one

    new_person = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: company.id
    })

    {:ok, result} = PaperTrail.insert(new_person, %{originator: "admin"}) # add link name later on

    person_count = Repo.all(
      from person in Person,
      select: count(person.id)
    )

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = Repo.all(
      from version in PaperTrail.Version,
      select: count(version.id)
    )

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

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
      event: "create",
      item_type: "Person",
      item_id: Repo.one(first(Person, :id)).id,
      item_changes: Map.drop(result[:model], [:__meta__, :__struct__, :company]),
      meta: %{originator: "admin"}
    }
  end

  test "updating a person creates a person version with correct attributes" do

  end

  test "deleting a person creates a person version with correct attributes" do

  end
end
