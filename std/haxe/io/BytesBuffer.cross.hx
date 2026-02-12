package haxe.io;

import elixir.types.Term;

/**
 * BytesBuffer (Elixir target)
 *
 * WHAT
 * - Efficient byte accumulator compatible with Haxe `haxe.io.BytesBuffer`.
 *
 * WHY
 * - Elixir binaries are immutable; repeated `<>` concatenation is O(n²).
 * - BEAM provides iodata for efficient incremental building.
 *
 * HOW
 * - Accumulate bytes/binaries into a reversed iodata list.
 * - Convert once at `getBytes()` via `:erlang.iolist_to_binary/1`.
 */
class BytesBuffer {
	var partsReversed:Term;
	var byteLength:Int;

	/** The length of the buffer in bytes. **/
	public var length(get, never):Int;

	public function new() {
		partsReversed = untyped __elixir__("[]");
		byteLength = 0;
	}

	inline function get_length():Int {
		return byteLength;
	}

	public inline function addByte(byte:Int):Void {
		partsReversed = untyped __elixir__("[{0} | {1}]", byte, partsReversed);
		byteLength += 1;
	}

	public inline function add(src:Bytes):Void {
		if (src.length == 0)
			return;
		partsReversed = untyped __elixir__("[{0} | {1}]", src.getData(), partsReversed);
		byteLength += src.length;
	}

	public inline function addString(v:String, ?encoding:Encoding):Void {
		add(Bytes.ofString(v, encoding));
	}

	public inline function addInt32(v:Int):Void {
		partsReversed = untyped __elixir__("[<<{0}::little-signed-size(32)>> | {1}]", v, partsReversed);
		byteLength += 4;
	}

	public inline function addInt64(v:haxe.Int64):Void {
		partsReversed = untyped __elixir__("[<<{0}::little-signed-size(64)>> | {1}]", v, partsReversed);
		byteLength += 8;
	}

	public inline function addFloat(v:Float):Void {
		partsReversed = untyped __elixir__("[<<{0}::float-little-size(32)>> | {1}]", v, partsReversed);
		byteLength += 4;
	}

	public inline function addDouble(v:Float):Void {
		partsReversed = untyped __elixir__("[<<{0}::float-little-size(64)>> | {1}]", v, partsReversed);
		byteLength += 8;
	}

	public inline function addBytes(src:Bytes, pos:Int, len:Int):Void {
		if (pos < 0 || len < 0 || pos + len > src.length) {
			throw Error.OutsideBounds;
		}
		if (len == 0)
			return;

		var slice = untyped __elixir__(":binary.part({0}, {1}, {2})", src.getData(), pos, len);
		partsReversed = untyped __elixir__("[{0} | {1}]", slice, partsReversed);
		byteLength += len;
	}

	/**
	 * Returns either a copy or a reference of the current bytes.
	 * Once called, the buffer should no longer be used.
	 */
	public function getBytes():Bytes {
		var reversed = partsReversed;
		partsReversed = null;
		byteLength = 0;

		var binary = untyped __elixir__(":erlang.iolist_to_binary(:lists.reverse({0}))", reversed);
		return Bytes.ofData(binary);
	}
}
