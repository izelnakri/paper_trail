defmodule QueryHelper do
  import Ecto.Query

  # Company related query functions
  def company_count(), do: (from company in Company, select: count(company.id))
  def company_count(:multitenant), do: company_count() |> MultiTenantHelper.add_prefix_to_query()

  def first_company(), do: (first(Company, :id) |> preload(:people))
  def first_company(:multitenant), do: first_company() |> MultiTenantHelper.add_prefix_to_query()

  def filter_company(opts), do: (from c in Company, where: c.name == ^opts[:name], limit: ^opts[:limit])
  def filter_company(opts, :multitenant), do: filter_company(opts) |> MultiTenantHelper.add_prefix_to_query()

  # Person related query functions
  def person_count(), do: (from person in Person, select: count(person.id))
  def person_count(:multitenant), do: person_count() |> MultiTenantHelper.add_prefix_to_query()

  def first_person(), do: (first(Person, :id) |> preload(:company))
  def first_person(:multitenant), do: first_person() |> MultiTenantHelper.add_prefix_to_query()

  # Version related query functions
  def version_count(), do: (from version in PaperTrail.Version, select: count(version.id))
  def version_count(:multitenant), do: version_count() |> MultiTenantHelper.add_prefix_to_query()
end
