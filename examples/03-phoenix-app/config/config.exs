import Config

config :phoenix_haxe_example,
  generators: [context_app: false]

config :phoenix_haxe_example, PhoenixHaxeExampleWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: PhoenixHaxeExampleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PhoenixHaxeExample.PubSub,
  live_view: [signing_salt: "secret"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"