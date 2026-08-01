import Config

if System.get_env("PHX_SERVER") do
  config :phoenix_haxe_example, PhoenixHaxeExampleWeb.Endpoint, server: true
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE is required when running the minimal Phoenix example in production"

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :phoenix_haxe_example, PhoenixHaxeExampleWeb.Endpoint,
    url: [host: host, port: port, scheme: "http"],
    http: [ip: {127, 0, 0, 1}, port: port],
    secret_key_base: secret_key_base
end
