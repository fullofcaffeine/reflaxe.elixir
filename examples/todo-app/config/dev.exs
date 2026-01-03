import Config

todo_app_root = Path.expand("../", __DIR__)

find_local_haxe = fn find_local_haxe, dir ->
  candidate = Path.join([dir, "node_modules", ".bin", "haxe"])

  cond do
    File.exists?(candidate) ->
      candidate

    dir == "/" or dir == Path.dirname(dir) ->
      nil

    true ->
      find_local_haxe.(find_local_haxe, Path.dirname(dir))
  end
end

# Dynamically enable optional watchers only when the toolchain is available.
haxe_bin = System.find_executable("haxe") || find_local_haxe.(find_local_haxe, todo_app_root)

# Base watchers (always on)
base_watchers = [
  # esbuild bundling watcher for Phoenix assets
  esbuild: {Esbuild, :install_and_run, [:todo_app, ~w(--sourcemap=external --watch)]},
  # Tailwind CSS watcher (if styles are edited)
  tailwind: {Tailwind, :install_and_run, [:todo_app, ~w(--watch)]}
]

# Optional watchers (enabled only if binaries are present)
optional_watchers =
  if haxe_bin != nil do
    [
      # Server Haxe watcher: regenerates Elixir into lib/ so Phoenix code reloader picks it up.
      mix: ["haxe.watch", "--hxml", "build-server.hxml", "--dirs", "src_haxe/server,src_haxe/shared,src_haxe/contexts", "--debounce", "150", cd: todo_app_root],
      # Client Haxe watcher: regenerates assets/js/hx_app.js; esbuild --watch rebundles into priv/static.
      mix: ["haxe.watch", "--hxml", "build-client.hxml", "--dirs", "src_haxe/client,src_haxe/shared,src_haxe/contexts", "--debounce", "150", cd: todo_app_root]
    ]
  else
    []
  end

all_watchers = base_watchers ++ optional_watchers
disable_watchers = System.get_env("DISABLE_WATCHERS") == "1"

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
  # Prefer env in dev when provided, otherwise use a stable (but non-secret) fallback.
  # NOTE: Keep this low-entropy so secret scanners don't flag example config.
  secret_key_base: System.get_env("DEV_SECRET_KEY_BASE") || String.duplicate("a", 64),
  watchers: (if disable_watchers, do: [], else: all_watchers)

# Watch static and templates for browser reloading.
config :todo_app, TodoAppWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/todo_app_web/(controllers|live|components)/.*(ex|heex)$",
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
