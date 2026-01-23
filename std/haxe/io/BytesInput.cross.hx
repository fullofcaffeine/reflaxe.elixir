package haxe.io;

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
 */
class BytesInput extends Input {
    final data: BytesData;
    var pos: Int;
    var remaining: Int;
    var totalLength: Int;

    /** The current position in the stream in bytes (0..length). */
    public var position(get, set): Int;

    /** The length of the stream in bytes. */
    public var length(get, never): Int;

    public function new(bytes: Bytes, ?pos: Int, ?len: Int) {
        if (pos == null) pos = 0;
        if (len == null) len = bytes.length - pos;

        if (pos < 0 || len < 0 || pos + len > bytes.length) {
            throw Error.OutsideBounds;
        }

        // Keep stream-relative positions by slicing the underlying binary.
        data = untyped __elixir__(":binary.part({0}, {1}, {2})", bytes.getData(), pos, len);

        this.pos = 0;
        this.remaining = len;
        this.totalLength = len;
    }

    inline function get_position(): Int {
        return pos;
    }

    inline function get_length(): Int {
        return totalLength;
    }

    function set_position(p: Int): Int {
        if (p < 0) p = 0;
        else if (p > totalLength) p = totalLength;

        remaining = totalLength - p;
        pos = p;
        return pos;
    }

    public override function readByte(): Int {
        if (remaining == 0) {
            throw new Eof();
        }
        remaining -= 1;
        var value = untyped __elixir__(":binary.at({0}, {1})", data, pos);
        pos += 1;
        return value;
    }

    public override function readBytes(buf: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > buf.length) {
            throw Error.OutsideBounds;
        }
        if (len == 0) return 0;

        if (remaining == 0) {
            throw new Eof();
        }

        if (len > remaining) {
            len = remaining;
        }

        var slice = untyped __elixir__(":binary.part({0}, {1}, {2})", data, this.pos, len);
        var src = Bytes.ofData(slice);
        buf.blit(pos, src, 0, len);

        this.pos += len;
        remaining -= len;
        return len;
    }
}

