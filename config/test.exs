use Mix.Config

config :paper_trail, ecto_repos: [PaperTrail.Repo]

config :paper_trail, repo: PaperTrail.Repo

config :paper_trail, PaperTrail.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "paper_trail_test",
  hostname: "localhost",
  poolsize: 10
