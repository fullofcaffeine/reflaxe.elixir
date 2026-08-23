defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app
  socket("/socket", MyAppWeb.UserSocket, [websocket: true, longpoll: false])
  socket("/socket-with-explicit-false", MyAppWeb.UserSocket, [websocket: true, longpoll: false])
  if (code_reloading?), do: plug(Phoenix.CodeReloader)
  plug(Plug.RequestId)
  plug(Plug.Telemetry, [event_prefix: [:phoenix, :endpoint]])
  plug(Plug.Parsers, [parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Phoenix.json_library()])
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(MyAppWeb.Router)
end
