defmodule PaperTrailStrictModeTest do
  use ExUnit.Case

  import Ecto.Query

  alias PaperTrail.Version
  alias StrictCompany, as: Company
  alias StrictPerson, as: Person

  @repo PaperTrail.RepoClient.repo

  doctest PaperTrail

  setup_all do
    Application.put_env(:paper_trail, :strict_mode, true)
    :ok
  end

  setup do
    @repo.delete_all(Person)
    @repo.delete_all(Company)
    @repo.delete_all(Version)
    on_exit fn ->
      @repo.delete_all(Person)
      @repo.delete_all(Company)
      @repo.delete_all(Version)
    end
    :ok
  end

  test "creating a company creates a company version with correct attributes" do
    {:ok, result} = create_company_with_version()

    company_count = Company.count()
    version_count = Version.count()

    company = result[:model] |> serialize()
    version = result[:version] |> serialize()

    assert company_count == [1]
    assert version_count == [1]
    assert Map.drop(company, [:id, :inserted_at, :updated_at]) == %{
      name: "Acme LLC",
      is_active: true,
      city: "Greenwich",
      website: nil,
      address: nil,
      facebook: nil,
      twitter: nil,
      founded_in: nil,
      first_version_id: version.id,
      current_version_id: version.id
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "insert",
      item_type: "StrictCompany",
      item_id: company.id,
      item_changes: company,
      sourced_by: nil,
      meta: nil
    }
  end

  test "updating a company creates a company version with correct item_changes" do
    {:ok, insert_company_result} = create_company_with_version()
    {:ok, result} = update_company_with_version(insert_company_result[:model])

    company_count = Company.count()
    version_count = Version.count()

    company = result[:model] |> serialize
    version = result[:version] |> serialize

    assert company_count == [1]
    assert version_count == [2]
    assert Map.drop(company, [:id, :inserted_at, :updated_at]) == %{
      name: "Acme LLC",
      is_active: true,
      city: "Hong Kong",
      website: "http://www.acme.com",
      address: nil,
      facebook: "acme.llc",
      twitter: nil,
      founded_in: nil,
      first_version_id: insert_company_result[:version].id,
      current_version_id: version.id
    }
    # IMPORTANT: current_version also changes?
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "update",
      item_type: "StrictCompany",
      item_id: company.id,
      item_changes: %{city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"},
      sourced_by: nil,
      meta: nil
    }
  end

  test "deleting a company creates a company version with correct attributes" do
    {:ok, insert_company_result} = create_company_with_version()
    {:ok, update_company_result} = update_company_with_version(insert_company_result[:model])
    {:ok, result} = PaperTrail.delete(update_company_result[:model])

    company_count = Company.count()
    version_count = Version.count()

    old_company = result[:model] |> serialize()
    version = result[:version] |> serialize()

    assert company_count == [0]
    assert version_count == [3]
    assert Map.drop(old_company, [:id, :inserted_at, :updated_at]) == %{
      name: "Acme LLC",
      is_active: true,
      city: "Hong Kong",
      website: "http://www.acme.com",
      address: nil,
      facebook: "acme.llc",
      twitter: nil,
      founded_in: nil,
      first_version_id: insert_company_result[:version].id,
      current_version_id: update_company_result[:version].id
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "delete",
      item_type: "StrictCompany",
      item_id: old_company.id,
      item_changes: %{
        id: old_company.id,
        inserted_at: old_company.inserted_at,
        updated_at: old_company.updated_at,
        name: "Acme LLC",
        is_active: true,
        website: "http://www.acme.com",
        city: "Hong Kong",
        address: nil,
        facebook: "acme.llc",
        twitter: nil,
        founded_in: nil,
        first_version_id: insert_company_result[:version].id,
        current_version_id: update_company_result[:version].id
      },
      sourced_by: nil,
      meta: nil
    }
  end

  test "creating a person with meta tag creates a person version with correct attributes" do
    create_company_with_version(%{name: "Acme LLC", website: "http://www.acme.com"})
    {:ok, insert_company_result} = create_company_with_version(%{
      name: "Another Company Corp.",
      is_active: true,
      address: "Sesame street 100/3, 101010"
    })
    {:ok, insert_person_result} = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: insert_company_result[:model].id
    }) |> PaperTrail.insert(sourced_by: "admin")

    person_count = Person.count()
    version_count = Version.count()

    person = insert_person_result[:model] |> serialize
    version = insert_person_result[:version] |> serialize

    assert person_count == [1]
    assert version_count == [3]
    assert Map.drop(person, [:id, :inserted_at, :updated_at]) == %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      visit_count: nil,
      birthdate: nil,
      company_id: insert_company_result[:model].id,
      first_version_id: insert_person_result[:version].id,
      current_version_id: insert_person_result[:version].id
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "insert",
      item_type: "StrictPerson",
      item_id: person.id,
      item_changes: person,
      sourced_by: "admin",
      meta: nil
    }
  end

  test "updating a person creates a person version with correct attributes" do
    create_company_with_version(%{name: "Acme LLC", website: "http://www.acme.com"})
    {:ok, target_company_insertion} = create_company_with_version(%{
      name: "Another Company Corp.", is_active: true, address: "Sesame street 100/3, 101010"
    })
    {:ok, insert_person_result} = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: target_company_insertion[:model].id
    }) |> PaperTrail.insert(sourced_by: "admin")
    {:ok, result} = Person.changeset(insert_person_result[:model], %{
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01]
    }) |> PaperTrail.update(sourced_by: "scraper", meta: %{linkname: "izelnakri"})

    person_count = Person.count()
    version_count = Version.count()

    person = result[:model] |> serialize
    version = result[:version] |> serialize

    assert person_count == [1]
    assert version_count == [4]
    assert Map.drop(person, [:id, :inserted_at, :updated_at]) == %{
      company_id: target_company_insertion[:model].id,
      first_name: "Isaac",
      visit_count: 10,
      birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1), #  this is the only problem
      last_name: "Nakri",
      gender: true,
      first_version_id: insert_person_result[:version].id,
      current_version_id: version.id
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "update",
      item_type: "StrictPerson",
      item_id: person.id,
      item_changes: %{
        first_name: "Isaac",
        visit_count: 10,
        birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1)
      },
      sourced_by: "scraper",
      meta: %{
        linkname: "izelnakri"
      }
    }
  end

  test "deleting a person creates a person version with correct attributes" do
    create_company_with_version(%{name: "Acme LLC", website: "http://www.acme.com"})
    {:ok, target_company_insertion} = create_company_with_version(%{
      name: "Another Company Corp.", is_active: true, address: "Sesame street 100/3, 101010"
    })
    {:ok, insert_person_result} = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: target_company_insertion[:model].id
    }) |> PaperTrail.insert(sourced_by: "admin")
    {:ok, update_person_result} = Person.changeset(insert_person_result[:model], %{
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01]
    }) |> PaperTrail.update(sourced_by: "scraper", meta: %{linkname: "izelnakri"})
    {:ok, result} = PaperTrail.delete(update_person_result[:model])

    person_count = Person.count()
    version_count = Version.count()

    old_person = result[:model] |> serialize
    version = result[:version] |> serialize

    assert person_count == [0]
    assert version_count == [5]
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "delete",
      item_type: "StrictPerson",
      item_id: old_person.id,
      item_changes: %{
        id: old_person.id,
        inserted_at: old_person.inserted_at,
        updated_at: old_person.updated_at,
        first_name: "Isaac",
        last_name: "Nakri",
        gender: true,
        visit_count: 10,
        birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1),
        company_id: target_company_insertion[:model].id,
        first_version_id: insert_person_result[:version].id,
        current_version_id: update_person_result[:version].id
      },
      sourced_by: nil,
      meta: nil
    }
  end

  defp create_company_with_version(params \\ %{
    name: "Acme LLC", is_active: true, city: "Greenwich"
  }, options \\ nil) do
    Company.changeset(%Company{}, params) |> PaperTrail.insert(options)
  end

  defp update_company_with_version(company, params \\ %{
    city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"
  }, options \\ nil) do
    Company.changeset(company, params) |> PaperTrail.update(options)
  end

  defp serialize(model) do
    relationships = model.__struct__.__schema__(:associations)
    Map.drop(model, [:__struct__, :__meta__] ++ relationships)
  end
end
