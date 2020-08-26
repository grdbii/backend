import Mix.Config

config :grdbii, Grdbii.Repo,
  database: "grdb",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :grdbii,
  python_lib: "./venv/lib/python3.6",
  python_pool_size: 5
