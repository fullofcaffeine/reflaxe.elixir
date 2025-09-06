/**
 * Input: Elixir-compatible Input stream implementation
 * 
 * WHY: The standard Haxe Input uses exception handling with typed catch
 * clauses that are incompatible with the Elixir target.
 * 
 * WHAT: A minimal Input implementation that avoids exception-based
 * error handling while maintaining API compatibility.
 * 
 * HOW: Uses return values and null checks instead of exceptions.
 * Essential methods only - extend as needed.
 */
package haxe.io;

import haxe.io.Bytes;

/**
 * An Input is an abstract reader for reading bytes from a stream.
 */
class Input {
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
     * Read one byte from the input stream.
     * Returns -1 if end of stream reached.
     */
    public function readByte(): Int {
        // Override in subclasses
        return -1;
    }
    
    /**
     * Read len bytes from the input stream into the buffer.
     * Returns the number of bytes actually read.
     */
    public function readBytes(b: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > b.length)
            throw "Invalid parameters";
            
        var k = len;
        while (k > 0) {
            var byte = readByte();
            if (byte < 0) {
                // End of stream reached
                break;
            }
            b.set(pos, byte);
            pos++;
            k--;
        }
        return len - k;
    }
    
    /**
     * Read all available bytes from the input stream.
     */
    public function readAll(?bufsize: Int): Bytes {
        if (bufsize == null) bufsize = 4096;
        
        var buf = Bytes.alloc(bufsize);
        var total = Bytes.alloc(0);
        var len = 0;
        
        while (true) {
            var n = readBytes(buf, 0, bufsize);
            if (n == 0) break;
            
            var newTotal = Bytes.alloc(len + n);
            newTotal.blit(0, total, 0, len);
            newTotal.blit(len, buf, 0, n);
            total = newTotal;
            len += n;
        }
        
        return total;
    }
    
    /**
     * Read a string of specified length from the input stream.
     */
    public function readString(len: Int): String {
        var b = Bytes.alloc(len);
        var actual = readBytes(b, 0, len);
        if (actual < len) {
            // Resize buffer to actual bytes read
            var smaller = Bytes.alloc(actual);
            smaller.blit(0, b, 0, actual);
            b = smaller;
        }
        return b.toString();
    }
    
    /**
     * Read a line from the input stream.
     */
    public function readLine(): String {
        var buf = new StringBuf();
        var last: Int;
        while ((last = readByte()) >= 0) {
            if (last == '\n'.code) break;
            if (last != '\r'.code) buf.addChar(last);
        }
        return buf.toString();
    }
    
    /**
     * Close the input stream.
     */
    public function close(): Void {
        // Override in subclasses
    }
}