defmodule CompanyTest do
  use ExUnit.Case
  import Ecto.Query
  alias Example.Repo

  doctest Company

  test "creating a company creates a company version with correct attributes" do
    new_company = Company.changeset(%Company{}, %{
      name: "Acme LLC", is_active: true, city: "Greenwich"
    })

    persisted_company = PaperTrail.insert(new_company)

    persisted_company |> inspect |> IO.puts

    company_count = Repo.all(
      from company in Company,
      select: count(company.id)
    )

    assert company_count == 1
    # assert Map.
    # company |> inspect |> IO.puts

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
