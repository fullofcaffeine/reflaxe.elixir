import Config

config :phoenix_haxe_example, PhoenixHaxeExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret",
  server: false

config :logger, level: :warn

config :phoenix, :plug_init_mode, :runtime