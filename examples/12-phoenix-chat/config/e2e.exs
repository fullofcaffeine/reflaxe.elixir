import Config

# E2E config is dev-like (watchers, assets, local endpoint), but allows the
# QA sentinel to run with MIX_ENV=e2e and a custom PORT without requiring any
# app-specific changes.
import_config "dev.exs"

port =
  System.get_env("PORT", "4000")
  |> String.to_integer()

config :phoenix_chat, PhoenixChatWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: port],
  server: true,
  code_reloader: false

