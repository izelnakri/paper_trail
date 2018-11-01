defmodule SimpleCompany do
  use Ecto.Schema

  alias PaperTrailTest.MultiTenantHelper, as: MultiTenant

  import Ecto.Changeset
  import Ecto.Query

  schema "simple_companies" do
    field(:name, :string)
    field(:is_active, :boolean)
    field(:website, :string)
    field(:city, :string)
    field(:address, :string)
    field(:facebook, :string)
    field(:twitter, :string)
    field(:founded_in, :string)

    has_many(:people, SimplePerson, foreign_key: :company_id)

    timestamps()
  end

  @optional_fields ~w(name is_active website city address facebook twitter founded_in)a

  def paper_trail_skip, do: [:twitter]

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @optional_fields)
    |> validate_required([:name])
    |> no_assoc_constraint(:people)
  end

  def count do
    from(record in __MODULE__, select: count(record.id)) |> PaperTrail.RepoClient.repo().one
  end

  def count(:multitenant) do
    from(record in __MODULE__, select: count(record.id))
    |> MultiTenant.add_prefix_to_query()
    |> PaperTrail.RepoClient.repo().one
  end
end

defmodule SimplePerson do
  use Ecto.Schema

  alias PaperTrailTest.MultiTenantHelper, as: MultiTenant

  import Ecto.Changeset
  import Ecto.Query

  schema "simple_people" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:visit_count, :integer)
    field(:gender, :boolean)
    field(:birthdate, :date)

    belongs_to(:company, SimpleCompany, foreign_key: :company_id)

    timestamps()
  end

  @optional_fields ~w(first_name last_name visit_count gender birthdate company_id)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @optional_fields)
    |> foreign_key_constraint(:company_id)
  end

  def count do
    from(record in __MODULE__, select: count(record.id)) |> PaperTrail.RepoClient.repo().one
  end

  def count(:multitenant) do
    from(record in __MODULE__, select: count(record.id))
    |> MultiTenant.add_prefix_to_query()
    |> PaperTrail.RepoClient.repo().one
  end
end
