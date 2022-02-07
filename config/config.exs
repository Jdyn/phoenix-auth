# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :nimble,
  ecto_repos: [Nimble.Repo]

# Configures the endpoint
config :nimble, Nimble.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "hbfYDlpG/H+OUeyXAdH3v71oxfA504VjHz/LWlmJS0f4u/c9HxHpBdGhSa+TyLd2",
  render_errors: [view: Nimble.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Nimble.PubSub,
  live_view: [signing_salt: "JOaxJkdG"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
