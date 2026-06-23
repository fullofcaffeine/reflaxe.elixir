import Config

# E2E config is dev-like (watchers, assets, local endpoint), but allows the
# QA sentinel to run with MIX_ENV=e2e and a custom PORT without requiring any
# app-specific changes.
import_config "dev.exs"

config :phoenix_hx_todo, PhoenixHxTodo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_hx_todo_e2e",
  pool_size: 10,
  types: PhoenixHxTodo.PostgrexTypes

port =
  System.get_env("PORT", "4000")
  |> String.to_integer()

config :phoenix_hx_todo, PhoenixHxTodoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: port],
  server: true,
  code_reloader: false
