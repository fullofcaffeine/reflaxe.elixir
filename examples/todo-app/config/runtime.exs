import Config

# Runtime configuration — runs after compile, ideal for secrets and env‑driven settings.

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing. Generate one with: mix phx.gen.secret"

  port =
    case Integer.parse(System.get_env("PORT") || "4000") do
      {int, _} -> int
      :error -> 4000
    end

  config :todo_app, TodoAppWeb.Endpoint,
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true
end

