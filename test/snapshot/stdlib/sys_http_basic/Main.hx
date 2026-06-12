import haxe.Http;
import haxe.io.BytesOutput;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function startServer(expectedMethod:String, expectedNeedle:String, status:Int, responseBody:String):Int {
		return untyped __elixir__('
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
                  String.starts_with?(request, {0} <> " ") and
                    ({1} == "" or String.contains?(request, {1}))

                actual_status = if request_ok, do: {2}, else: 500
                body = if request_ok, do: {3}, else: "server request mismatch"
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
        ', expectedMethod, expectedNeedle, status, responseBody);
	}

	static function url(port:Int, path:String):String {
		return 'http://127.0.0.1:$port$path';
	}

	static function putCallbackString(key:String, value:String):Void {
		untyped __elixir__("Process.put({0}, {1})", key, value);
	}

	static function putCallbackInt(key:String, value:Int):Void {
		untyped __elixir__("Process.put({0}, {1})", key, value);
	}

	static function getCallbackString(key:String):String {
		return untyped __elixir__("Process.get({0})", key);
	}

	static function getCallbackInt(key:String):Int {
		return untyped __elixir__("Process.get({0})", key);
	}

	static function mapValue(map:Map<String, String>, key:String):String {
		return untyped __elixir__("Map.get({0}, {1})", map, key);
	}

	static function testRequestUrl():Void {
		var port = startServer("GET", "/hello", 200, "request-url-ok");
		var body = Http.requestUrl(url(port, "/hello"));
		assertThat(body == "request-url-ok", "Http.requestUrl should return response body");
	}

	static function testCallbacksAndHeaders():Void {
		var port = startServer("GET", "name=alfa%20beta", 200, "get-ok");
		var http = new Http(url(port, "/search"));

		http.setParameter("name", "alfa beta");
		http.onStatus = function(nextStatus:Int) {
			putCallbackInt("sys_http_status", nextStatus);
		};
		http.onData = function(nextData:String) {
			putCallbackString("sys_http_data", nextData);
		};
		http.onBytes = function(nextBytes) {
			putCallbackString("sys_http_bytes", nextBytes.toString());
		};
		http.request(false);

		assertThat(getCallbackInt("sys_http_status") == 200, "GET should report status 200");
		assertThat(getCallbackString("sys_http_data") == "get-ok", "GET should call onData");
		assertThat(getCallbackString("sys_http_bytes") == "get-ok", "GET should call onBytes");
		assertThat(http.responseData == "get-ok", "GET should expose responseData");
		assertThat(http.responseBytes.toString() == "get-ok", "GET should expose responseBytes");
		assertThat(mapValue(http.responseHeaders, "x-test") == "two", "duplicate responseHeaders should keep last value");

		var values = http.getResponseHeaderValues("x-test");
		assertThat(values != null && values.length == 2 && values[0] == "one" && values[1] == "two",
			"getResponseHeaderValues should preserve duplicate headers");
	}

	static function testPostForm():Void {
		var port = startServer("POST", "answer=42", 201, "post-ok");
		var http = new Http(url(port, "/submit"));

		http.setParameter("answer", "42");
		http.onStatus = function(nextStatus:Int) {
			putCallbackInt("sys_http_post_status", nextStatus);
		};
		http.onData = function(nextData:String) {
			putCallbackString("sys_http_post_data", nextData);
		};
		http.request(true);

		assertThat(getCallbackInt("sys_http_post_status") == 201, "POST should report status 201");
		assertThat(getCallbackString("sys_http_post_data") == "post-ok", "POST form should call onData");
	}

	static function testCustomMethod():Void {
		var port = startServer("PUT", "payload", 200, "put-ok");
		var http = new sys.Http(url(port, "/resource"));
		var output = new BytesOutput();

		http.setPostData("payload");
		http.customRequest(false, output, null, "PUT");

		assertThat(output.getBytes().toString() == "put-ok", "customRequest should support PUT through :httpc");
	}

	static function testStatusError():Void {
		var port = startServer("GET", "/missing", 404, "missing");
		var http = new Http(url(port, "/missing"));

		http.onStatus = function(nextStatus:Int) {
			putCallbackInt("sys_http_error_status", nextStatus);
		};
		http.onError = function(message:String) {
			putCallbackString("sys_http_error", message);
		};
		http.request(false);

		assertThat(getCallbackInt("sys_http_error_status") == 404, "HTTP errors should still report status");
		assertThat(getCallbackString("sys_http_error") == "Http Error #404", "HTTP errors should call onError with Haxe-compatible message");
		assertThat(http.responseBytes.toString() == "missing", "HTTP error should retain response body bytes");
	}

	public static function main():Void {
		testRequestUrl();
		testCallbacksAndHeaders();
		testPostForm();
		testCustomMethod();
		testStatusError();
	}
}
