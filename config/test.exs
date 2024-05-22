import Config

postgres_user = System.fetch_env!("POSTGRES_USER")
postgres_pass = System.fetch_env!("POSTGRES_PASSWORD")
postgres_host = System.fetch_env!("POSTGRES_HOST")

config :paper_trail,
  ecto_repos: [PaperTrail.Repo, PaperTrail.UUIDRepo, PaperTrail.UUIDWithCustomNameRepo]

config :paper_trail, repo: PaperTrail.Repo, originator: [name: :user, model: User]

config :paper_trail, PaperTrail.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: postgres_user,
  password: postgres_pass,
  database: "paper_trail_test",
  hostname: postgres_host,
  pool: Ecto.Adapters.SQL.Sandbox

config :paper_trail, PaperTrail.UUIDRepo,
  adapter: Ecto.Adapters.Postgres,
  username: postgres_user,
  password: postgres_pass,
  database: "paper_trail_uuid_test",
  hostname: postgres_host,
  pool: Ecto.Adapters.SQL.Sandbox

config :paper_trail, PaperTrail.UUIDWithCustomNameRepo,
  adapter: Ecto.Adapters.Postgres,
  username: postgres_user,
  password: postgres_pass,
  database: "paper_trail_uuid_with_custom_name_test",
  hostname: postgres_host,
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning
