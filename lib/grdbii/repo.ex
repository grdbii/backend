defmodule Grdbii.Repo do
  use Ecto.Repo,
    otp_app: :grdbii,
    adapter: Ecto.Adapters.Postgres
end
