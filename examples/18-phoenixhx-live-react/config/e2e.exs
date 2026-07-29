import Config

# Browser QA uses the production-built static assets while retaining the local
# Phoenix endpoint configuration. The sentinel sets DISABLE_WATCHERS=1 for its
# one-shot run, so no Vite, Tailwind, or Haxe watcher survives teardown.
import_config "dev.exs"

port =
  System.get_env("PORT", "4018")
  |> String.to_integer()

config :phoenixhx_live_react, PhoenixhxLiveReactWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: port],
  server: true,
  code_reloader: false

config :logger, level: :warning
