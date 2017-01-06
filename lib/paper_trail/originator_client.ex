defmodule PaperTrail.OriginatorClient do

  @doc """
  Gives details for originator tracking
  """
  def originator, do: Application.get_env(:paper_trail, :originator) || nil
end
