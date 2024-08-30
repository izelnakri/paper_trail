import Config

config :paper_trail,
  ecto_repos: [PaperTrail.Repo, PaperTrail.UUIDRepo, PaperTrail.UUIDWithCustomNameRepo]

config :paper_trail, repo: PaperTrail.Repo, originator: [name: :user, model: User]

config :paper_trail, PaperTrail.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("PGUSER"),
  password: System.get_env("PGPASSWORD"),
  database: "paper_trail_test",
  hostname: System.get_env("PGHOST"),
  show_sensitive_data_on_connection_error: true,
  poolsize: 10

config :paper_trail, PaperTrail.UUIDRepo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("PGUSER"),
  password: System.get_env("PGPASSWORD"),
  database: "paper_trail_uuid_test",
  hostname: System.get_env("PGHOST"),
  show_sensitive_data_on_connection_error: true,
  poolsize: 10

config :paper_trail, PaperTrail.UUIDWithCustomNameRepo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("PGUSER"),
  password: System.get_env("PGPASSWORD"),
  database: "paper_trail_uuid_with_custom_name_test",
  hostname: System.get_env("PGHOST"),
  show_sensitive_data_on_connection_error: true,
  poolsize: 10

config :logger, level: :warn
