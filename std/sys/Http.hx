package sys;

import elixir.types.Term;
import haxe.http.HttpBase.HttpBaseRuntime;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Output;
import sys.net.Socket;

private typedef HeaderPair = {
	var _0:String;
	var _1:String;
};

/**
 * sys.Http (Elixir target)
 *
 * WHAT
 * - Haxe `sys.Http`/`haxe.Http` compatibility backed by OTP `:httpc`.
 *
 * WHY
 * - The upstream implementation builds HTTP over target sockets. On BEAM, `:httpc`
 *   already handles HTTP parsing, redirects, chunking, TLS handshakes, and response
 *   framing better than reimplementing a second client on top of `sys.net.Socket`.
 *
 * HOW
 * - Preserve the `haxe.http.HttpBase` callback contract: `onStatus`, `onData`,
 *   `onBytes`, `onError`, `responseData`, `responseBytes`, and response headers.
 * - Convert Haxe headers/params/body fields to `:httpc.request/4` inputs.
 * - Fail explicitly for surfaces that require separate BEAM contracts: proxy,
 *   caller-supplied sockets, and multipart file transfer.
 */
class Http extends haxe.http.HttpBase {
	public var noShutdown:Bool;
	public var cnxTimeout:Float;
	public var responseHeaders(get, never):Map<String, String>;

	private var file:Null<{
		param:String,
		filename:String,
		io:Input,
		size:Int,
		mimeType:String
	}>;

	public static var PROXY:{host:String, port:Int, auth:{user:String, pass:String}} = null;

	public function new(url:String) {
		noShutdown = false;
		cnxTimeout = 10;
		super(url);
		HttpRuntime.resetResponseHeaders(httpBaseRef);
	}

	public override function request(?post:Bool):Void {
		var output = new BytesOutput();
		var isPost = (post == true) || HttpBaseRuntime.hasRequestBody(httpBaseRef);
		customRequest(isPost, output);
		if (!HttpBaseRuntime.failed(httpBaseRef)) {
			success(output.getBytes());
		}
	}

	@:noCompletion
	@:deprecated("Use fileTransfer instead")
	inline public function fileTransfert(argname:String, filename:String, file:Input, size:Int, mimeType = "application/octet-stream"):Void {
		fileTransfer(argname, filename, file, size, mimeType);
	}

	public function fileTransfer(argname:String, filename:String, fileInput:Input, size:Int, mimeType = "application/octet-stream"):Void {
		HttpRuntime.markFileTransfer(httpBaseRef);
		file = {
			param: argname,
			filename: filename,
			io: fileInput,
			size: size,
			mimeType: mimeType
		};
	}

	public function customRequest(post:Bool, api:Output, ?sock:Socket, ?method:String):Void {
		resetResponseState();

		var unsupportedMessage = unsupportedRequestMessage(sock);
		if (unsupportedMessage != null) {
			onError(unsupportedMessage);
		} else {
			var hadExplicitBody = HttpBaseRuntime.hasRequestBody(httpBaseRef);
			var requestMethod = method != null ? method : defaultMethod(post);
			var requestBody = requestBodyFor(post);
			var requestBodyData = bodyDataFor(requestBody);
			var requestUrl = requestUrlFor(post, requestBody);
			var requestContentType = contentTypeFor(post, requestBody, hadExplicitBody);

			var result = HttpRuntime.request(requestMethod, requestUrl, headerPairs(), requestBodyData, requestContentType, timeoutMillis(cnxTimeout));
			handleResult(result, api);
		}
	}

	function handleResult(result:Term, api:Output):Void {
		if (!HttpRuntime.isOk(result)) {
			fail(HttpRuntime.errorMessage(result));
		} else {
			var status = HttpRuntime.status(result);
			storeResponseHeaders(HttpRuntime.headers(result));
			onStatus(status);
			var body = Bytes.ofData(HttpRuntime.body(result));
			HttpBaseRuntime.setResponseBytes(httpBaseRef, body);
			writeResponseBody(api, body);
			if (status < 200 || status >= 400)
				fail("Http Error #" + status);
		}
	}

	static function writeResponseBody(api:Output, body:Bytes):Void {
		if (body.length > 0)
			api.writeFullBytes(body, 0, body.length);
		api.close();
	}

	public function getResponseHeaderValues(key:String):Null<Array<String>> {
		return HttpRuntime.responseHeaderValues(httpBaseRef, key);
	}

	public static function requestUrl(url:String):String {
		var http = new Http(url);
		http.request(false);
		if (HttpBaseRuntime.failed(http.httpBaseRef))
			throw HttpBaseRuntime.lastError(http.httpBaseRef);
		return http.responseData;
	}

	function resetResponseState():Void {
		HttpBaseRuntime.resetResponse(httpBaseRef);
		HttpRuntime.resetResponseHeaders(httpBaseRef);
	}

	function fail(message:String):Void {
		HttpBaseRuntime.markFailed(httpBaseRef, message);
		onError(message);
	}

	function unsupportedRequestMessage(sock:Socket):Null<String> {
		if (sock != null)
			return
				"sys.Http.customRequest with a caller-supplied Socket is not supported on the Elixir target; use sys.net.Socket directly or let sys.Http use OTP :httpc";
		if (PROXY != null)
			return "sys.Http.PROXY is not supported on the Elixir target yet; configure an OTP :httpc profile or an application HTTP client boundary instead";
		if (file != null || HttpRuntime.hasFileTransfer(httpBaseRef))
			return "sys.Http.fileTransfer is not supported on the Elixir target yet; use a typed Elixir HTTP client boundary for multipart uploads";
		return null;
	}

	static function defaultMethod(post:Bool):String {
		return post ? "POST" : "GET";
	}

	function requestUrlFor(post:Bool, requestBody:Null<Bytes>):String {
		if (post || requestBody != null)
			return url;

		var encodedParams = encodeParams();
		if (encodedParams == "")
			return url;
		return appendQuery(url, encodedParams);
	}

	function requestBodyFor(post:Bool):Null<Bytes> {
		var postData = HttpBaseRuntime.takePostData(httpBaseRef);
		if (postData != null) {
			var body = Bytes.ofString(postData);
			return body;
		}
		var postBytes = HttpBaseRuntime.postBytes(httpBaseRef);
		if (postBytes != null)
			return postBytes;
		if (post)
			return Bytes.ofString(encodeParams());
		return null;
	}

	static function bodyDataFor(requestBody:Null<Bytes>):Term {
		if (requestBody == null)
			return null;
		return requestBody.getData();
	}

	function contentTypeFor(post:Bool, requestBody:Null<Bytes>, hadExplicitBody:Bool):Null<String> {
		if (requestBody == null)
			return null;

		var contentType = headerValue("Content-Type");
		if (contentType != null)
			return contentType;
		return post && !hadExplicitBody ? "application/x-www-form-urlencoded" : "application/octet-stream";
	}

	function headerPairs():Array<HeaderPair> {
		return HttpBaseRuntime.headerPairs(httpBaseRef);
	}

	function headerValue(name:String):Null<String> {
		return HttpBaseRuntime.headerValue(httpBaseRef, name);
	}

	function encodeParams():String {
		return HttpBaseRuntime.encodedParams(httpBaseRef);
	}

	static function appendQuery(baseUrl:String, encodedParams:String):String {
		if (baseUrl.indexOf("?") >= 0)
			return baseUrl + "&" + encodedParams;
		return baseUrl + "?" + encodedParams;
	}

	static function timeoutMillis(seconds:Float):Int {
		if (seconds < 0)
			return 0;
		return Std.int(seconds * 1000);
	}

	function storeResponseHeaders(pairs:Array<HeaderPair>):Void {
		HttpRuntime.storeResponseHeaders(httpBaseRef, pairs);
	}

	function get_responseHeaders():Map<String, String> {
		return HttpRuntime.responseHeaders(httpBaseRef);
	}
}

private class HttpRuntime {
	public static function resetResponseHeaders(ref:Term):Void {
		untyped __elixir__('
            state = Process.get({:reflaxe_sys_http, {0}}, %{headers: %{}, same_key: %{}, file_transfer: false})
            Process.put({:reflaxe_sys_http, {0}}, %{state | headers: %{}, same_key: %{}})
            :ok
        ', ref);
	}

	public static function markFileTransfer(ref:Term):Void {
		untyped __elixir__('
            state = Process.get({:reflaxe_sys_http, {0}}, %{headers: %{}, same_key: %{}, file_transfer: false})
            Process.put({:reflaxe_sys_http, {0}}, %{state | file_transfer: true})
            :ok
        ', ref);
	}

	public static function hasFileTransfer(ref:Term):Bool {
		return untyped __elixir__('Process.get({:reflaxe_sys_http, {0}}, %{file_transfer: false}).file_transfer', ref);
	}

	public static function storeResponseHeaders(ref:Term, pairs:Array<HeaderPair>):Void {
		untyped __elixir__('
            state = Process.get({:reflaxe_sys_http, {0}}, %{headers: %{}, same_key: %{}})

            next_state =
              Enum.reduce({1} || [], state, fn {name, value}, acc ->
                previous = Map.get(acc.headers, name)
                same_key =
                  if is_nil(previous) do
                    acc.same_key
                  else
                    values = Map.get(acc.same_key, name, [previous])
                    Map.put(acc.same_key, name, values ++ [value])
                  end

                %{headers: Map.put(acc.headers, name, value), same_key: same_key}
              end)

            Process.put({:reflaxe_sys_http, {0}}, next_state)
            :ok
        ', ref, pairs);
	}

	public static function responseHeaders(ref:Term):Map<String, String> {
		return cast untyped __elixir__('Process.get({:reflaxe_sys_http, {0}}, %{headers: %{}}).headers', ref);
	}

	public static function responseHeaderValues(ref:Term, key:String):Null<Array<String>> {
		return cast untyped __elixir__('
            state = Process.get({:reflaxe_sys_http, {0}}, %{headers: %{}, same_key: %{}})
            case Map.get(state.same_key, {1}) do
              nil ->
                case Map.get(state.headers, {1}) do
                  nil -> nil
                  value -> [value]
                end
              values -> values
            end
        ', ref, key);
	}

	public static function request(method:String, url:String, headers:Array<HeaderPair>, bodyData:Term, contentType:Null<String>, timeoutMs:Int):Term {
		return untyped __elixir__('
            (fn ->
              try do
                :inets.start()
                :ssl.start()

                method_atom =
                  case String.upcase({0}) do
                    "GET" -> :get
                    "POST" -> :post
                    "HEAD" -> :head
                    "OPTIONS" -> :options
                    "PUT" -> :put
                    "DELETE" -> :delete
                    "TRACE" -> :trace
                    "PATCH" -> :patch
                    other -> raise "sys.Http.customRequest unsupported HTTP method #{inspect(other)}"
                  end

                header_pairs =
                  Enum.map({2} || [], fn {name, value} ->
                    {String.to_charlist(name), String.to_charlist(value)}
                  end)

                timeout =
                  case {5} do
                    value when is_integer(value) and value > 0 -> value
                    _ -> 0
                  end

                http_options = [timeout: timeout, connect_timeout: timeout]
                options = [body_format: :binary]
                url_chars = String.to_charlist({1})

                request =
                  case {3} do
                    nil ->
                      {url_chars, header_pairs}
                    body_bytes ->
                      request_content_type = {4} || "application/octet-stream"
                      {url_chars, header_pairs, String.to_charlist(request_content_type), body_bytes}
                  end

                case :httpc.request(method_atom, request, http_options, options) do
                  {:ok, {{_, status, _}, response_headers, response_body}} ->
                    normalized_headers =
                      Enum.map(response_headers, fn {name, value} ->
                        {to_string(name), to_string(value)}
                      end)

                    {:ok, status, normalized_headers, response_body}

                  {:error, reason} ->
                    {:error, "http_error: " <> inspect(reason)}
                end
              rescue
                error -> {:error, Exception.message(error)}
              catch
                kind, reason -> {:error, "#{kind}: #{inspect(reason)}"}
              end
            end).()
        ', method, url, headers, bodyData, contentType, timeoutMs);
	}

	public static function isOk(result:Term):Bool {
		return untyped __elixir__('case {0} do {:ok, _, _, _} -> true; _ -> false end', result);
	}

	public static function status(result:Term):Int {
		return untyped __elixir__('case {0} do {:ok, status, _, _} -> status; _ -> 0 end', result);
	}

	public static function headers(result:Term):Array<HeaderPair> {
		return cast untyped __elixir__('case {0} do {:ok, _, headers, _} -> headers; _ -> [] end', result);
	}

	public static function body(result:Term):haxe.io.BytesData {
		return untyped __elixir__('case {0} do {:ok, _, _, body} -> body; _ -> <<>> end', result);
	}

	public static function errorMessage(result:Term):String {
		return untyped __elixir__('case {0} do {:error, message} -> message; other -> "sys.Http unexpected response: " <> inspect(other) end', result);
	}
}
