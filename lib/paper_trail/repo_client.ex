defmodule PaperTrail.RepoClient do
  @doc """
  Gets the configured repo module or defaults to Repo if none configured
  """
  def repo, do: env(:repo, Repo)
  def originator, do: env(:originator, nil)
  def strict_mode, do: env(:strict_mode, false)
  def item_type, do: env(:item_type, :integer)
  def originator_type, do: env(:originator_type, :integer)
  def originator_relationship_opts, do: env(:originator_relationship_options, [])
  def timestamps_type, do: env(:timestamps_type, :utc_datetime)
  def origin_read_after_writes(), do: env(:origin_read_after_writes, true)

  defp env(k, default), do: Application.get_env(:paper_trail, k, default)
end
