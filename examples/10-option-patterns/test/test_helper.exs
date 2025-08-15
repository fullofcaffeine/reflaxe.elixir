# Test helper for Option patterns example
# Sets up ExUnit configuration for the example

ExUnit.start()

# Configure ExUnit for better output
ExUnit.configure(
  exclude: [:pending, :integration],
  capture_log: true,
  colors: [enabled: true]
)