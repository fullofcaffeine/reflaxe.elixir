defmodule TodoAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :todo_app
  @session_options [store: :cookie, key: "_todo_app_key", signing_salt: "generated_salt_784663", same_site: "Lax"]
  socket("/live", Phoenix.LiveView.Socket, [websocket: [connect_info: [session: @session_options]]])
  plug(Plug.Static, [at: "/", from: :todo_app, gzip: false, only: ~w"""
assets fonts images favicon.ico robots.txt
"""])
  if Code.ensure_loaded?(Phoenix.CodeReloader), do: plug(Phoenix.CodeReloader)
  plug(Plug.RequestId)
  plug(Plug.Telemetry, [event_prefix: [:phoenix, :endpoint]])
  plug(Plug.Parsers, [parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Phoenix.json_library()])
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(TodoAppWeb.Router)
end