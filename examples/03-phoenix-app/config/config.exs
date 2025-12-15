import Config

config :phoenix_haxe_example,
  generators: [context_app: false]

config :phoenix_haxe_example, PhoenixHaxeExampleWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [html: PhoenixHaxeExampleWeb.ErrorHTML, json: PhoenixHaxeExampleWeb.ErrorJSON], layout: false],
  pubsub_server: PhoenixHaxeExample.PubSub,
  live_view: [signing_salt: "phoenix_haxe_example_signing_salt"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
