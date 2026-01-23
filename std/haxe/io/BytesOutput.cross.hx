package haxe.io;

/**
 * BytesOutput (Elixir target)
 *
 * WHAT
 * - In-memory `haxe.io.Output` that writes to a `haxe.io.BytesBuffer`.
 *
 * WHY
 * - Enables encoders/serializers to target a `Bytes` buffer using the standard API.
 *
 * HOW
 * - Delegates to `BytesBuffer` which is iodata-backed for O(n) total build cost.
 */
class BytesOutput extends Output {
    var buffer: BytesBuffer;

    /** The length of the stream in bytes. **/
    public var length(get, never): Int;

    public function new() {
        buffer = new BytesBuffer();
    }

    inline function get_length(): Int {
        return buffer.length;
    }

    override function writeByte(c: Int): Void {
        buffer.addByte(c);
    }

    override function writeBytes(buf: Bytes, pos: Int, len: Int): Int {
        buffer.addBytes(buf, pos, len);
        return len;
    }

    /**
     * Returns the `Bytes` of this output.
     *
     * This function should not be called more than once on a given instance.
     */
    public function getBytes(): Bytes {
        var current = buffer;
        buffer = null;
        return current.getBytes();
    }
}

