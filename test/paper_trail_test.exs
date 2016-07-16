defmodule PaperTrailTest do
  use ExUnit.Case
  import Ecto.Query

  doctest PaperTrail

  setup_all do
    Repo.delete_all(Person)
    Repo.delete_all(Company)
    Repo.delete_all(PaperTrail.Version)
    :ok
  end

  test "creating a company creates a company version with correct attributes" do
    new_company = Company.changeset(%Company{}, %{
      name: "Acme LLC", is_active: true, city: "Greenwich", people: []
    })

    {:ok, result} = PaperTrail.insert(new_company)

    company_count = Repo.all(
      from company in Company,
      select: count(company.id)
    )

    company = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = Repo.all(
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
      item_id: Repo.one(first(Company, :id)).id,
      item_changes: Map.drop(result[:model], [:__meta__, :__struct__, :people]),
      meta: nil
    }
  end

  test "updating a company creates a company version with correct item_changes" do
    old_company = first(Company, :id) |> preload(:people) |> Repo.one
    new_company = Company.changeset(old_company, %{
      city: "Hong Kong",
      website: "http://www.acme.com",
      facebook: "acme.llc"
    })

    {:ok, result} = PaperTrail.update(new_company)

    company_count = Repo.all(
      from company in Company,
      select: count(company.id)
    )

    company = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = Repo.all(
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
      item_id: Repo.one(first(Company, :id)).id,
      item_changes: %{city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"},
      meta: nil
    }
  end

  test "deleting a company creates a company version with correct attributes" do
    company = first(Company, :id) |> preload(:people) |> Repo.one

    {:ok, result} = PaperTrail.delete(company)

    company_count = Repo.all(
      from company in Company,
      select: count(company.id)
    )

    company_ref = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])

    version_count = Repo.all(
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

end
