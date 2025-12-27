import Config

config :phoenix_haxe_example, PhoenixHaxeExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  # Prefer env in test when provided, otherwise use a stable (but non-secret) fallback.
  # NOTE: Keep this low-entropy so secret scanners don't flag example config.
  secret_key_base: System.get_env("TEST_SECRET_KEY_BASE") || String.duplicate("a", 64),
  server: false

config :logger, level: :warn

config :phoenix, :plug_init_mode, :runtime
