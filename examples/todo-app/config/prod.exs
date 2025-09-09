import Config

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

# Ensure Repo uses precompiled Postgrex types in production as well.
config :todo_app, TodoApp.Repo,
  types: TodoApp.PostgrexTypes
