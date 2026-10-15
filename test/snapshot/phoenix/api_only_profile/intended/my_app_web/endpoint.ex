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
  def call(conn, opts) do
    conn = admit_request(conn)
    if (conn.halted), do: conn, else: super(conn, opts)
  end
  def admit_request(conn) do
    if (length(Plug.Conn.get_req_header(conn, "x-fail")) > 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("Admission failure fixture", nil, nil)]
    end
    if (length(Plug.Conn.get_req_header(conn, "x-deny")) > 0) do
      this1 = Plug.Conn.send_resp(conn, 400, "Rejected before dispatch")
      Plug.Conn.halt(this1)
    else
      mark_request(conn)
    end
  end
  defp mark_request(conn) do
    Plug.Conn.put_resp_header(conn, "x-admission", "checked")
  end
end
