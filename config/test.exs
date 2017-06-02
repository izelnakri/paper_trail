use Mix.Config

config :paper_trail, ecto_repos: [PaperTrail.Repo, PaperTrail.UUIDRepo]

config :paper_trail, repo: PaperTrail.Repo, originator: [name: :user, model: User]

config :paper_trail, PaperTrail.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "paper_trail_test",
  hostname: "localhost",
  poolsize: 10

config :paper_trail, PaperTrail.UUIDRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "paper_trail_uuid_test",
  hostname: "localhost",
  poolsize: 10

config :logger, level: :info
