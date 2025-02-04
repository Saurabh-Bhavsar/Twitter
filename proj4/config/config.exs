# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :proj4,
  ecto_repos: [Proj4.Repo]

# Configures the endpoint
config :proj4, Proj4Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rzlYcultO/gEeCLlc5WyYZadq5MsBpOJNnDa5e0t28YYRaP9DrkRt7qYjFSuQGUD",
  render_errors: [view: Proj4Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Proj4.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
