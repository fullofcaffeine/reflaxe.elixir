import Config

# Test environment configuration  
config :mix_project_example,
  # Disable verbose output during tests
  haxe_verbose: false,
  
  # Test-specific settings
  test_mode: true,
  mock_external_services: true

# Logger configuration for tests
config :logger,
  level: :warn,
  backends: []  # Disable console output during tests

# Print only warnings and errors during test
config :logger, :console,
  level: :warn,
  format: "$message\n"