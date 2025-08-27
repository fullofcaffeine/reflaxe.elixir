import Config

# Production environment configuration
config :mix_project_example,
  # Disable verbose compilation in production
  haxe_verbose: false,
  
  # Production optimizations  
  enable_optimizations: true,
  debug_mode: false

# Logger configuration for production
config :logger,
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

# Runtime production configuration (if needed)
# config :mix_project_example, MixProjectExample.Repo,
#   url: System.get_env("DATABASE_URL"),
#   pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")