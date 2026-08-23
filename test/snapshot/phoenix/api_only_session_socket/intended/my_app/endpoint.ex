defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app
  @session_options [store: :cookie, key: "_my_app_key", signing_salt: "my_app_signing_salt", same_site: "Lax"]
  socket("/session-socket", MyApp.UserSocket, [websocket: [connect_info: [session: @session_options]], longpoll: false])
  socket("/sessionless-socket", MyApp.UserSocket, [websocket: true, longpoll: false])
  if (code_reloading?), do: plug(Phoenix.CodeReloader)
  plug(Plug.RequestId)
  plug(Plug.Telemetry, [event_prefix: [:phoenix, :endpoint]])
  plug(Plug.Parsers, [parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Phoenix.json_library()])
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(MyApp.Router)
end
