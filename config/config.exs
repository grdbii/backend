use Mix.Config

config :cors_plug,
  origin: ["http://localhost:8000"],
  methods: ["GET"]

config :grdbii, :ecto_repos, [Grdbii.Repo]
import_config "#{Mix.env()}.exs"
