alias Grdbii.{Metric, Repo, Python}

Python.fetch(:python)
|> Stream.map(&Metric.from_python/1)
|> Enum.map(&Repo.insert!/1)
