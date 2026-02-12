package haxe.io;

import elixir.types.Term;

private typedef BytesInputState = {
	var pos:Int;
	var remaining:Int;
};

/**
 * BytesInput (Elixir target)
 *
 * WHAT
 * - In-memory `haxe.io.Input` backed by `haxe.io.Bytes`.
 *
 * WHY
 * - Common building block for decoders/parsers that expect Haxe's `Input` API.
 *
 * HOW
 * - Stores an Elixir sub-binary slice so `position` is relative to the stream.
 * - Uses `:binary.at/2` and `:binary.part/3` for efficient reads.
 * - Persists cursor state (`pos`, `remaining`) in the process dictionary keyed by a unique reference,
 *   because instance field updates are immutable and not automatically threaded through callers.
 */
class BytesInput extends Input {
	final data:BytesData;
	var totalLength:Int;
	final refId:Int;
	final dictKey:Term;

	/** The current position in the stream in bytes (0..length). */
	public var position(get, set):Int;

	/** The length of the stream in bytes. */
	public var length(get, never):Int;

	inline function getState():BytesInputState {
		var state:Null<BytesInputState> = untyped __elixir__("Process.get({0})", dictKey);
		if (state == null) {
			// Cross-process use (or manual state deletion) loses the process dictionary entry.
			// Fall back to a safe default that preserves invariants.
			state = {pos: 0, remaining: totalLength};
			untyped __elixir__("Process.put({0}, {1})", dictKey, state);
		}
		return state;
	}

	inline function putState(state:BytesInputState):Void {
		untyped __elixir__("Process.put({0}, {1})", dictKey, state);
	}

	public function new(bytes:Bytes, ?pos:Int, ?len:Int) {
		pos = (pos == null) ? 0 : pos;
		len = (len == null) ? (bytes.length - pos) : len;

		if (pos < 0 || len < 0 || pos + len > bytes.length) {
			throw Error.OutsideBounds;
		}

		// Keep stream-relative positions by slicing the underlying binary.
		data = untyped __elixir__(":binary.part({0}, {1}, {2})", bytes.getData(), pos, len);

		this.totalLength = len;
		this.refId = untyped __elixir__(":erlang.unique_integer([:positive])");
		this.dictKey = untyped __elixir__("{:reflaxe_bytes_input, {0}}", refId);
		putState({pos: 0, remaining: len});
	}

	inline function get_position():Int {
		return getState().pos;
	}

	inline function get_length():Int {
		return totalLength;
	}

	function set_position(p:Int):Int {
		if (p < 0)
			p = 0;
		else if (p > totalLength)
			p = totalLength;

		var state = getState();
		state.remaining = totalLength - p;
		state.pos = p;
		putState(state);
		return state.pos;
	}

	public override function readByte():Int {
		var state = getState();
		if (state.remaining == 0) {
			throw new Eof();
		}
		var currentPos = state.pos;
		state.remaining -= 1;
		state.pos = currentPos + 1;
		putState(state);
		return untyped __elixir__(":binary.at({0}, {1})", data, currentPos);
	}

	public override function readBytes(buf:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > buf.length) {
			throw Error.OutsideBounds;
		}
		if (len == 0)
			return 0;

		var state = getState();
		if (state.remaining == 0) {
			throw new Eof();
		}

		if (len > state.remaining) {
			len = state.remaining;
		}

		var slice = untyped __elixir__(":binary.part({0}, {1}, {2})", data, state.pos, len);
		var src = Bytes.ofData(slice);
		buf.blit(pos, src, 0, len);

		state.pos += len;
		state.remaining -= len;
		putState(state);
		return len;
	}

	public override function readAll(?bufsize:Int):Bytes {
		var state = getState();
		if (state.remaining == 0) {
			return Bytes.alloc(0);
		}

		var slice:BytesData = untyped __elixir__(":binary.part({0}, {1}, {2})", data, state.pos, state.remaining);
		state.pos += state.remaining;
		state.remaining = 0;
		putState(state);
		return Bytes.ofData(slice);
	}

	public override function readLine():String {
		var state = getState();
		if (state.remaining == 0) {
			throw new Eof();
		}

		var result:Term = untyped __elixir__("(fn ->\n  rem = :binary.part({0}, {1}, {2})\n  case :binary.match(rem, \"\\n\") do\n    :nomatch -> {rem, byte_size(rem)}\n    {idx, _} ->\n      line_len = if idx > 0 and :binary.at(rem, idx - 1) == 13, do: idx - 1, else: idx\n      {:binary.part(rem, 0, line_len), idx + 1}\n  end\nend).()",
			data, state.pos, state.remaining);

		var line:BytesData = untyped __elixir__("elem({0}, 0)", result);
		var advance:Int = untyped __elixir__("elem({0}, 1)", result);
		state.pos += advance;
		state.remaining -= advance;
		putState(state);

		return untyped __elixir__("{0}", line);
	}

	public override function close():Void {
		untyped __elixir__("Process.delete({0})", dictKey);
	}
}
