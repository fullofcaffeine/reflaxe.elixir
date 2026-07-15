# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :phoenix_chat,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :phoenix_chat, PhoenixChatWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PhoenixChatWeb.ErrorHTML, json: PhoenixChatWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PhoenixChat.PubSub,
  live_view: [signing_salt: "n6w0LkDj"]

# BEGIN phoenix_chat vite_live_react_config
# The first proof is client-only: stock live_react never starts an SSR runtime.
config :live_react, ssr: false
# END phoenix_chat vite_live_react_config

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  phoenix_chat: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
