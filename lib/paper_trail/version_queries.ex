defmodule PaperTrail.VersionQueries do
  @moduledoc false
  # TODO: Remove Module with next major release

  @doc false
  @deprecated "Use PaperTrail.get_version/1"
  defdelegate get_version(record), to: PaperTrail

  @doc false
  @deprecated "Use PaperTrail.get_version/2"
  defdelegate get_version(model_or_record, id_or_options), to: PaperTrail

  @doc false
  @deprecated "Use PaperTrail.get_version/3"
  defdelegate get_version(model, id, options), to: PaperTrail

  @doc false
  @deprecated "Use PaperTrail.get_versions/1"
  defdelegate get_versions(record), to: PaperTrail

  @doc false
  @deprecated "Use PaperTrail.get_versions/2"
  defdelegate get_versions(model_or_record, id_or_options), to: PaperTrail

  @doc false
  @deprecated "Use PaperTrail.get_versions/3"
  defdelegate get_versions(model, id, options), to: PaperTrail

  @doc false
  @deprecated "Use PaperTrail.get_current_model/1"
  defdelegate get_current_model(version), to: PaperTrail
end
