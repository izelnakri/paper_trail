use Mix.Config

config :example, Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "paper_trail_example_test",
  hostname: "localhost",
  poolsize: 10
