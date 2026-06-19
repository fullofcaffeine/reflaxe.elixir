import Config

# Test environment configuration  
config :mix_project_example,
  # Disable verbose output during tests
  haxe_verbose: false,
  
  # Test-specific settings
  test_mode: true,
  mock_external_services: true

# Logger configuration for tests
config :logger, level: :warning

# Print only warnings and errors during test
config :logger, :default_formatter,
  format: "$message\n"
