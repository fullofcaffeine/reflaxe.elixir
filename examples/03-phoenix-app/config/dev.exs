import Config

config :phoenix_haxe_example, PhoenixHaxeExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  # Prefer env in dev when provided, otherwise use a stable (but non-secret) fallback.
  # NOTE: Keep this low-entropy so secret scanners don't flag example config.
  secret_key_base: System.get_env("DEV_SECRET_KEY_BASE") || String.duplicate("a", 64),
  watchers: []

config :phoenix_haxe_example, PhoenixHaxeExampleWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/phoenix_haxe_example_web/(live|views)/.*(ex)$",
      ~r"lib/phoenix_haxe_example_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
