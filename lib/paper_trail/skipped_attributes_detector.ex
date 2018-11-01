defmodule PaperTrail.SkippedAttributesDetector do
  @doc """
  Gets list of skipped attributes for a module
  """
  @spec call(module :: atom()) :: List.t()
  def call(module) when is_atom(module) do
    case :erlang.function_exported(module, :paper_trail_skip, 0) do
      true ->
        attrs = module.paper_trail_skip

        case is_list(attrs) do
          true ->
            attrs
          _ ->
            raise ArgumentError
        end
      _ ->
        []
    end
  end
end
