defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp start_server(expected_method, expected_needle, status, response_body) do

                (fn ->
                  {:ok, listener} =
                    :gen_tcp.listen(0, [
                      :binary,
                      {:active, false},
                      {:packet, :raw},
                      {:reuseaddr, true},
                      {:ip, {127, 0, 0, 1}}
                    ])

                  {:ok, {{127, 0, 0, 1}, port}} = :inet.sockname(listener)

                  spawn(fn ->
                    {:ok, socket} = :gen_tcp.accept(listener)
                    {:ok, request} = :gen_tcp.recv(socket, 0, 5_000)

                    request_ok =
                      String.starts_with?(request, expected_method <> " ") and
                        (expected_needle == "" or String.contains?(request, expected_needle))

                    actual_status = if request_ok, do: status, else: 500
                    body = if request_ok, do: response_body, else: "server request mismatch"
                    reason = if actual_status >= 400, do: "ERROR", else: "OK"

                    crlf = <<13, 10>>

                    response =
                      "HTTP/1.1 #{actual_status} #{reason}" <> crlf <>
                        "content-type: text/plain" <> crlf <>
                        "x-test: one" <> crlf <>
                        "x-test: two" <> crlf <>
                        "content-length: #{byte_size(body)}" <> crlf <>
                        crlf <>
                        body

                    :ok = :gen_tcp.send(socket, response)
                    :gen_tcp.close(socket)
                    :gen_tcp.close(listener)
                  end)

                  port
                end).()

  end
  defp url(port, path) do
    "http://127.0.0.1:#{Reflaxe.Elixir.HaxeFloat.to_string(port)}#{path}"
  end
  defp put_callback_string(key, value) do
    Process.put(key, value)
  end
  defp put_callback_int(key, value) do
    Process.put(key, value)
  end
  defp get_callback_string(key) do
    Process.get(key)
  end
  defp get_callback_int(key) do
    Process.get(key)
  end
  defp map_value(map, key) do
    Map.get(map, key)
  end
  defp test_request_url() do
    port = start_server("GET", "/hello", 200, "request-url-ok")
    body = Http.request_url(url(port, "/hello"))
    _ = assert_that(body == "request-url-ok", "Http.requestUrl should return response body")
  end
  defp test_callbacks_and_headers() do
    port = start_server("GET", "name=alfa%20beta", 200, "get-ok")
    http = Http.new(url(port, "/search"))
    _ = apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :set_parameter, [http, "name", "alfa beta"])
    http = %{http | on_status: fn next_status -> put_callback_int("sys_http_status", next_status) end}
    http = %{http | on_data: fn next_data -> put_callback_string("sys_http_data", next_data) end}
    http = %{http | on_bytes: fn next_bytes -> put_callback_string("sys_http_bytes", apply(Map.get(next_bytes, :__reflaxe_class__) || Map.get(next_bytes, :__struct__), :to_string, [next_bytes])) end}
    _ = apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :request, [http, false])
    _ = assert_that(get_callback_int("sys_http_status") == 200, "GET should report status 200")
    _ = assert_that(get_callback_string("sys_http_data") == "get-ok", "GET should call onData")
    _ = assert_that(get_callback_string("sys_http_bytes") == "get-ok", "GET should call onBytes")
    _ = assert_that(HttpBase.get_response_data(http) == "get-ok", "GET should expose responseData")
    _ =
      assert_that((fn ->
        reflaxe_dispatch_receiver = HttpBase.get_response_bytes(http)
        _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
      end).() == "get-ok", "GET should expose responseBytes")
    _ = assert_that(map_value(Http.get_response_headers(http), "x-test") == "two", "duplicate responseHeaders should keep last value")
    values = apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :get_response_header_values, [http, "x-test"])
    _ = assert_that(not Kernel.is_nil(values) and length(values) == 2 and Enum.at(values, 0) == "one" and Enum.at(values, 1) == "two", "getResponseHeaderValues should preserve duplicate headers")
  end
  defp test_post_form() do
    port = start_server("POST", "answer=42", 201, "post-ok")
    http = Http.new(url(port, "/submit"))
    _ = apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :set_parameter, [http, "answer", "42"])
    http = %{http | on_status: fn next_status -> put_callback_int("sys_http_post_status", next_status) end}
    http = %{http | on_data: fn next_data -> put_callback_string("sys_http_post_data", next_data) end}
    _ = apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :request, [http, true])
    _ = assert_that(get_callback_int("sys_http_post_status") == 201, "POST should report status 201")
    _ = assert_that(get_callback_string("sys_http_post_data") == "post-ok", "POST form should call onData")
  end
  defp test_custom_method() do
    port = start_server("PUT", "payload", 200, "put-ok")
    http = Http.new(url(port, "/resource"))
    output = BytesOutput.new()
    _ = apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :set_post_data, [http, "payload"])
    _ = apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :custom_request, [http, false, output, nil, "PUT"])
    _ =
      assert_that((fn ->
        reflaxe_dispatch_receiver = apply(Map.get(output, :__reflaxe_class__) || Map.get(output, :__struct__), :get_bytes, [output])
        _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
      end).() == "put-ok", "customRequest should support PUT through :httpc")
  end
  defp test_status_error() do
    port = start_server("GET", "/missing", 404, "missing")
    http = Http.new(url(port, "/missing"))
    http = %{http | on_status: fn next_status -> put_callback_int("sys_http_error_status", next_status) end}
    http = %{http | on_error: fn message -> put_callback_string("sys_http_error", message) end}
    _ = apply(Map.get(http, :__reflaxe_class__) || Map.get(http, :__struct__), :request, [http, false])
    _ = assert_that(get_callback_int("sys_http_error_status") == 404, "HTTP errors should still report status")
    _ = assert_that(get_callback_string("sys_http_error") == "Http Error #404", "HTTP errors should call onError with Haxe-compatible message")
    _ =
      assert_that((fn ->
        reflaxe_dispatch_receiver = HttpBase.get_response_bytes(http)
        _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
      end).() == "missing", "HTTP error should retain response body bytes")
  end
  def main() do
    _ = test_request_url()
    _ = test_callbacks_and_headers()
    _ = test_post_form()
    _ = test_custom_method()
    _ = test_status_error()
  end
end
