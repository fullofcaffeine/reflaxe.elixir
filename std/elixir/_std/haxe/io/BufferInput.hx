package haxe.io;

/**
 * BufferInput (Elixir target)
 *
 * WHAT
 * - Buffered wrapper around another `haxe.io.Input`.
 *
 * WHY
 * - Reduces per-byte reads on slow inputs by reading in chunks.
 *
 * HOW
 * - Maintains an internal `Bytes` buffer and refills via `readBytes`.
 */
class BufferInput extends Input {
	public var i:Input;
	public var buf:Bytes;
	public var available:Int;
	public var pos:Int;

	public function new(i:Input, buf:Bytes, ?pos:Int = 0, ?available:Int = 0) {
		this.i = i;
		this.buf = buf;
		this.pos = pos;
		this.available = available;
	}

	public function refill():Void {
		if (pos > 0) {
			buf.blit(0, buf, pos, available);
			pos = 0;
		}
		available += i.readBytes(buf, available, buf.length - available);
	}

	override function readByte():Int {
		if (available == 0) {
			refill();
		}
		var c = buf.get(pos);
		pos += 1;
		available -= 1;
		return c;
	}

	override function readBytes(buf:Bytes, pos:Int, len:Int):Int {
		if (available == 0) {
			refill();
		}

		var size = if (len > available) available else len;
		buf.blit(pos, this.buf, this.pos, size);
		this.pos += size;
		this.available -= size;
		return size;
	}
}
