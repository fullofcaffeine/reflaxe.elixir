import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :test_template_vars, TestTemplateVarsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "3/Wjn+u3WNaz+YotBPU002G7r0C2sUGERXc7okI8l0A2rvUA35j5tdyqU9bbj6+x",
  server: false

# In test we don't send emails
config :test_template_vars, TestTemplateVars.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
