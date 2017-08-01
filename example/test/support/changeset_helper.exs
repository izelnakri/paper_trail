defmodule ChangesetHelper do

  # Company related changeset functions
  def new_company(attrs), do: Company.changeset(%Company{}, attrs)
  def new_company(attrs, :multitenant) do
    new_company(attrs) |> MultiTenantHelper.add_prefix_to_changeset()
  end

  def update_company(company, attrs), do: Company.changeset(company, attrs)
  def update_company(company, attrs, :multitenant) do
    update_company(company, attrs) |> MultiTenantHelper.add_prefix_to_changeset()
  end

  # Person related changeset functions
  def new_person(attrs), do: Person.changeset(%Person{}, attrs)
  def new_person(attrs, :multitenant) do
    new_person(attrs) |> MultiTenantHelper.add_prefix_to_changeset()
  end

  def update_person(person, attrs), do: Person.changeset(person, attrs)
  def update_person(person, attrs, :multitenant) do
    update_person(person, attrs) |> MultiTenantHelper.add_prefix_to_changeset()
  end
end
