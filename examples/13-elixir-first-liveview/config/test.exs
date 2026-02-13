import Config

config :elixir_first_liveview, ElixirFirstLiveviewWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: System.get_env("TEST_SECRET_KEY_BASE") || String.duplicate("a", 64),
  server: false

config :logger, level: :warning

config :swoosh, :api_client, false

config :phoenix, :plug_init_mode, :runtime
