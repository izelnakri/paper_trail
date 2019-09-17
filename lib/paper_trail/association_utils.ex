defmodule PaperTrail.AssociationUtils do
  @client PaperTrail.RepoClient
  @repo @client.repo()

  def get_all_children(changeset_or_struct) do
    get_all_children_recursive(changeset_or_struct, [changeset_or_struct])
  end

  defp get_all_children_recursive(%Ecto.Changeset{} = changeset, accumulator) do
    get_all_children_recursive(changeset.data, accumulator)
  end
  defp get_all_children_recursive(struct, accumulator) do
    struct.__struct__
    |> get_child_assocs()
    |> Enum.flat_map(fn {action, field} ->
      struct
      |> Ecto.assoc(field)
      |> @repo.all()
      |> Enum.map(&{action, find_parent(&1.__struct__, struct.__struct__), &1})
    end)
    |> Enum.flat_map(fn
      {:delete_all, _field, child_struct} = entry ->
        # when this struct is deleted, we need to cascade the effect down to its
        # children, but we need to make sure we don't revisit the same struct
        # more than once or we end up in an infinite loop
        accumulator
        |> Enum.member?(child_struct)
        |> case do
          true ->
            []
          false ->
            [entry | get_all_children_recursive(child_struct, [child_struct | accumulator])]
        end
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
    :associations
    |> from.__schema__()
    |> Enum.map(&from.__schema__(:association, &1))
    |> Enum.filter(&(Map.get(&1, :relationship) == :parent))
    |> Enum.filter(&(Map.get(&1, :related) == to))
    |> case do
      [] -> nil
      [assoc] -> assoc.owner_key
    end
  end
end
