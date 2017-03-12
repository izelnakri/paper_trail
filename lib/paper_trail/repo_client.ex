defmodule PaperTrail.RepoClient do

  @doc """
  Gets the configured repo module or defaults to Repo if none configured
  """
  def repo, do: Application.get_env(:paper_trail, :repo) || Repo
  def strict_mode, do: Application.get_env(:paper_trail, :strict_mode) || false
end
