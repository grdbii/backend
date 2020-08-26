defmodule Grdbii.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    python_config = [
      name: {:local, :python},
      worker_module: Grdbii.Python,
      size: Application.fetch_env!(:grdbii, :python_pool_size)
    ]

    children = [
      # {Plug.Cowboy, scheme: :http, plug: Grdbii, options: [port: 4001]},
      :poolboy.child_spec(:python, python_config),
      {Grdbii.Repo, []}
    ]

    opts = [strategy: :one_for_one, name: Grdbii.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
