package haxe.http;

import elixir.types.Term;
import haxe.io.Bytes;

private typedef StringKeyValue = {
	var name:String;
	var value:String;
};

/**
 * haxe.http.HttpBase (Elixir target)
 *
 * WHAT
 * - Local source-of-truth for the callback/state contract shared by `haxe.Http`
 *   and `sys.Http`.
 *
 * WHY
 * - Generated Elixir structs are immutable. Haxe's `HttpBase` API is intentionally
 *   mutating (`setHeader`, `setParameter`, `setPostData`, `responseBytes`, etc.),
 *   so state must live behind a stable BEAM reference rather than only in fields.
 *
 * HOW
 * - Each instance owns `httpBaseRef`.
 * - Mutable request/response state is stored in the process dictionary.
 * - Callbacks are initialized as Haxe function fields so user assignments have
 *   stable keys in the generated Elixir struct.
 */
class HttpBase {
	public var url:String;
	public var responseData(get, never):Null<String>;
	public var responseBytes(get, never):Null<Bytes>;
	public var onData:String->Void;
	public var onBytes:Bytes->Void;
	public var onError:String->Void;
	public var onStatus:Int->Void;

	@:noCompletion public var httpBaseRef(default, null):Term;

	public function new(url:String) {
		this.url = url;
		httpBaseRef = HttpBaseRuntime.create();
		onData = defaultOnData;
		onBytes = defaultOnBytes;
		onError = defaultOnError;
		onStatus = defaultOnStatus;
	}

	public function setHeader(name:String, value:String):Void {
		HttpBaseRuntime.setHeader(httpBaseRef, name, value);
	}

	public function addHeader(header:String, value:String):Void {
		HttpBaseRuntime.addHeader(httpBaseRef, header, value);
	}

	public function setParameter(name:String, value:String):Void {
		HttpBaseRuntime.setParameter(httpBaseRef, name, value);
	}

	public function addParameter(name:String, value:String):Void {
		HttpBaseRuntime.addParameter(httpBaseRef, name, value);
	}

	public function setPostData(data:Null<String>):Void {
		HttpBaseRuntime.setPostData(httpBaseRef, data);
	}

	public function setPostBytes(data:Null<Bytes>):Void {
		HttpBaseRuntime.setPostBytes(httpBaseRef, data);
	}

	public function request(?post:Bool):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	public function success(data:Bytes):Void {
		HttpBaseRuntime.setResponseBytes(httpBaseRef, data);
		HttpBaseRuntime.callOnData(this, responseData);
		HttpBaseRuntime.callOnBytes(this, data);
	}

	@:noCompletion public function on_data(data:String):Void {
		HttpBaseRuntime.callOnData(this, data);
	}

	@:noCompletion public function on_bytes(data:Bytes):Void {
		HttpBaseRuntime.callOnBytes(this, data);
	}

	@:noCompletion public function on_error(msg:String):Void {
		HttpBaseRuntime.callOnError(this, msg);
	}

	@:noCompletion public function on_status(status:Int):Void {
		HttpBaseRuntime.callOnStatus(this, status);
	}

	function get_responseBytes():Null<Bytes> {
		return HttpBaseRuntime.responseBytes(httpBaseRef);
	}

	function get_responseData():Null<String> {
		var bytes = responseBytes;
		if (bytes == null)
			return null;
		return bytes.getString(0, bytes.length, UTF8);
	}

	static function defaultOnData(data:String):Void {}

	static function defaultOnBytes(data:Bytes):Void {}

	static function defaultOnError(msg:String):Void {}

	static function defaultOnStatus(status:Int):Void {}
}

@:noCompletion
class HttpBaseRuntime {
	public static function create():Term {
		return untyped __elixir__('
            (fn ->
              ref = make_ref()
              Process.put({:reflaxe_http_base, ref}, %{
                headers: [],
                params: [],
                post_data: nil,
                post_bytes: nil,
                response_bytes: nil,
                failed: false,
                last_error: nil
              })
              ref
            end).()
        ');
	}

	public static function resetResponse(ref:Term):Void {
		untyped __elixir__('
            key = {:reflaxe_http_base, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | response_bytes: nil, failed: false, last_error: nil})
            :ok
        ', ref);
	}

	public static function setHeader(ref:Term, name:String, value:String):Void {
		updatePair(ref, untyped __elixir__(':headers'), name, value, true);
	}

	public static function addHeader(ref:Term, name:String, value:String):Void {
		updatePair(ref, untyped __elixir__(':headers'), name, value, false);
	}

	public static function setParameter(ref:Term, name:String, value:String):Void {
		updatePair(ref, untyped __elixir__(':params'), name, value, true);
	}

	public static function addParameter(ref:Term, name:String, value:String):Void {
		updatePair(ref, untyped __elixir__(':params'), name, value, false);
	}

	static function updatePair(ref:Term, field:Term, name:String, value:String, replace:Bool):Void {
		untyped __elixir__('
            key = {:reflaxe_http_base, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            pair = {{2}, {3}}
            pairs = Map.fetch!(state, {1})

            next_pairs =
              if {4} do
                {replaced, reversed} =
                  Enum.reduce(pairs, {false, []}, fn {existing_name, existing_value}, {found, acc} ->
                    if existing_name == {2} and not found do
                      {true, [pair | acc]}
                    else
                      {found, [{existing_name, existing_value} | acc]}
                    end
                  end)

                if replaced, do: Enum.reverse(reversed), else: pairs ++ [pair]
              else
                pairs ++ [pair]
              end

            Process.put(key, Map.put(state, {1}, next_pairs))
            :ok
        ', ref, field, name, value, replace);
	}

	public static function headers(ref:Term):Array<StringKeyValue> {
		return cast untyped __elixir__('
            Process.get({:reflaxe_http_base, {0}}).headers
            |> Enum.map(fn {name, value} -> %{name: name, value: value} end)
        ', ref);
	}

	public static function headerPairs(ref:Term):Array<{_0:String, _1:String}> {
		return cast untyped __elixir__('Process.get({:reflaxe_http_base, {0}}).headers', ref);
	}

	public static function headerValue(ref:Term, name:String):Null<String> {
		return untyped __elixir__('
            expected = String.downcase({1})
            Process.get({:reflaxe_http_base, {0}}).headers
            |> Enum.find_value(fn {header_name, header_value} ->
              if String.downcase(header_name) == expected, do: header_value, else: nil
            end)
        ', ref, name);
	}

	public static function encodedParams(ref:Term):String {
		return untyped __elixir__('
            Process.get({:reflaxe_http_base, {0}}).params
            |> Enum.map_join("&", fn {name, value} ->
              URI.encode(name) <> "=" <> URI.encode(value)
            end)
        ', ref);
	}

	public static function setPostData(ref:Term, data:Null<String>):Void {
		untyped __elixir__('
            key = {:reflaxe_http_base, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | post_data: {1}, post_bytes: nil})
            :ok
        ', ref, data);
	}

	public static function setPostBytes(ref:Term, data:Null<Bytes>):Void {
		untyped __elixir__('
            key = {:reflaxe_http_base, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            post_bytes =
              case {1} do
                nil -> nil
                bytes -> bytes
              end
            Process.put(key, %{state | post_data: nil, post_bytes: post_bytes})
            :ok
        ', ref, data);
	}

	public static function hasRequestBody(ref:Term):Bool {
		return untyped __elixir__('
            state = Process.get({:reflaxe_http_base, {0}})
            not is_nil(state.post_data) or not is_nil(state.post_bytes)
        ', ref);
	}

	public static function takePostData(ref:Term):Null<String> {
		return untyped __elixir__('
            key = {:reflaxe_http_base, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            value = state.post_data
            Process.put(key, %{state | post_data: nil})
            value
        ', ref);
	}

	public static function postBytes(ref:Term):Null<Bytes> {
		return cast untyped __elixir__('Process.get({:reflaxe_http_base, {0}}).post_bytes', ref);
	}

	public static function setResponseBytes(ref:Term, bytes:Bytes):Void {
		untyped __elixir__('
            key = {:reflaxe_http_base, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | response_bytes: {1}})
            :ok
        ', ref, bytes);
	}

	public static function responseBytes(ref:Term):Null<Bytes> {
		return cast untyped __elixir__('Process.get({:reflaxe_http_base, {0}}).response_bytes', ref);
	}

	public static function markFailed(ref:Term, message:String):Void {
		untyped __elixir__('
            key = {:reflaxe_http_base, {0}}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | failed: true, last_error: {1}})
            :ok
        ', ref, message);
	}

	public static function failed(ref:Term):Bool {
		return untyped __elixir__('Process.get({:reflaxe_http_base, {0}}).failed', ref);
	}

	public static function lastError(ref:Term):Null<String> {
		return untyped __elixir__('Process.get({:reflaxe_http_base, {0}}).last_error', ref);
	}

	public static function callOnData(owner:HttpBase, data:String):Void {
		untyped __elixir__('Map.fetch!({0}, :on_data).({1})', owner, data);
	}

	public static function callOnBytes(owner:HttpBase, data:Bytes):Void {
		untyped __elixir__('Map.fetch!({0}, :on_bytes).({1})', owner, data);
	}

	public static function callOnError(owner:HttpBase, message:String):Void {
		untyped __elixir__('Map.fetch!({0}, :on_error).({1})', owner, message);
	}

	public static function callOnStatus(owner:HttpBase, status:Int):Void {
		untyped __elixir__('Map.fetch!({0}, :on_status).({1})', owner, status);
	}
}
