alias Grdbii.{Metric, Repo, Python}

Ecto.Adapters.SQL.query!(Repo, """
  CREATE INDEX IF NOT EXISTS metrics_idx ON metrics USING GIN (to_tsvector('english', name))
  """)

Python.fetch!(:python)
|> Stream.map(&Metric.from_python/1)
|> Enum.map(&Repo.insert!/1)
