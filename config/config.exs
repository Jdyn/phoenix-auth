# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :nimble,
  ecto_repos: [Nimble.Repo],
  generators: [timestamp_type: :utc_datetime]

config :nimble, Nimble.Repo,
  migration_primary_key: [name: :id, type: :binary_id]

# Configures the endpoint
config :nimble, Nimble.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  secret_key_base: "hbfYDlpG/H+OUeyXAdH3v71oxfA504VjHz/LWlmJS0f4u/c9HxHpBdGhSa+TyLd2",
  render_errors: [view: Nimble.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Nimble.PubSub,
  live_view: [signing_salt: "JOaxJkdG"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, JSON

config :swoosh, :api_client, Swoosh.ApiClient.Req
config :swoosh, :json_library, JSON

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
