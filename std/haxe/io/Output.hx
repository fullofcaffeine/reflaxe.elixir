/**
 * Output: Elixir-compatible Output stream implementation
 * 
 * WHY: The standard Haxe Output uses exception handling with typed catch
 * clauses that are incompatible with the Elixir target.
 * 
 * WHAT: A minimal Output implementation that avoids exception-based
 * error handling while maintaining API compatibility.
 * 
 * HOW: Uses return values instead of exceptions for error handling.
 * Essential methods only - extend as needed.
 */
package haxe.io;

import haxe.io.Bytes;

/**
 * An Output is an abstract writer for writing bytes to a stream.
 */
class Output {
    /**
     * Endianness (word byte order) of the stream.
     */
    public var bigEndian(default, set): Bool;
    
    function set_bigEndian(b: Bool): Bool {
        // In Elixir, we need to return the value being set
        // The actual struct update will be handled by the compiler
        return b;
    }
    
    /**
     * Write one byte to the output stream.
     */
    public function writeByte(c: Int): Void {
        // Override in subclasses
    }
    
    /**
     * Write len bytes from the buffer to the output stream.
     * Returns the number of bytes actually written.
     */
    public function writeBytes(b: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > b.length)
            throw "Invalid parameters";
            
        var k = len;
        while (k > 0) {
            writeByte(b.get(pos));
            pos = pos + 1;
            k = k - 1;
        }
        return len;
    }
    
    /**
     * Write all bytes from the buffer to the output stream.
     */
    public function write(b: Bytes): Void {
        writeBytes(b, 0, b.length);
    }
    
    /**
     * Write all bytes from the input stream to this output.
     */
    public function writeInput(i: Input, ?bufsize: Int): Void {
        if (bufsize == null) bufsize = 4096;
        var buf = Bytes.alloc(bufsize);
        while (true) {
            var len = i.readBytes(buf, 0, bufsize);
            if (len == 0) break;
            writeBytes(buf, 0, len);
        }
    }
    
    /**
     * Write a string to the output stream.
     */
    public function writeString(s: String): Void {
        var b = Bytes.ofString(s, null);
        write(b);
    }
    
    /**
     * Flush the output buffer if any.
     */
    public function flush(): Void {
        // Override in subclasses if buffering is used
    }
    
    /**
     * Close the output stream.
     */
    public function close(): Void {
        // Override in subclasses
    }
}
