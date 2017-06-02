defmodule PaperTrail.AssociationUtils do
  @client PaperTrail.RepoClient
  @repo @client.repo()

  def get_all_children(%Ecto.Changeset{} = changeset) do
    get_all_children(changeset.data)
  end
  def get_all_children(struct) do
    struct.__struct__
    |> get_child_assocs()
    |> Enum.flat_map(fn {action, field} ->
      struct
      |> Ecto.assoc(field)
      |> @repo.all()
      |> Enum.map(&{action, find_parent(&1.__struct__, struct.__struct__), &1})
    end)
    |> Enum.flat_map(fn
      {:delete_all, _field, struct} = entry ->
        # when this struct is deleted, we need to cascade the effect down to its
        # children
        [entry | get_all_children(struct)]
      {:nilify_all, _field, _struct} = entry ->
        # when the association field on this struct is set to nil, we don't need
        # to cascade further down
        [entry]
    end)
  end

  def get_child_assocs(schema) do
    :associations
    |> schema.__schema__()
    |> Enum.map(&schema.__schema__(:association, &1))
    |> Enum.filter(&(Map.get(&1, :relationship) == :child))
    |> Enum.filter(&(Map.get(&1, :on_delete) in [:delete_all, :nilify_all]))
    |> Enum.map(&{&1.on_delete, &1.field})
  end

  def find_parent(from, to) do
    [assoc] = :associations
    |> from.__schema__()
    |> Enum.map(&from.__schema__(:association, &1))
    |> Enum.filter(&(Map.get(&1, :relationship) == :parent))
    |> Enum.filter(&(Map.get(&1, :related) == to))

    assoc.owner_key
  end
end
