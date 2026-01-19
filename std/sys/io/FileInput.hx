package sys.io;

import elixir.types.Term;
import haxe.io.Eof;
import haxe.io.Bytes;

/**
 * sys.io.FileInput (Elixir target)
 *
 * WHAT
 * - BEAM-backed file reader implementing Haxe's `sys.io.FileInput`.
 *
 * WHY
 * - Haxe libraries use `sys.io.File.read(...)` to obtain an input stream.
 * - For Elixir, we map to an Erlang IO device returned by `File.open!/2`.
 *
 * HOW
 * - Uses Erlang `:file.read/2` and `:file.position/2` under the hood.
 * - Throws `haxe.io.Eof` when the end of file is reached (Haxe contract).
 */
class FileInput extends haxe.io.Input {
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

    public function eof(): Bool {
        var result: Term = untyped __elixir__(':file.read({0}, 1)', device);
        var tag: Term = untyped __elixir__('case {0} do
            :eof -> :eof
            {t, _} -> t
        end', result);

        if (untyped __elixir__('{0} == :eof', tag)) {
            return true;
        }

        if (untyped __elixir__('{0} == :ok', tag)) {
            var data: Term = untyped __elixir__('elem({0}, 1)', result);
            untyped __elixir__('{:ok, _} = :file.position({0}, {:cur, -byte_size({1})})', device, data);
            return false;
        }

        var reason: Term = untyped __elixir__('elem({0}, 1)', result);
        throw "File read error: " + untyped __elixir__('inspect({0})', reason);
    }

    override public function readByte(): Int {
        var result: Term = untyped __elixir__(':file.read({0}, 1)', device);
        var tag: Term = untyped __elixir__('case {0} do
            :eof -> :eof
            {t, _} -> t
        end', result);

        if (untyped __elixir__('{0} == :eof', tag)) {
            throw new Eof();
        }

        if (untyped __elixir__('{0} == :ok', tag)) {
            var data: Term = untyped __elixir__('elem({0}, 1)', result);
            // `:file.read/2` returns a binary; for `len=1` it should be exactly 1 byte.
            return untyped __elixir__(':binary.at({0}, 0)', data);
        }

        var reason: Term = untyped __elixir__('elem({0}, 1)', result);
        throw "File read error: " + untyped __elixir__('inspect({0})', reason);
    }

    override public function readBytes(buf: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > buf.length) {
            throw haxe.io.Error.OutsideBounds;
        }

        if (len == 0) return 0;

        var result: Term = untyped __elixir__(':file.read({0}, {1})', device, len);
        var tag: Term = untyped __elixir__('case {0} do
            :eof -> :eof
            {t, _} -> t
        end', result);

        if (untyped __elixir__('{0} == :eof', tag)) {
            throw new Eof();
        }

        if (untyped __elixir__('{0} == :ok', tag)) {
            var data: Term = untyped __elixir__('elem({0}, 1)', result);
            var bytes = Bytes.ofData(data);
            buf.blit(pos, bytes, 0, bytes.length);
            return bytes.length;
        }

        var reason: Term = untyped __elixir__('elem({0}, 1)', result);
        throw "File read error: " + untyped __elixir__('inspect({0})', reason);
    }

    override public function close(): Void {
        untyped __elixir__(':ok = File.close({0})', device);
    }
}
