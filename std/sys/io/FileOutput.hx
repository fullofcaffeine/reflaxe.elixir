package sys.io;

import elixir.types.Term;
import haxe.io.Bytes;

/**
 * sys.io.FileOutput (Elixir target)
 *
 * WHAT
 * - BEAM-backed file writer implementing Haxe's `sys.io.FileOutput`.
 *
 * WHY
 * - Haxe libraries use `sys.io.File.write/append/update` to obtain output streams.
 *
 * HOW
 * - Uses Erlang `:file.write/2` and `:file.position/2` against the underlying
 *   IO device returned by `File.open!/2`.
 */
class FileOutput extends haxe.io.Output {
    final device: Term;

    public function new(device: Term) {
        this.device = device;
    }

    public function seek(p: Int, pos: FileSeek): Void {
        switch (pos) {
            case SeekBegin:
                untyped __elixir__('{:ok, _} = :file.position({0}, {:bof, {1}})', device, p);
            case SeekCur:
                untyped __elixir__('{:ok, _} = :file.position({0}, {:cur, {1}})', device, p);
            case SeekEnd:
                untyped __elixir__('{:ok, _} = :file.position({0}, {:eof, {1}})', device, p);
        }
    }

    public function tell(): Int {
        return untyped __elixir__('case :file.position({0}, :cur) do {:ok, p} -> p end', device);
    }

    override public function writeByte(c: Int): Void {
        untyped __elixir__(':ok = :file.write({0}, <<{1}::8>>)', device, c);
    }

    override public function writeBytes(b: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > b.length) {
            throw haxe.io.Error.OutsideBounds;
        }
        if (len == 0) return 0;

        var slice = b.sub(pos, len).getData();
        untyped __elixir__(':ok = :file.write({0}, {1})', device, slice);
        return len;
    }

    override public function close(): Void {
        untyped __elixir__(':ok = File.close({0})', device);
    }
}
