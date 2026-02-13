defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app
  @session_options [store: :cookie, key: "_my_app_key", signing_salt: "my_app_signing_salt", same_site: "Lax"]
  socket("/live", Phoenix.LiveView.Socket, [websocket: [connect_info: [session: @session_options]], longpoll: [connect_info: [session: @session_options]]])
  socket("/socket", MyAppWeb.UserSocket, [websocket: [connect_info: [session: @session_options]], longpoll: false])
  plug(Plug.Static, [at: "/", from: :my_app, gzip: false, only: ["assets", "fonts", "images", "favicon.ico", "robots.txt"]])
  if (Code.ensure_loaded?(Phoenix.CodeReloader)), do: plug(Phoenix.CodeReloader)
  plug(Plug.RequestId)
  plug(Plug.Telemetry, [event_prefix: [:phoenix, :endpoint]])
  plug(Plug.Parsers, [parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Phoenix.json_library()])
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(MyAppWeb.Router)
end
