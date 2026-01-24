package;

import haxe.io.BufferInput;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.io.FPHelper;

/**
 * Snapshot: haxe.io bytes IO building blocks
 *
 * Exercises:
 * - BytesBuffer (iodata builder)
 * - BytesInput / BytesOutput
 * - BufferInput
 * - FPHelper IEEE754 conversions
 */
class Main {
    static function assertThat(condition: Bool, message: String): Void {
        if (!condition) {
            throw message;
        }
    }

    static function main() {
        bytesBuffer();
        bytesInputOutput();
        bufferInput();
        fpHelper();
        ioSemantics();
    }

    static function bytesBuffer() {
        var buffer = new BytesBuffer();
        buffer.addByte('A'.code);
        buffer.addString("BC");
        buffer.addInt32(0x01020304);
        buffer.addFloat(1.5);
        buffer.addDouble(3.25);

        var bytes = buffer.getBytes();
        trace(bytes.length);
        trace(bytes.get(0));
    }

    static function bytesInputOutput() {
        var out = new BytesOutput();
        out.writeByte(0);
        out.writeString("hi");
        var bytes = out.getBytes();

        var input = new BytesInput(bytes);
        var first = input.readByte();
        var tmp = Bytes.alloc(2);
        input.readBytes(tmp, 0, 2);

        trace(first);
        trace(tmp.toString());
    }

    static function bufferInput() {
        var bytes = Bytes.ofString("hello");
        var base = new BytesInput(bytes);
        var buf = Bytes.alloc(2);
        var buffered = new BufferInput(base, buf);

        trace(buffered.readByte());
    }

    static function fpHelper() {
        var bits = FPHelper.floatToI32(1.0);
        var value = FPHelper.i32ToFloat(bits);
        trace(value);

        var bits64 = FPHelper.doubleToI64(1.0);
        trace(bits64);
    }

    /**
     * Runtime IO semantics smoke
     *
     * This test intentionally executes critical stdlib paths at runtime (via `Main.main/0`)
     * to validate behavior on BEAM beyond snapshot output shape.
     *
     * Covers:
     * - Input.readAll: reads complete content with chunking
     * - Input.readLine: CRLF + LF handling and EOF contract
     * - Output.writeInput: copies full content
     * - Output.writeDouble/Input.readDouble: roundtrip via FPHelper.doubleToI64 and Int64 access
     */
    static function ioSemantics() {
        // readAll: chunked read
        var allInput = new BytesInput(Bytes.ofString("hello"));
        var all = allInput.readAll(2).toString();
        assertThat(all == "hello", "readAll chunked failed");

        // readLine: CRLF and LF + EOF contract
        var lineInput = new BytesInput(Bytes.ofString("a\r\nb\n"));
        assertThat(lineInput.readLine() == "a", "readLine CRLF failed");
        assertThat(lineInput.readLine() == "b", "readLine LF failed");
        try {
            lineInput.readLine();
            assertThat(false, "readLine should throw Eof on empty input");
        } catch (_: Eof) {}

        // writeInput: stream copy
        var src = new BytesInput(Bytes.ofString("xyz"));
        var sink = new BytesOutput();
        sink.writeInput(src, 2);
        assertThat(sink.getBytes().toString() == "xyz", "writeInput failed");

        // writeDouble/readDouble: roundtrip
        var out = new BytesOutput();
        out.bigEndian = false;
        out.writeDouble(3.25);
        var bytes = out.getBytes();
        assertThat(bytes.length == 8, "writeDouble length should be 8");

        var inp = new BytesInput(bytes);
        inp.bigEndian = false;
        var got = inp.readDouble();
        assertThat(Math.abs(got - 3.25) < 1e-12, "double roundtrip failed");
    }
}
