import Config

config :elixir_first_liveview, ElixirFirstLiveviewWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: System.get_env("DEV_SECRET_KEY_BASE") || String.duplicate("a", 64),
  watchers: []

config :elixir_first_liveview, ElixirFirstLiveviewWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/elixir_first_liveview_web/(live|views)/.*(ex)$",
      ~r"lib/elixir_first_liveview_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
