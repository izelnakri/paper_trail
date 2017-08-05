defmodule MultiTenantCompanyTest do
  use ExUnit.Case
  import Ecto.Query

  setup_all do
    MultiTenantHelper.setup_tenant(Repo)
    :ok
  end

  test "[multi tenant] creating a company creates a company version with correct attributes" do
    {:ok, result} =
      %{name: "Acme LLC", is_active: true, city: "Greenwich", people: []}
      |> new_company()
      |> PaperTrail.insert(origin: "test", prefix: MultiTenantHelper.tenant())

    company_count = company_count() |> Repo.all()
    version_count = version_count() |> Repo.all()
    first_company = first_company() |> Repo.one()

    company = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
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
      event: "insert",
      item_type: "Company",
      item_id: first_company.id,
      item_changes: Map.drop(result[:model], [:__meta__, :__struct__, :people]),
      origin: "test",
      originator_id: nil,
      meta: nil
    }
  end

  test "[multi tenant] updating a company creates a company version with correct item_changes" do
    first_company = first_company() |> Repo.one()

    {:ok, result} =
      update_company(first_company, %{
        city: "Hong Kong",
        website: "http://www.acme.com",
        facebook: "acme.llc"
      }) |> PaperTrail.update(prefix: MultiTenantHelper.tenant())

    company_count = company_count() |> Repo.all()
    version_count = version_count() |> Repo.all()

    company = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
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
      item_id: first_company.id,
      item_changes: %{city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"},
      origin: nil,
      originator_id: nil,
      meta: nil
    }
  end

  test "[multi tenant] deleting a company creates a company version with correct attributes" do
    company = first_company() |> Repo.one()

    {:ok, result} =
      company
      |> PaperTrail.delete(prefix: MultiTenantHelper.tenant())

    company_count = company_count() |> Repo.all()
    version_count = version_count() |> Repo.all()

    company_ref = result[:model] |> Map.drop([:__meta__, :__struct__, :inserted_at, :updated_at, :id])
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
      event: "delete",
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
      origin: nil,
      originator_id: nil,
      meta: nil
    }
  end

  # Company related functions
  def company_count() do
    (from company in Company, select: count(company.id))
    |> MultiTenantHelper.add_prefix_to_query()
  end
  def first_company() do
    (first(Company, :id)
    |> preload(:people))
    |> MultiTenantHelper.add_prefix_to_query()
  end
  def new_company(attrs) do
    Company.changeset(%Company{}, attrs)
    |> MultiTenantHelper.add_prefix_to_changeset()
  end
  def update_company(company, attrs) do
    Company.changeset(company, attrs)
    |> MultiTenantHelper.add_prefix_to_changeset()
  end

  # Version related functions
  def version_count() do
    (from version in PaperTrail.Version, select: count(version.id))
    |> MultiTenantHelper.add_prefix_to_query()
  end
end
