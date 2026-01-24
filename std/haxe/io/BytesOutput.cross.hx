package haxe.io;

import elixir.types.Term;

private typedef BytesOutputState = {
    var partsReversed: Term;
    var byteLength: Int;
};

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
 * - Persists buffer state in the process dictionary keyed by a unique reference, so callers
 *   do not need to thread updated instance structs through imperative APIs like `writeBytes`.
 */
class BytesOutput extends Output {
    final refId: Int;
    final dictKey: Term;

    /** The length of the stream in bytes. **/
    public var length(get, never): Int;

    public function new() {
        refId = untyped __elixir__(":erlang.unique_integer([:positive])");
        dictKey = untyped __elixir__("{:reflaxe_bytes_output, {0}}", refId);
        putState({partsReversed: untyped __elixir__("[]"), byteLength: 0});
    }

    inline function get_length(): Int {
        return getState().byteLength;
    }

    inline function getState(): BytesOutputState {
        var state: Null<BytesOutputState> = untyped __elixir__("Process.get({0})", dictKey);
        if (state == null) {
            state = {partsReversed: untyped __elixir__("[]"), byteLength: 0};
            untyped __elixir__("Process.put({0}, {1})", dictKey, state);
        }
        return state;
    }

    inline function putState(state: BytesOutputState): Void {
        untyped __elixir__("Process.put({0}, {1})", dictKey, state);
    }

    override function writeByte(c: Int): Void {
        var state = getState();
        state.partsReversed = untyped __elixir__("[{0} | {1}]", c, state.partsReversed);
        state.byteLength += 1;
        putState(state);
    }

    override function writeBytes(buf: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > buf.length) {
            throw Error.OutsideBounds;
        }
        if (len == 0) return 0;

        var slice = untyped __elixir__(":binary.part({0}, {1}, {2})", buf.getData(), pos, len);
        var state = getState();
        state.partsReversed = untyped __elixir__("[{0} | {1}]", slice, state.partsReversed);
        state.byteLength += len;
        putState(state);
        return len;
    }

    public override function writeInput(i: Input, ?bufsize: Int): Void {
        var bytes = i.readAll(bufsize);
        if (bytes.length > 0) {
            writeBytes(bytes, 0, bytes.length);
        }
    }

    /**
     * Returns the `Bytes` of this output.
     *
     * This function should not be called more than once on a given instance.
     */
    public function getBytes(): Bytes {
        var state = getState();
        // Enforce the "only once" contract by clearing state eagerly.
        untyped __elixir__("Process.delete({0})", dictKey);
        var binary: BytesData = untyped __elixir__(":erlang.iolist_to_binary(:lists.reverse({0}))", state.partsReversed);
        return Bytes.ofData(binary);
    }
}
