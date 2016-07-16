use Mix.Config

config :paper_trail, ecto_repos: [Repo]

config :paper_trail, Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "paper_trail_test",
  hostname: "localhost",
  poolsize: 10
