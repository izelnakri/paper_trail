use Mix.Config

config :example, Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "papertrail_example_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  poolsize: 10
