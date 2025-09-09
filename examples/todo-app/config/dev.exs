import Config

# Configure the database
config :todo_app, TodoApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "todo_app_dev",
  # Use precompiled Postgrex types module (extern-backed) to avoid runtime TypeManager races
  types: TodoApp.PostgrexTypes,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
config :todo_app, TodoAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "HFnRr3hEFYrcH3i7y3b7Z1234567890abcdefghijklmnopqrstuvwxyz1234567",
  watchers: [
    # Haxe client compilation watcher (flat list format for Phoenix.Endpoint.Watcher)
    # haxe_client: ["haxe", "build-client.hxml", "--wait", "6001"],
    # esbuild bundling watcher  
    # esbuild: {Esbuild, :install_and_run, [:todo_app, ~w(--sourcemap=external --watch)]},
    # Tailwind CSS watcher
    # tailwind: {Tailwind, :install_and_run, [:todo_app, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :todo_app, TodoAppWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/todo_app_web/(controllers|live|components)/.*(ex|heex)$",
      # Watch Haxe source files for recompilation
      ~r"src_haxe/.*(hx)$",
      # Watch generated Elixir files
      ~r"lib/.*(ex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :todo_app, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
# config :phoenix, :plug_init_mode, :runtime  # Deprecated in Phoenix 1.7
