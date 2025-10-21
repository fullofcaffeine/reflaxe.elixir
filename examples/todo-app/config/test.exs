import Config

# We don't run a server during test
config :todo_app, TodoAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  # Test seldom needs a real secret; allow env override for CI hygiene
  secret_key_base: System.get_env("TEST_SECRET_KEY_BASE") ||
    "HFnRr3hEFYrcH3i7y3b7Z1234567890abcdefghijklmnopqrstuvwxyz1234567",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Dedicated test database with SQL Sandbox
config :todo_app, TodoApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "todo_app_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  # Use precompiled Postgrex types in tests to avoid races in concurrent DB usage
  types: TodoApp.PostgrexTypes
