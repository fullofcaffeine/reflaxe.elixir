import Config

# Configuration for Mix Project Example
# This file demonstrates how to configure a Mix project that uses Haxe→Elixir compilation

# Application configuration
config :mix_project_example,
  # Environment-specific settings
  environment: config_env(),
  
  # Haxe compilation settings
  haxe_source_dir: "src_haxe",
  haxe_target_dir: "lib",
  
  # Logging configuration
  log_level: :info

# Configure logger
config :logger,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :module, :function]

# Import environment-specific configuration
if config_env() != :prod do
  import_config "#{config_env()}.exs"
end