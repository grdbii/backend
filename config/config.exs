use Mix.Config

config :grdbii, :ecto_repos, [Grdbii.Repo]
import_config "#{Mix.env()}.exs"
