defmodule Grdbii.MixProject do
  use Mix.Project

  def project do
    [
      app: :grdbii,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Grdbii.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.4"},
      {:postgrex, "~> 0.15.5"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 4.0"},
      {:export, "~> 0.1.0"},
      {:poolboy, "~> 1.5"},
      {:distillery, "~> 2.1"}
    ]
  end
end
