defmodule PaperTrailTest.SimpleModeBangFunctions do
  use ExUnit.Case

  import Ecto.Query

  alias PaperTrail.Version
  alias SimpleCompany, as: Company
  alias SimplePerson, as: Person

  @repo PaperTrail.RepoClient.repo
  @create_company_params %{name: "Acme LLC", is_active: true, city: "Greenwich"}
  @update_company_params %{city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"}

  doctest PaperTrail

  setup_all do
    Application.put_env(:paper_trail, :strict_mode, false)
    Code.eval_file("lib/paper_trail.ex")
    Code.eval_file("lib/version.ex")
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
    user = create_user()
    company = create_company_with_version(@create_company_params, originator: user)

    company_count = Company.count()
    version_count = Version.count()

    version = PaperTrail.get_version(company) |> serialize

    assert company_count == 1
    assert version_count == 1
    assert company |> serialize |> Map.drop([:id, :inserted_at, :updated_at]) == %{
      name: "Acme LLC",
      is_active: true,
      city: "Greenwich",
      website: nil,
      address: nil,
      facebook: nil,
      twitter: nil,
      founded_in: nil
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "insert",
      item_type: "SimpleCompany",
      item_id: company.id,
      item_changes: company |> serialize |> convert_to_string_map,
      originator_id: user.id,
      origin: nil,
      meta: nil
    }
    assert company == first(Company, :id) |> @repo.one
  end

  test "PaperTrail.insert!/2 with an error raises Ecto.InvalidChangesetError" do
    assert_raise(Ecto.InvalidChangesetError, fn ->
      create_company_with_version(%{name: nil, is_active: true, city: "Greenwich"})
    end)
  end

  test "updating a company with originator creates a correct company version" do
    user = create_user()
    inserted_company = create_company_with_version()
    updated_company = update_company_with_version(
      inserted_company, @update_company_params, user: user
    )

    company_count = Company.count()
    version_count = Version.count()

    company = updated_company |> serialize
    version = PaperTrail.get_version(updated_company) |> serialize

    assert company_count == 1
    assert version_count == 2
    assert Map.drop(company, [:id, :inserted_at, :updated_at]) == %{
      name: "Acme LLC",
      is_active: true,
      city: "Hong Kong",
      website: "http://www.acme.com",
      address: nil,
      facebook: "acme.llc",
      twitter: nil,
      founded_in: nil
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "update",
      item_type: "SimpleCompany",
      item_id: company.id,
      item_changes: convert_to_string_map(%{
        city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"
      }),
      originator_id: user.id,
      origin: nil,
      meta: nil
    }
    assert company == first(Company, :id) |> @repo.one |> serialize
  end

  test "updating a company with originator[user] creates a correct company version" do
    user = create_user()
    inserted_company = create_company_with_version()
    updated_company = update_company_with_version(
      inserted_company, @update_company_params, user: user
    )

    company_count = Company.count()
    version_count = Version.count()

    company = updated_company |> serialize
    version =  PaperTrail.get_version(updated_company) |> serialize

    assert company_count == 1
    assert version_count == 2
    assert Map.drop(company, [:id, :inserted_at, :updated_at]) == %{
      name: "Acme LLC",
      is_active: true,
      city: "Hong Kong",
      website: "http://www.acme.com",
      address: nil,
      facebook: "acme.llc",
      twitter: nil,
      founded_in: nil
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "update",
      item_type: "SimpleCompany",
      item_id: company.id,
      item_changes: convert_to_string_map(%{
        city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"
      }),
      originator_id: user.id,
      origin: nil,
      meta: nil
    }
    assert company == first(Company, :id) |> @repo.one |> serialize
  end

  test "PaperTrail.update!/2 with an error raises Ecto.InvalidChangesetError" do
    assert_raise(Ecto.InvalidChangesetError, fn ->
      inserted_company = create_company_with_version()
      update_company_with_version(inserted_company, %{
        name: nil, city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"
      })
    end)
  end

  test "deleting a company creates a company version with correct attributes" do
    user = create_user()
    inserted_company = create_company_with_version()
    updated_company = update_company_with_version(inserted_company)
    company_before_deletion = first(Company, :id) |> @repo.one |> serialize
    deleted_company = PaperTrail.delete!(updated_company, originator: user)

    company_count = Company.count()
    version_count = Version.count()

    company = deleted_company |> serialize
    version = PaperTrail.get_version(deleted_company) |> serialize

    assert company_count == 0
    assert version_count == 3
    assert Map.drop(company, [:id, :inserted_at, :updated_at]) == %{
      name: "Acme LLC",
      is_active: true,
      city: "Hong Kong",
      website: "http://www.acme.com",
      address: nil,
      facebook: "acme.llc",
      twitter: nil,
      founded_in: nil
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "delete",
      item_type: "SimpleCompany",
      item_id: company.id,
      item_changes: convert_to_string_map(%{
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
      }),
      originator_id: user.id,
      origin: nil,
      meta: nil
    }
    assert company == company_before_deletion
  end

  test "PaperTrail.delete!/2 with an error raises Ecto.InvalidChangesetError" do
    assert_raise(Ecto.InvalidChangesetError, fn ->
      inserted_company = create_company_with_version()
      Person.changeset(%Person{}, %{
        first_name: "Izel",
        last_name: "Nakri",
        gender: true,
        company_id: inserted_company.id
      }) |> PaperTrail.insert!
      inserted_company |> Company.changeset |> PaperTrail.delete!
    end)
  end

  test "creating a person with meta tag creates a person version with correct attributes" do
    create_company_with_version()
    second_company = Company.changeset(%Company{}, %{
      name: "Another Company Corp.",
      is_active: true,
      address: "Sesame street 100/3, 101010"
    }) |> PaperTrail.insert!
    inserted_person = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: second_company.id
    }) |> PaperTrail.insert!(origin: "admin", meta: %{linkname: "izelnakri"})

    person_count = Person.count()
    company_count = Company.count()
    version_count = Version.count()

    person = inserted_person |> serialize
    version = PaperTrail.get_version(inserted_person) |> serialize

    assert person_count == 1
    assert company_count == 2
    assert version_count == 3
    assert  Map.drop(person, [:id, :inserted_at, :updated_at]) == %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      visit_count: nil,
      birthdate: nil,
      company_id: second_company.id
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "insert",
      item_type: "SimplePerson",
      item_id: person.id,
      item_changes: convert_to_string_map(person),
      originator_id: nil,
      origin: "admin",
      meta: %{"linkname" => "izelnakri"}
    }
    assert person == first(Person, :id) |> @repo.one |> serialize
  end

  test "updating a person creates a person version with correct attributes" do
    inserted_initial_company = create_company_with_version(%{
      name: "Acme LLC", website: "http://www.acme.com"
    })
    inserted_target_company = create_company_with_version(%{
      name: "Another Company Corp.", is_active: true, address: "Sesame street 100/3, 101010"
    })
    inserted_person = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: inserted_target_company.id
    }) |> PaperTrail.insert!(origin: "admin")
    updated_person = Person.changeset(inserted_person, %{
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01],
      company_id: inserted_initial_company.id
    }) |> PaperTrail.update!(origin: "scraper", meta: %{linkname: "izelnakri"})

    person_count = Person.count()
    company_count = Company.count()
    version_count = Version.count()

    person = updated_person |> serialize
    version = PaperTrail.get_version(updated_person) |> serialize

    assert person_count == 1
    assert company_count == 2
    assert version_count == 4
    assert Map.drop(person, [:id, :inserted_at, :updated_at]) == %{
      company_id: inserted_initial_company.id,
      first_name: "Isaac",
      visit_count: 10,
      birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1),
      last_name: "Nakri",
      gender: true
    }
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "update",
      item_type: "SimplePerson",
      item_id: person.id,
      item_changes: convert_to_string_map(%{
        first_name: "Isaac",
        visit_count: 10,
        birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1),
        company_id: inserted_initial_company.id
      }),
      originator_id: nil,
      origin: "scraper",
      meta: %{"linkname" => "izelnakri"}
    }
    assert person == first(Person, :id) |> @repo.one |> serialize
  end

  test "deleting a person creates a person version with correct attributes" do
    create_company_with_version(%{name: "Acme LLC", website: "http://www.acme.com"})
    inserted_target_company = create_company_with_version(%{
      name: "Another Company Corp.", is_active: true, address: "Sesame street 100/3, 101010"
    })
    inserted_person = Person.changeset(%Person{}, %{
      first_name: "Izel",
      last_name: "Nakri",
      gender: true,
      company_id: inserted_target_company.id
    }) |> PaperTrail.insert!(origin: "admin")
    updated_person = Person.changeset(inserted_person, %{
      first_name: "Isaac",
      visit_count: 10,
      birthdate: ~D[1992-04-01],
      company_id: inserted_target_company.id
    }) |> PaperTrail.update!(origin: "scraper", meta: %{linkname: "izelnakri"})
    person_before_deletion = first(Person, :id) |> @repo.one |> serialize
    deleted_person = PaperTrail.delete!(
      updated_person, origin: "admin", meta: %{linkname: "izelnakri"}
    )

    person_count = Person.count()
    company_count = Company.count()
    version_count = Version.count()

    old_person = updated_person |> serialize
    version = PaperTrail.get_version(deleted_person) |> serialize

    assert person_count == 0
    assert company_count == 2
    assert version_count == 5
    assert Map.drop(version, [:id, :inserted_at]) == %{
      event: "delete",
      item_type: "SimplePerson",
      item_id: old_person.id,
      item_changes: convert_to_string_map(%{
        id: old_person.id,
        inserted_at: old_person.inserted_at,
        updated_at: old_person.updated_at,
        first_name: "Isaac",
        last_name: "Nakri",
        gender: true,
        visit_count: 10,
        birthdate: elem(Ecto.Date.cast(~D[1992-04-01]), 1),
        company_id: inserted_target_company.id
      }),
      originator_id: nil,
      origin: "admin",
      meta: %{"linkname" => "izelnakri"}
    }
    assert old_person == person_before_deletion
  end

  defp create_user do
    User.changeset(%User{}, %{token: "fake-token", username: "izelnakri"}) |> @repo.insert!
  end

  defp create_company_with_version(params \\ @create_company_params, options \\ nil) do
    Company.changeset(%Company{}, params) |> PaperTrail.insert!(options)
  end

  defp update_company_with_version(company, params \\ @update_company_params, options \\ nil) do
    Company.changeset(company, params) |> PaperTrail.update!(options)
  end

  defp serialize(model) do
    relationships = model.__struct__.__schema__(:associations)
    Map.drop(model, [:__struct__, :__meta__] ++ relationships)
  end

  def convert_to_string_map(map) do
    map |> Poison.encode! |> Poison.decode!
  end
end
