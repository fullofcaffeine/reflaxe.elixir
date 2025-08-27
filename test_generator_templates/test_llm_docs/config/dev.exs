import Config

# Development environment configuration
config :mix_project_example,
  # Enable verbose Haxe compilation in development
  haxe_verbose: true,
  
  # Development-specific features
  enable_hot_reload: true,
  debug_mode: true

# Logger configuration for development
config :logger,
  level: :debug,
  compile_time_purge_matching: []

# Enable code reloading for development
config :mix_project_example, MixProjectExample.Endpoint,
  code_reloader: true,
  check_origin: false,
  watchers: [
    # Watch Haxe source files for changes
    haxe: {
      "mix",
      ["compile.haxe", "--force"],
      cd: Path.expand("..")
    }
  ]