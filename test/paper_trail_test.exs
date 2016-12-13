defmodule PaperTrailTest do
  use ExUnit.Case
  import Ecto.Query

  @repo PaperTrail.RepoClient.repo

  doctest PaperTrail

  setup_all do
    @repo.delete_all(Person)
    @repo.delete_all(Company)
    @repo.delete_all(PaperTrail.Version)
    :ok
  end

  test "creating a company creates a company version with correct attributes" do
    new_company = Company.changeset(%Company{}, %{
      name: "Acme LLC", is_active: true, city: "Greenwich", people: []
    })

    {:ok, result} = PaperTrail.insert(new_company)

    company_count = @repo.all(
      from company in Company,
      select: count(company.id)
    )

    company = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = @repo.all(
      from version in PaperTrail.Version,
      select: count(version.id)
    )

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert company_count == [1]
    assert version_count == [1]

    assert company == %{
      name: "Acme LLC",
      is_active: true,
      city: "Greenwich",
      website: nil,
      address: nil,
      facebook: nil,
      twitter: nil,
      founded_in: nil,
      people: []
    }

    assert Map.drop(version, [:id]) == %{
      event: "create",
      item_type: "Company",
      item_id: @repo.one(first(Company, :id)).id,
      item_changes: Map.drop(result[:model], [:__meta__, :__struct__, :people]),
      meta: nil
    }
  end

  test "updating a company creates a company version with correct item_changes" do
    old_company = first(Company, :id) |> preload(:people) |> @repo.one
    new_company = Company.changeset(old_company, %{
      city: "Hong Kong",
      website: "http://www.acme.com",
      facebook: "acme.llc"
    })

    {:ok, result} = PaperTrail.update(new_company)

    company_count = @repo.all(
      from company in Company,
      select: count(company.id)
    )

    company = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = @repo.all(
      from version in PaperTrail.Version,
      select: count(version.id)
    )

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert company_count == [1]
    assert version_count == [2]

    assert company == %{
      name: "Acme LLC",
      is_active: true,
      city: "Hong Kong",
      website: "http://www.acme.com",
      address: nil,
      facebook: "acme.llc",
      twitter: nil,
      founded_in: nil,
      people: []
    }

    assert Map.drop(version, [:id]) == %{
      event: "update",
      item_type: "Company",
      item_id: @repo.one(first(Company, :id)).id,
      item_changes: %{city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"},
      meta: nil
    }
  end

  test "deleting a company creates a company version with correct attributes" do
    company = first(Company, :id) |> preload(:people) |> @repo.one

    {:ok, result} = PaperTrail.delete(company)

    company_count = @repo.all(
      from company in Company,
      select: count(company.id)
    )

    company_ref = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = @repo.all(
      from version in PaperTrail.Version,
      select: count(version.id)
    )

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert company_count == [0]
    assert version_count == [3]

    assert company_ref == %{
      name: "Acme LLC",
      is_active: true,
      city: "Hong Kong",
      website: "http://www.acme.com",
      address: nil,
      facebook: "acme.llc",
      twitter: nil,
      founded_in: nil,
      people: []
    }

    assert Map.drop(version, [:id]) == %{
      event: "destroy",
      item_type: "Company",
      item_id: company.id,
      item_changes: %{
        id: company.id,
        inserted_at: company.inserted_at,
        updated_at: company.updated_at,
        name: "Acme LLC",
        is_active: true,
        website: "http://www.acme.com",
        city: "Hong Kong",
        address: nil,
        facebook: "acme.llc",
        twitter: nil,
        founded_in: nil
      },
      meta: nil
    }
  end


  test "creating a person with meta tag creates a person version with correct attributes" do
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

    new_person = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: company.id
    })

    {:ok, result} = PaperTrail.insert(new_person, %{originator: "admin"}) # add link name later on

    person_count = @repo.all(
      from person in Person,
      select: count(person.id)
    )

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = @repo.all(
      from version in PaperTrail.Version,
      select: count(version.id)
    )

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert person_count == [1]
    assert version_count == [6]

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
      item_id: @repo.one(first(Person, :id)).id,
      item_changes: Map.drop(result[:model], [:__meta__, :__struct__, :company]),
      meta: %{originator: "admin"}
    }
  end

  test "updating a person creates a person version with correct attributes" do
    old_person = first(Person, :id) |> @repo.one

    target_company = @repo.one(
      from c in Company,
      where: c.name == "Another Company Corp.",
      limit: 1
    )

    new_person = Person.changeset(old_person, %{
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01],
      company_id: target_company.id
    })

    {:ok, result} = PaperTrail.update(new_person, %{
      originator: "user:1",
      linkname: "izelnakri"
    })

    person_count = @repo.all(
      from person in Person,
      select: count(person.id)
    )

    person = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = @repo.all(
      from version in PaperTrail.Version,
      select: count(version.id)
    )

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert person_count == [1]
    assert version_count == [7]

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
      item_id: @repo.one(first(Person, :id)).id,
      item_changes: %{
        first_name: "Isaac",
        visit_count: 10,
        birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1),
        company_id: target_company.id
      },
      meta: %{
        originator: "user:1",
        linkname: "izelnakri"
      }
    }
  end

  test "deleting a person creates a person version with correct attributes" do
    person = first(Person, :id) |> preload(:company) |> @repo.one

    {:ok, result} = PaperTrail.delete(person)

    person_count = @repo.all(
      from person in Person,
      select: count(person.id)
    )

    version_count = @repo.all(
      from version in PaperTrail.Version,
      select: count(version.id)
    )

    version = result[:version] |> Map.drop([:__meta__, :__struct__, :inserted_at])

    assert person_count == [0]
    assert version_count == [8]

    assert Map.drop(version, [:id]) == %{
      event: "destroy",
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
      meta: nil
    }
  end
end
