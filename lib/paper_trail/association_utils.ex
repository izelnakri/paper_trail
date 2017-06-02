defmodule PaperTrail.AssociationUtils do
  @client PaperTrail.RepoClient
  @repo @client.repo()

  def get_all_children(struct) do
    struct.__struct__
    |> get_child_assocs_that_delete()
    |> Enum.flat_map(&@repo.all(Ecto.assoc(struct, &1)))
    |> Enum.flat_map(&[&1 | get_all_children(&1)])
  end

  def get_child_assocs_that_delete(schema) do
    :associations
    |> schema.__schema__()
    |> Enum.map(&schema.__schema__(:association, &1))
    |> Enum.filter(&(Map.get(&1, :relationship) == :child))
    |> Enum.filter(&(Map.get(&1, :on_delete) == :delete_all))
    |> Enum.map(&Map.get(&1, :field))
  end
end
