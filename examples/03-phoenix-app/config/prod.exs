import Config

# Keep compile-time production settings small. Port, host, and secrets belong
# in runtime.exs so the same compiled application can run in different
# environments without rebuilding it.
config :logger, level: :info

config :phoenix, :plug_init_mode, :runtime
