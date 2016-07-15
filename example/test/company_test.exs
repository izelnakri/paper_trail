defmodule CompanyTest do
  use ExUnit.Case
  import Ecto.Query

  doctest Company

  setup_all do
    Repo.delete_all(Company)
    Repo.delete_all(PaperTrail.Version)
    :ok
  end

  test "creating a company creates a company version with correct attributes" do
    new_company = Company.changeset(%Company{}, %{
      name: "Acme LLC", is_active: true, city: "Greenwich"
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
      founded_in: nil
    }

    version |> inspect |> IO.puts

    assert Map.drop(version, [:id]) == %{
      event: "create",
      item_type: "Company",
      item_id: Repo.one(first(Company, :id)).id,
      item_changes: Map.drop(result[:model], [:__meta__, :__struct__]),
      meta: nil,
      originator: nil
    }
  end

  test "updating a company creates a company version with correct attributes" do

  end

  test "deleting a company creates a company version with correct attributes" do

  end
end
# field :name, :string
# field :is_active, :boolean
# field :website, :string
# field :city, :string
# field :address, :string
# field :facebook, :string
# field :twitter, :string
# field :founded_in, :string
