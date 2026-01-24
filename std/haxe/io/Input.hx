package haxe.io;

import haxe.io.Bytes;

/**
 * Input (Elixir target)
 *
 * WHAT
 * - Target-compatible implementation of Haxe's `haxe.io.Input` base class.
 *
 * WHY
 * - The upstream `haxe.io.Input` assumes a mutable underlying `BytesData`
 *   representation for some targets when reading bytes.
 * - On the Elixir target, `BytesData` is a BEAM binary, so we implement the
 *   core API using `Bytes.get/set` and preserve the standard EOF contract.
 *
 * HOW
 * - `readByte()` remains abstract (implementations throw `Eof` on EOF).
 * - `readBytes()` loops over `readByte()` and catches `Eof` to return partial reads.
 * - Higher-level helpers (`readAll`, `readLine`, numeric reads, etc.) match the
 *   upstream stdlib behavior.
 */
class Input {
    /**
     * Endianness (word byte order) of the stream.
     */
    public var bigEndian(default, set): Bool;
    
    function set_bigEndian(b: Bool): Bool {
        bigEndian = b;
        return b;
    }
    
    /**
     * Read and return one byte.
     */
    public function readByte(): Int {
        throw new haxe.exceptions.NotImplementedException();
    }
    
    /**
     * Read `len` bytes and write them into `s` to the position specified by `pos`.
     *
     * Returns the actual length of read data that can be smaller than `len`.
     *
     * See `readFullBytes` that tries to read the exact amount of specified bytes.
     */
    public function readBytes(s: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > s.length) {
            throw Error.OutsideBounds;
        }

        var k = len;

        try {
            while (k > 0) {
                s.set(pos, readByte());
                pos += 1;
                k -= 1;
            }
        } catch (_: Eof) {}

        return len - k;
    }
    
    public function close(): Void {}

    /* ------------------ API ------------------ */
    /**
     * Read and return all available data.
     *
     * The `bufsize` optional argument specifies the size of chunks by
     * which data is read.
     */
    public function readAll(?bufsize: Int): Bytes {
        if (bufsize == null) {
            bufsize = (1 << 14);
        }

        var buf = Bytes.alloc(bufsize);
        var total = new haxe.io.BytesBuffer();

        try {
            while (true) {
                var len = readBytes(buf, 0, bufsize);
                if (len == 0) {
                    throw Error.Blocked;
                }
                total.addBytes(buf, 0, len);
            }
        } catch (_: Eof) {}

        return total.getBytes();
    }
    
    /**
     * Read `len` bytes and write them into `s` to the position specified by `pos`.
     *
     * Unlike `readBytes`, this method tries to read the exact `len` amount of bytes.
     */
    public function readFullBytes(s: Bytes, pos: Int, len: Int): Void {
        while (len > 0) {
            var k = readBytes(s, pos, len);
            if (k == 0) {
                throw Error.Blocked;
            }
            pos += k;
            len -= k;
        }
    }

    /**
     * Read and return `nbytes` bytes.
     */
    public function read(nbytes: Int): Bytes {
        var s = Bytes.alloc(nbytes);
        var p = 0;
        while (nbytes > 0) {
            var k = readBytes(s, p, nbytes);
            if (k == 0) {
                throw Error.Blocked;
            }
            p += k;
            nbytes -= k;
        }
        return s;
    }

    /**
     * Read a string until a character code specified by `end` is occurred.
     *
     * The final character is not included in the resulting string.
     */
    public function readUntil(end: Int): String {
        var buf = new BytesBuffer();
        var last: Int;
        while ((last = readByte()) != end) {
            buf.addByte(last);
        }
        return buf.getBytes().toString();
    }

    /**
     * Read a line of text separated by CR and/or LF bytes.
     *
     * The CR/LF characters are not included in the resulting string.
     */
    public function readLine(): String {
        var buf = new BytesBuffer();
        var last: Int;
        var s: String;

        try {
            while ((last = readByte()) != 10) {
                buf.addByte(last);
            }
            s = buf.getBytes().toString();
            if (s.charCodeAt(s.length - 1) == 13) {
                s = s.substr(0, -1);
            }
        } catch (e: Eof) {
            s = buf.getBytes().toString();
            if (s.length == 0) {
                throw e;
            }
        }

        return s;
    }

    /**
     * Read a 32-bit floating point number.
     *
     * Endianness is specified by the `bigEndian` property.
     */
    public function readFloat(): Float {
        return FPHelper.i32ToFloat(readInt32());
    }

    /**
     * Read a 64-bit double-precision floating point number.
     *
     * Endianness is specified by the `bigEndian` property.
     */
    public function readDouble(): Float {
        var i1 = readInt32();
        var i2 = readInt32();
        return bigEndian ? FPHelper.i64ToDouble(i2, i1) : FPHelper.i64ToDouble(i1, i2);
    }

    /**
     * Read a 8-bit signed integer.
     */
    public function readInt8(): Int {
        var n = readByte();
        if (n >= 128) return n - 256;
        return n;
    }

    /**
     * Read a 16-bit signed integer.
     *
     * Endianness is specified by the `bigEndian` property.
     */
    public function readInt16(): Int {
        var ch1 = readByte();
        var ch2 = readByte();
        var n = bigEndian ? ch2 | (ch1 << 8) : ch1 | (ch2 << 8);
        if ((n & 0x8000) != 0) return n - 0x10000;
        return n;
    }

    /**
     * Read a 16-bit unsigned integer.
     *
     * Endianness is specified by the `bigEndian` property.
     */
    public function readUInt16(): Int {
        var ch1 = readByte();
        var ch2 = readByte();
        return bigEndian ? ch2 | (ch1 << 8) : ch1 | (ch2 << 8);
    }

    /**
     * Read a 24-bit signed integer.
     *
     * Endianness is specified by the `bigEndian` property.
     */
    public function readInt24(): Int {
        var ch1 = readByte();
        var ch2 = readByte();
        var ch3 = readByte();
        var n = bigEndian ? ch3 | (ch2 << 8) | (ch1 << 16) : ch1 | (ch2 << 8) | (ch3 << 16);
        if ((n & 0x800000) != 0) return n - 0x1000000;
        return n;
    }

    /**
     * Read a 24-bit unsigned integer.
     *
     * Endianness is specified by the `bigEndian` property.
     */
    public function readUInt24(): Int {
        var ch1 = readByte();
        var ch2 = readByte();
        var ch3 = readByte();
        return bigEndian ? ch3 | (ch2 << 8) | (ch1 << 16) : ch1 | (ch2 << 8) | (ch3 << 16);
    }

    /**
     * Read a 32-bit signed integer.
     *
     * Endianness is specified by the `bigEndian` property.
     */
    public function readInt32(): Int {
        var ch1 = readByte();
        var ch2 = readByte();
        var ch3 = readByte();
        var ch4 = readByte();
        return bigEndian ? ch4 | (ch3 << 8) | (ch2 << 16) | (ch1 << 24) : ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
    }

    /**
     * Read `len` bytes as a string.
     */
    public function readString(len: Int, ?encoding: Encoding): String {
        var b = Bytes.alloc(len);
        readFullBytes(b, 0, len);
        return b.getString(0, len, encoding);
    }
}
