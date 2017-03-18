defmodule PaperTrailTest.StrictModeBangFunctions do
  use ExUnit.Case

  import Ecto.Query

  alias PaperTrail.Version
  alias StrictCompany, as: Company
  alias StrictPerson, as: Person

  @repo PaperTrail.RepoClient.repo
  @create_company_params %{name: "Acme LLC", is_active: true, city: "Greenwich"}
  @update_company_params %{city: "Hong Kong", website: "http://www.acme.com", facebook: "acme.llc"}

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


end
