import Config

# Dynamically enable optional watchers only when the executables are available
npm_bin = System.find_executable("npm")

# Base watchers (always on)
base_watchers = [
  # esbuild bundling watcher for Phoenix assets
  esbuild: {Esbuild, :install_and_run, [:todo_app, ~w(--sourcemap=external --watch)]},
  # Tailwind CSS watcher (if styles are edited)
  tailwind: {Tailwind, :install_and_run, [:todo_app, ~w(--watch)]}
]

# Optional watchers (enabled only if binaries are present)
optional_watchers = []
optional_watchers =
  if npm_bin do
    # Use npm to invoke the Haxe client watcher (portable and PATH-friendly)
    Keyword.put(optional_watchers, :haxe_client, [npm_bin, "--prefix", Path.expand("../assets", __DIR__), "run", "watch:haxe", cd: Path.expand("../", __DIR__)])
  else
    optional_watchers
  end

all_watchers = base_watchers ++ optional_watchers

# Configure the database
config :todo_app, TodoApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "todo_app_dev",
  # Use default Postgrex types
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.

# Allow overriding the port via PORT; default to 4000 for dev
dev_port =
  case System.get_env("PORT") do
    nil -> 4000
    val ->
      case Integer.parse(val) do
        {int, _} -> int
        :error -> 4000
      end
  end

config :todo_app, TodoAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: dev_port],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  # Prefer env in dev when provided, otherwise use a stable, non-sensitive fallback
  secret_key_base: System.get_env("DEV_SECRET_KEY_BASE") ||
    "HFnRr3hEFYrcH3i7y3b7Z1234567890abcdefghijklmnopqrstuvwxyz1234567",
  watchers: all_watchers

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
