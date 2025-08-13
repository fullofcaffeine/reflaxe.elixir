import Config

# We don't run a server during test
config :todo_app, TodoAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "HFnRr3hEFYrcH3i7y3b7Z1234567890abcdefghijklmnopqrstuvwxyz1234567",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime