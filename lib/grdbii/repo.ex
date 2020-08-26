defmodule Grdbii.Repo do
  alias Grdbii.Metric
  use Ecto.Repo,
    otp_app: :grdbii,
    adapter: Ecto.Adapters.Postgres
  
  def search(Metric, query, limit \\ 10) do
    Ecto.Adapters.SQL.query!(__MODULE__, """
      SELECT DISTINCT ON (name) id, ts_headline(name, to_tsquery('#{query}')) FROM metrics
      WHERE to_tsvector(name) @@ to_tsquery('#{query}') LIMIT #{limit}
      """)
      |> Map.take([:rows, :num_rows])
  end
end
