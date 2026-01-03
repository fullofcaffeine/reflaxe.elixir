import Config

# E2E environment (browser-driven tests)
# - Dedicated database to isolate from dev/test
# - Server runs by default; port honors PORT env

config :todo_app, TodoApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "todo_app_e2e",
  pool_size: 10,
  # Use precompiled Postgrex types to avoid races under concurrency
  types: TodoApp.PostgrexTypes

port =
  case System.get_env("PORT") do
    nil -> 4001
    val ->
      case Integer.parse(val) do
        {int, _} -> int
        :error -> 4001
      end
  end

config :todo_app, TodoAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: port],
  # Prefer env in CI (SECRET_KEY_BASE); otherwise use a stable (but non-secret) fallback.
  # Keep this low-entropy so secret scanners don't flag example config.
  secret_key_base: System.get_env("SECRET_KEY_BASE") || String.duplicate("a", 64),
  server: true,
  check_origin: false

# Keep logs quieter under E2E
config :logger, level: :warning

# Initialize plugs at runtime for faster compiles
config :phoenix, :plug_init_mode, :runtime

# Deterministic local OAuth-style flow for Playwright (no external secrets/providers).
config :todo_app, :mock_oauth_enabled, true
