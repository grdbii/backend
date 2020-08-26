import Ecto.Query
alias Grdbii.{Metric, Repo, Python}

metric =
  Metric
  |> Ecto.Query.first
  |> Repo.one
