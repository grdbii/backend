import Mix.Config

config :grdbii, Grdbii.Repo,
  database: "grdb",
  username: "postgres",
  password: "postgres",
  hostname: "postgres"

config :grdbii,
  python_lib: "/usr/lib/python3.6",
  python_pool_size: 12
