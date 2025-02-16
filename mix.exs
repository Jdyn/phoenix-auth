defmodule Nimble.MixProject do
  use Mix.Project

  def project do
    [
      app: :nimble,
      version: "0.1.0",
      elixir: "~> 1.18.1",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Nimble.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "priv", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web", "priv"]

  # Specifies your project dependencies.
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.19"},
      {:phoenix_ecto, "~> 4.6.3"},
      {:ecto_sql, "~> 3.12.1"},
      {:postgrex, "~> 0.20.0"},
      {:swoosh, "~> 1.17.10"},
      {:assent, "~> 0.3.0"},
      {:styler, "~> 1.3.3", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.4.4"},
      {:req, "~> 0.5.8"},
      {:cors_plug, "~> 3.0.3"},
      {:pbkdf2_elixir, "~> 2.3.1"},
      {:uniq, "~> 0.6.1"},
      {:plug_cowboy, "~> 2.7.2"},
      {:ex_phone_number, "~> 0.4.5"},
      {:bandit, "~> 1.6.7"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
