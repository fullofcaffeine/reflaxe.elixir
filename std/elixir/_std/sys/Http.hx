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

private typedef FileTransfer = {
	var param:String;
	var filename:String;
	var io:Input;
	var size:Int;
	var mimeType:String;
};

private typedef RequestPayload = {
	var body:Null<Bytes>;
	var contentType:Null<String>;
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
 * - Fail explicitly for surfaces that require separate BEAM contracts: proxy
 *   and caller-supplied sockets.
 */
class Http extends haxe.http.HttpBase {
	public var noShutdown:Bool;
	public var cnxTimeout:Float;
	public var responseHeaders(get, never):Map<String, String>;

	public static var PROXY:{host:String, port:Int, auth:{user:String, pass:String}} = null;

	public function new(url:String) {
		noShutdown = false;
		cnxTimeout = 10;
		super(url);
		HttpRuntime.resetResponseHeaders(httpBaseRef);
	}

	public override function request(?post:Bool):Void {
		var output = new BytesOutput();
		var isPost = (post == true) || HttpBaseRuntime.hasRequestBody(httpBaseRef) || HttpRuntime.hasFileTransfer(httpBaseRef);
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
		HttpRuntime.storeFileTransfer(httpBaseRef, {
			param: argname,
			filename: filename,
			io: fileInput,
			size: size,
			mimeType: mimeType
		});
	}

	public function customRequest(post:Bool, api:Output, ?sock:Socket, ?method:String):Void {
		resetResponseState();

		var unsupportedMessage = unsupportedRequestMessage(sock);
		if (unsupportedMessage != null) {
			fail(unsupportedMessage);
		} else {
			var transfer = HttpRuntime.fileTransfer(httpBaseRef);
			var effectivePost = post || transfer != null;
			var hadExplicitBody = HttpBaseRuntime.hasRequestBody(httpBaseRef);
			var requestMethod = method != null ? method : defaultMethod(effectivePost);
			var payload = requestPayloadFor(effectivePost, transfer, hadExplicitBody);
			var requestBodyData = bodyDataFor(payload.body);
			var requestUrl = requestUrlFor(effectivePost, payload.body);

			var result = HttpRuntime.request(requestMethod, requestUrl, headerPairs(), requestBodyData, payload.contentType, timeoutMillis(cnxTimeout));
			handleResult(result, api);
		}
	}

	function requestPayloadFor(post:Bool, transfer:Null<FileTransfer>, hadExplicitBody:Bool):RequestPayload {
		if (transfer == null) {
			var body = requestBodyFor(post);
			return {
				body: body,
				contentType: contentTypeFor(post, body, hadExplicitBody)
			};
		}

		var boundary = HttpRuntime.multipartBoundary();
		return {
			body: multipartBody(transfer, boundary),
			contentType: "multipart/form-data; boundary=" + boundary
		};
	}

	function handleResult(result:Term, api:Output):Void {
		if (!HttpRuntime.isOk(result)) {
			fail(HttpRuntime.errorMessage(result));
		} else {
			var status = HttpRuntime.status(result);
			storeResponseHeaders(HttpRuntime.headers(result));
			HttpBaseRuntime.callOnStatus(this, status);
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
		HttpBaseRuntime.callOnError(this, message);
	}

	function unsupportedRequestMessage(sock:Socket):Null<String> {
		if (sock != null)
			return
				"sys.Http.customRequest with a caller-supplied Socket is not supported on the Elixir target; use sys.net.Socket directly or let sys.Http use OTP :httpc";
		if (PROXY != null)
			return "sys.Http.PROXY is not supported on the Elixir target yet; configure an OTP :httpc profile or an application HTTP client boundary instead";
		return null;
	}

	/** Build the multipart body when the request starts, as the Haxe API requires. */
	function multipartBody(transfer:FileTransfer, boundary:String):Bytes {
		var output = new BytesOutput();
		for (parameter in HttpBaseRuntime.parameterPairs(httpBaseRef)) {
			output.writeString("--" + boundary + "\r\n");
			output.writeString('Content-Disposition: form-data; name="${parameter._0}"\r\n\r\n');
			output.writeString(parameter._1 + "\r\n");
		}

		output.writeString("--" + boundary + "\r\n");
		output.writeString('Content-Disposition: form-data; name="${transfer.param}"; filename="${transfer.filename}"\r\n');
		output.writeString("Content-Type: " + transfer.mimeType + "\r\n\r\n");

		var buffer = Bytes.alloc(4096);
		writeFileBytes(output, transfer.io, transfer.size, buffer);

		output.writeString("\r\n--" + boundary + "--");
		return output.getBytes();
	}

	static function writeFileBytes(output:BytesOutput, input:Input, remaining:Int, buffer:Bytes):Void {
		if (remaining <= 0)
			return;

		var requested = remaining > buffer.length ? buffer.length : remaining;
		var read = readFileChunk(input, buffer, requested);
		if (read == null)
			return;
		if (read == 0)
			throw haxe.io.Error.Blocked;
		output.writeFullBytes(buffer, 0, read);
		writeFileBytes(output, input, remaining - read, buffer);
	}

	static function readFileChunk(input:Input, buffer:Bytes, requested:Int):Null<Int> {
		try {
			return input.readBytes(buffer, 0, requested);
		} catch (_:haxe.io.Eof) {
			return null;
		}
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
		var postData = HttpBaseRuntime.postData(httpBaseRef);
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
            state = Process.get({:reflaxe_sys_http, {0}}, %{headers: %{}, same_key: %{}, file_transfer: nil})
            Process.put({:reflaxe_sys_http, {0}}, %{state | headers: %{}, same_key: %{}})
            :ok
        ', ref);
	}

	public static function storeFileTransfer(ref:Term, transfer:FileTransfer):Void {
		untyped __elixir__('
            state = Process.get({:reflaxe_sys_http, {0}}, %{headers: %{}, same_key: %{}, file_transfer: nil})
            Process.put({:reflaxe_sys_http, {0}}, %{state | file_transfer: {1}})
            :ok
        ', ref, transfer);
	}

	public static function hasFileTransfer(ref:Term):Bool {
		return untyped __elixir__('not is_nil(Process.get({:reflaxe_sys_http, {0}}, %{file_transfer: nil}).file_transfer)', ref);
	}

	public static function fileTransfer(ref:Term):Null<FileTransfer> {
		return cast untyped __elixir__('Process.get({:reflaxe_sys_http, {0}}, %{file_transfer: nil}).file_transfer', ref);
	}

	public static function multipartBoundary():String {
		return untyped __elixir__('"--------------------------" <> Integer.to_string(System.unique_integer([:positive, :monotonic]))');
	}

	public static function storeResponseHeaders(ref:Term, pairs:Array<HeaderPair>):Void {
		untyped __elixir__('
            state = Process.get({:reflaxe_sys_http, {0}}, %{headers: %{}, same_key: %{}, file_transfer: nil})

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

                %{acc | headers: Map.put(acc.headers, name, value), same_key: same_key}
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
