# Native observer boundary: compile and exercise generated endpoint code against
# real Phoenix/Plug/Bandit. Keeping these expectations outside the Haxe compiler
# lets them detect a wrong generated entry point rather than repeat its lowering.
{output, reloading?} =
  case System.argv() do
    [output] -> {output, false}
    [output, "reload-enabled"] -> {output, true}
    _ -> raise("Expected generated output path and optional reload-enabled mode")
  end

for app <- [:phoenix, :bandit, :jason], do: {:ok, _} = Application.ensure_all_started(app)

for app <- [:phoenix, :bandit],
    do: IO.puts("#{app} runtime version: #{Application.spec(app, :vsn)}")

defmodule AdmissionErrorJSON do
  def render("500.json", _assigns), do: %{error: "Internal server error"}
end

Application.put_env(:my_app, MyAppWeb.Endpoint,
  url: [host: "configured.example"],
  force_ssl: [hsts: false, exclude: ["127.0.0.1"]],
  secret_key_base: String.duplicate("x", 64),
  pubsub_server: MyApp.PubSub,
  code_reloader: reloading?,
  render_errors: [formats: [json: AdmissionErrorJSON], layout: false],
  server: false
)

{:ok, _, []} =
  Kernel.ParallelCompiler.compile(
    Path.wildcard(Path.join(output, "**/*.ex")),
    warnings_as_errors: true
  )

# The enabled branch proves strict native compilation only. Running a development
# reload requires a Mix project; this isolated fixture is intentionally not one.
if reloading? do
  IO.puts("endpoint admission: strict full-profile compile with code reloading enabled")
  System.halt(0)
end

{:ok, owner} =
  Supervisor.start_link(
    [
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint
    ],
    strategy: :one_for_one
  )

try do
  allowed = MyAppWeb.Endpoint.call(Plug.Test.conn(:get, "http://allowed.example/api/status"), [])
  301 = allowed.status
  ["https://configured.example/api/status"] = Plug.Conn.get_resp_header(allowed, "location")
  ["checked"] = Plug.Conn.get_resp_header(allowed, "x-admission")

  rejected =
    Plug.Test.conn(:get, "http://allowed.example/api/status")
    |> Plug.Conn.put_req_header("x-deny", "yes")
    |> MyAppWeb.Endpoint.call([])

  400 = rejected.status
  "Rejected before dispatch" = rejected.resp_body
  [] = Plug.Conn.get_resp_header(rejected, "location")
  MyAppWeb.Endpoint = rejected.private.phoenix_endpoint

  routed = MyAppWeb.Endpoint.call(Plug.Test.conn(:get, "https://allowed.example/api/status"), [])
  200 = routed.status
  %{"status" => "ok"} = Jason.decode!(routed.resp_body)
  ["checked"] = Plug.Conn.get_resp_header(routed, "x-admission")

  {:ok, listener} =
    Supervisor.start_child(
      owner,
      {Bandit, plug: MyAppWeb.Endpoint, ip: {127, 0, 0, 1}, port: 0, startup_log: false}
    )

  {:ok, {_ip, port}} = ThousandIsland.listener_info(listener)

  for {extra, expected} <- [
        {"x-deny: yes\r\n", "HTTP/1.1 400 Bad Request"},
        {"", "HTTP/1.1 101 Switching Protocols"},
        {"x-fail: yes\r\n", "HTTP/1.1 500 Internal Server Error"}
      ] do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false], 2_000)

    try do
      failure? = String.starts_with?(extra, "x-fail:")

      request =
        if failure? do
          "GET /api/status HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\nAccept: application/json\r\n"
        else
          "GET /socket/websocket?vsn=2.0.0 HTTP/1.1\r\nHost: 127.0.0.1\r\n" <>
            "Connection: Upgrade\r\nUpgrade: websocket\r\nSec-WebSocket-Version: 13\r\n" <>
            "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
        end

      :ok = :gen_tcp.send(socket, request <> extra <> "\r\n")
      # Read the complete status line; TCP may split it across receive calls.
      read_line = fn read_line, bytes ->
        if String.contains?(bytes, "\r\n") do
          bytes
        else
          {:ok, part} = :gen_tcp.recv(socket, 0, 10_000)
          if byte_size(bytes) + byte_size(part) > 16_384, do: raise("Oversized response headers")
          read_line.(read_line, bytes <> part)
        end
      end

      response = read_line.(read_line, "")

      unless String.starts_with?(response, expected <> "\r\n"),
        do: raise("Unexpected socket admission response: #{inspect(response)}")

      if failure? do
        read_body = fn read_body, bytes ->
          case :gen_tcp.recv(socket, 0, 10_000) do
            {:ok, part} when byte_size(bytes) + byte_size(part) <= 16_384 ->
              read_body.(read_body, bytes <> part)

            {:error, :closed} ->
              bytes

            other ->
              raise("Unexpected bounded error response: #{inspect(other)}")
          end
        end

        [headers, body] = String.split(read_body.(read_body, response), "\r\n\r\n", parts: 2)
        true = String.contains?(String.downcase(headers), "content-type: application/json")
        %{"error" => "Internal server error"} = Jason.decode!(body)
      end
    after
      :gen_tcp.close(socket)
    end
  end

  IO.puts(
    "endpoint admission: rejection precedes SSL and sockets; allowed requests continue; callback failures use Phoenix error handling"
  )
after
  Supervisor.stop(owner)
end
