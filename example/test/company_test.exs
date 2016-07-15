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

    {:ok, persisted_company} = PaperTrail.insert(new_company)

    persisted_company |> inspect |> IO.puts

    company_count = Repo.all(
      from company in Company,
      select: count(company.id)
    )

    assert company_count == [1]
    
    # assert Map.

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
