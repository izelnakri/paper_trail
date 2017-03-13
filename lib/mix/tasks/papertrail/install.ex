defmodule Mix.Tasks.Papertrail.Install do
  @shortdoc "generates paper_trail migration file for your database"
  @strict_mode PaperTrail.RepoClient.strict_mode()

  import Macro, only: [underscore: 1]
  import Mix.Generator

  use Mix.Task

  def run(_args) do
    path = Path.relative_to("priv/repo/migrations", Mix.Project.app_path)
    file = Path.join(path, "#{timestamp()}_#{underscore(AddVersions)}.exs")
    create_directory path

    create_file file, """
    defmodule Repo.Migrations.AddVersions do
      use Ecto.Migration

      def change do
        create table(:versions) do
          add :event,        :string, null: false
          add :item_type,    :string, null: false
          add :item_id,      :integer
          add :item_changes, :map, null: false
          #{created_by_field()}
          add :meta,         :map

          add :inserted_at,  :utc_datetime, null: false
        end

        # Uncomment if you want to add the following indexes to speed up special queries:
        # create index(:versions, [:item_id, :item_type])
        # create index(:versions, [:event, :item_type])
        # create index(:versions, [:item_type, :inserted_at])
      end
    end
    """
  end

  defp created_by_field do
    case @strict_mode do
      true -> "add :set_by, :string, size: 50, null: false, default: 'unknown'"
      _ -> "add :set_by, :string, size: 50"
    end
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)
end
