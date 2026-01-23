package;

import haxe.io.BufferInput;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
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
    static function main() {
        bytesBuffer();
        bytesInputOutput();
        bufferInput();
        fpHelper();
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
}

