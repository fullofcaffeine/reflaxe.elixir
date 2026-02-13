import Config

config :elixir_first_liveview,
  generators: [context_app: false]

config :elixir_first_liveview, ElixirFirstLiveviewWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [html: ElixirFirstLiveviewWeb.ErrorHTML, json: ElixirFirstLiveviewWeb.ErrorJSON], layout: false],
  pubsub_server: ElixirFirstLiveview.PubSub,
  live_view: [signing_salt: "elixir_first_liveview_signing_salt"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason
config :swoosh, :api_client, false

import_config "#{config_env()}.exs"
