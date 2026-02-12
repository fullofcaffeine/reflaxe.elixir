package haxe.io;

import haxe.io.Bytes;

/**
 * Output (Elixir target)
 *
 * WHAT
 * - Target-compatible implementation of Haxe's `haxe.io.Output` base class.
 *
 * WHY
 * - The upstream `haxe.io.Output` assumes a mutable underlying `BytesData`
 *   representation for some targets when writing bytes.
 * - On the Elixir target, `BytesData` is a BEAM binary, so we implement the
 *   core API using `Bytes.get` and preserve standard Haxe semantics.
 *
 * HOW
 * - `writeByte()` remains abstract.
 * - `writeBytes()` loops over `writeByte()` and validates bounds.
 * - Higher-level helpers (`write`, numeric writes, `writeInput`, etc.) match
 *   the upstream stdlib behavior.
 */
class Output {
	/**
	 * Endianness (word byte order) of the stream.
	 */
	public var bigEndian(default, set):Bool;

	function set_bigEndian(b:Bool):Bool {
		bigEndian = b;
		return b;
	}

	/**
	 * Write one byte to the output stream.
	 */
	public function writeByte(c:Int):Void {
		throw new haxe.exceptions.NotImplementedException();
	}

	/**
	 * Write `len` bytes from `s` starting by position specified by `pos`.
	 *
	 * Returns the actual length of written data that can differ from `len`.
	 *
	 * See `writeFullBytes` that tries to write the exact amount of specified bytes.
	 */
	public function writeBytes(s:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > s.length) {
			throw Error.OutsideBounds;
		}

		var k = len;
		while (k > 0) {
			writeByte(s.get(pos));
			pos += 1;
			k -= 1;
		}
		return len;
	}

	/**
	 * Flush any buffered data.
	 */
	public function flush():Void {}

	/**
	 * Close the output stream.
	 */
	public function close():Void {}

	/* ------------------ API ------------------ */
	/**
	 * Write all bytes stored in `s`.
	 */
	public function write(s:Bytes):Void {
		var l = s.length;
		var p = 0;
		while (l > 0) {
			var k = writeBytes(s, p, l);
			if (k == 0) {
				throw Error.Blocked;
			}
			p += k;
			l -= k;
		}
	}

	/**
	 * Write `len` bytes from `s` starting by position specified by `pos`.
	 *
	 * Unlike `writeBytes`, this method tries to write the exact `len` amount of bytes.
	 */
	public function writeFullBytes(s:Bytes, pos:Int, len:Int):Void {
		while (len > 0) {
			var k = writeBytes(s, pos, len);
			pos += k;
			len -= k;
		}
	}

	/**
	 * Write `x` as 32-bit floating point number.
	 *
	 * Endianness is specified by the `bigEndian` property.
	 */
	public function writeFloat(x:Float):Void {
		writeInt32(FPHelper.floatToI32(x));
	}

	/**
	 * Write `x` as 64-bit double-precision floating point number.
	 *
	 * Endianness is specified by the `bigEndian` property.
	 */
	public function writeDouble(x:Float):Void {
		var i64 = FPHelper.doubleToI64(x);
		if (bigEndian) {
			writeInt32(i64.high);
			writeInt32(i64.low);
		} else {
			writeInt32(i64.low);
			writeInt32(i64.high);
		}
	}

	/**
	 * Write `x` as 8-bit signed integer.
	 */
	public function writeInt8(x:Int):Void {
		if (x < -0x80 || x >= 0x80) {
			throw Error.Overflow;
		}
		writeByte(x & 0xFF);
	}

	/**
	 * Write `x` as 16-bit signed integer.
	 *
	 * Endianness is specified by the `bigEndian` property.
	 */
	public function writeInt16(x:Int):Void {
		if (x < -0x8000 || x >= 0x8000) {
			throw Error.Overflow;
		}
		writeUInt16(x & 0xFFFF);
	}

	/**
	 * Write `x` as 16-bit unsigned integer.
	 *
	 * Endianness is specified by the `bigEndian` property.
	 */
	public function writeUInt16(x:Int):Void {
		if (x < 0 || x >= 0x10000) {
			throw Error.Overflow;
		}
		if (bigEndian) {
			writeByte(x >> 8);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte(x >> 8);
		}
	}

	/**
	 * Write `x` as 24-bit signed integer.
	 *
	 * Endianness is specified by the `bigEndian` property.
	 */
	public function writeInt24(x:Int):Void {
		if (x < -0x800000 || x >= 0x800000) {
			throw Error.Overflow;
		}
		writeUInt24(x & 0xFFFFFF);
	}

	/**
	 * Write `x` as 24-bit unsigned integer.
	 *
	 * Endianness is specified by the `bigEndian` property.
	 */
	public function writeUInt24(x:Int):Void {
		if (x < 0 || x >= 0x1000000) {
			throw Error.Overflow;
		}
		if (bigEndian) {
			writeByte(x >> 16);
			writeByte((x >> 8) & 0xFF);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte(x >> 16);
		}
	}

	/**
	 * Write `x` as 32-bit signed integer.
	 *
	 * Endianness is specified by the `bigEndian` property.
	 */
	public function writeInt32(x:Int):Void {
		if (bigEndian) {
			writeByte(x >>> 24);
			writeByte((x >> 16) & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte((x >> 16) & 0xFF);
			writeByte(x >>> 24);
		}
	}

	/**
	 * Inform that we are about to write at least `nbytes` bytes.
	 *
	 * The underlying implementation can allocate proper working space depending
	 * on this information, or simply ignore it.
	 */
	public function prepare(nbytes:Int):Void {}

	/**
	 * Read all available data from `i` and write it.
	 *
	 * The `bufsize` optional argument specifies the size of chunks by
	 * which data is read and written. Its default value is 4096.
	 */
	public function writeInput(i:Input, ?bufsize:Int):Void {
		if (bufsize == null)
			bufsize = 4096;
		var buf = Bytes.alloc(bufsize);
		while (true) {
			try {
				var len = i.readBytes(buf, 0, bufsize);
				if (len == 0) {
					throw Error.Blocked;
				}

				var p = 0;
				while (len > 0) {
					var k = writeBytes(buf, p, len);
					if (k == 0) {
						throw Error.Blocked;
					}
					p += k;
					len -= k;
				}
			} catch (_:Eof) {
				break;
			}
		}
	}

	/**
	 * Write `s` string.
	 */
	public function writeString(s:String, ?encoding:Encoding):Void {
		var b = Bytes.ofString(s, encoding);
		writeFullBytes(b, 0, b.length);
	}
}
