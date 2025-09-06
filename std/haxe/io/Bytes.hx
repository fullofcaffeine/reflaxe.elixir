package haxe.io;

/**
 * Bytes: Elixir-optimized implementation of Haxe's Bytes class
 * 
 * WHY: Haxe's built-in Bytes.hx uses inline functions that generate problematic
 * assignment patterns like `c = index = s.cca(i = i + 1)` which are invalid in Elixir.
 * This implementation provides the same API but generates clean, idiomatic Elixir.
 * 
 * WHAT: Binary data manipulation optimized for Elixir's binary pattern matching
 * - Uses Elixir's native binary operations where possible
 * - Avoids complex inline patterns that cause compilation issues
 * - Maintains full API compatibility with Haxe's Bytes
 * 
 * HOW: Leverages Elixir's binary syntax and pattern matching
 * - Direct binary operations instead of array-based manipulation
 * - Clean iteration patterns without nested assignments
 * - Efficient UTF-8 handling using Elixir's native support
 */
@:coreApi
class Bytes {
    public var length(default, null): Int;
    
    // Internal binary data representation
    var b: Dynamic;
    
    /**
     * Private constructor - use factory methods instead
     */
    private function new(length: Int, b: Dynamic) {
        this.length = length;
        this.b = b;
    }
    
    /**
     * Allocate a new Bytes buffer of specified length
     */
    public static function alloc(length: Int): Bytes {
        // In Elixir, we'll use a binary with zeros
        var b = untyped __elixir__(':binary.copy(<<0>>, {0})', length);
        return new Bytes(length, b);
    }
    
    /**
     * Create Bytes from a string (single parameter version)
     * 
     * @param s The string to convert
     */
    @:overload(function(s: String): Bytes {})
    /**
     * Create Bytes from a string with encoding
     * 
     * @param s The string to convert
     * @param encoding Optional encoding (defaults to UTF8)
     */
    public static function ofString(s: String, encoding: Encoding = UTF8): Bytes {
        // For now, always use UTF8 regardless of encoding parameter
        // (Full encoding support would require more complex implementation)
        var binary = untyped __elixir__(':unicode.characters_to_binary({0}, :utf8)', s);
        var length = untyped __elixir__('byte_size({0})', binary);
        return new Bytes(length, binary);
    }
    
    /**
     * Convert Bytes to string
     * 
     * @param pos Starting position
     * @param len Number of bytes to convert
     * @param encoding Optional encoding (defaults to UTF8)
     */
    public function getString(pos: Int, len: Int, ?encoding: Encoding): String {
        if (encoding == null) encoding = UTF8;
        
        if (pos < 0 || len < 0 || pos + len > length) {
            throw "Out of bounds";
        }
        
        // Extract the binary slice and convert to string
        var slice = untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos, len);
        return untyped __elixir__(':unicode.characters_to_list({0}, :utf8)', slice);
    }
    
    /**
     * Convert entire Bytes to string
     */
    public function toString(): String {
        return getString(0, length);
    }
    
    /**
     * Get a byte at specified position
     */
    public function get(pos: Int): Int {
        if (pos < 0 || pos >= length) {
            throw "Out of bounds";
        }
        return untyped __elixir__(':binary.at({0}, {1})', b, pos);
    }
    
    /**
     * Set a byte at specified position
     */
    public function set(pos: Int, v: Int): Void {
        if (pos < 0 || pos >= length) {
            throw "Out of bounds";
        }
        
        // In Elixir, binaries are immutable, so we need to rebuild
        var beforePart = if (pos > 0) {
            untyped __elixir__(':binary.part({0}, 0, {1})', b, pos);
        } else {
            untyped __elixir__('<<>>');
        }
        
        var afterPart = if (pos < length - 1) {
            untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos + 1, length - pos - 1);
        } else {
            untyped __elixir__('<<>>');
        }
        
        b = untyped __elixir__('<<{0}::binary, {1}::8, {2}::binary>>', beforePart, v, afterPart);
    }
    
    /**
     * Copy bytes from source to destination
     */
    public function blit(pos: Int, src: Bytes, srcpos: Int, len: Int): Void {
        if (pos < 0 || srcpos < 0 || len < 0 || 
            pos + len > length || srcpos + len > src.length) {
            throw "Out of bounds";
        }
        
        // Extract the source slice
        var srcSlice = untyped __elixir__(':binary.part({0}, {1}, {2})', src.b, srcpos, len);
        
        // Rebuild the binary with the new data
        var beforePart = if (pos > 0) {
            untyped __elixir__(':binary.part({0}, 0, {1})', b, pos);
        } else {
            untyped __elixir__('<<>>');
        }
        
        var afterPart = if (pos + len < length) {
            untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos + len, length - pos - len);
        } else {
            untyped __elixir__('<<>>');
        }
        
        b = untyped __elixir__('<<{0}::binary, {1}::binary, {2}::binary>>', beforePart, srcSlice, afterPart);
    }
    
    /**
     * Create a sub-bytes view
     */
    public function sub(pos: Int, len: Int): Bytes {
        if (pos < 0 || len < 0 || pos + len > length) {
            throw "Out of bounds";
        }
        
        var subBinary = untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos, len);
        return new Bytes(len, subBinary);
    }
    
    /**
     * Fill a range with a specific byte value
     * 
     * @param pos Starting position
     * @param len Number of bytes to fill
     * @param value Byte value to fill with
     */
    public function fill(pos: Int, len: Int, value: Int): Void {
        if (pos < 0 || len < 0 || pos + len > length) {
            throw "Out of bounds";
        }
        
        // Create the fill pattern
        var fillBytes = untyped __elixir__(':binary.copy(<<{0}::8>>, {1})', value, len);
        
        // Rebuild the binary with the filled section
        var beforePart = if (pos > 0) {
            untyped __elixir__(':binary.part({0}, 0, {1})', b, pos);
        } else {
            untyped __elixir__('<<>>');
        }
        
        var afterPart = if (pos + len < length) {
            untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos + len, length - pos - len);
        } else {
            untyped __elixir__('<<>>');
        }
        
        b = untyped __elixir__('<<{0}::binary, {1}::binary, {2}::binary>>', beforePart, fillBytes, afterPart);
    }
    
    /**
     * Compare two Bytes objects
     */
    public function compare(other: Bytes): Int {
        return untyped __elixir__('case {0} do
            x when x < {1} -> -1
            x when x > {1} -> 1
            _ -> 0
        end', b, other.b);
    }
    
    /**
     * Get the underlying data (platform-specific)
     * Required by Haxe core type interface
     */
    public function getData(): haxe.io.BytesData {
        return b;
    }
    
    /**
     * Read a 64-bit double from the specified position
     */
    public function getDouble(pos: Int): Float {
        if (pos < 0 || pos + 8 > length) {
            throw "Out of bounds";
        }
        return untyped __elixir__('<<value::float-little-size(64)>> = :binary.part({0}, {1}, 8); value', b, pos);
    }
    
    /**
     * Write a 64-bit double to the specified position
     */
    public function setDouble(pos: Int, v: Float): Void {
        if (pos < 0 || pos + 8 > length) {
            throw "Out of bounds";
        }
        
        var beforePart = if (pos > 0) {
            untyped __elixir__(':binary.part({0}, 0, {1})', b, pos);
        } else {
            untyped __elixir__('<<>>');
        }
        
        var afterPart = if (pos + 8 < length) {
            untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos + 8, length - pos - 8);
        } else {
            untyped __elixir__('<<>>');
        }
        
        b = untyped __elixir__('<<{0}::binary, {1}::float-little-size(64), {2}::binary>>', beforePart, v, afterPart);
    }
    
    /**
     * Read a 32-bit float from the specified position
     */
    public function getFloat(pos: Int): Float {
        if (pos < 0 || pos + 4 > length) {
            throw "Out of bounds";
        }
        return untyped __elixir__('<<value::float-little-size(32)>> = :binary.part({0}, {1}, 4); value', b, pos);
    }
    
    /**
     * Write a 32-bit float to the specified position
     */
    public function setFloat(pos: Int, v: Float): Void {
        if (pos < 0 || pos + 4 > length) {
            throw "Out of bounds";
        }
        
        var beforePart = if (pos > 0) {
            untyped __elixir__(':binary.part({0}, 0, {1})', b, pos);
        } else {
            untyped __elixir__('<<>>');
        }
        
        var afterPart = if (pos + 4 < length) {
            untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos + 4, length - pos - 4);
        } else {
            untyped __elixir__('<<>>');
        }
        
        b = untyped __elixir__('<<{0}::binary, {1}::float-little-size(32), {2}::binary>>', beforePart, v, afterPart);
    }
    
    /**
     * Read a 16-bit unsigned integer
     */
    public function getUInt16(pos: Int): Int {
        if (pos < 0 || pos + 2 > length) {
            throw "Out of bounds";
        }
        return untyped __elixir__('<<value::little-unsigned-size(16)>> = :binary.part({0}, {1}, 2); value', b, pos);
    }
    
    /**
     * Write a 16-bit unsigned integer
     */
    public function setUInt16(pos: Int, v: Int): Void {
        if (pos < 0 || pos + 2 > length) {
            throw "Out of bounds";
        }
        
        var beforePart = if (pos > 0) {
            untyped __elixir__(':binary.part({0}, 0, {1})', b, pos);
        } else {
            untyped __elixir__('<<>>');
        }
        
        var afterPart = if (pos + 2 < length) {
            untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos + 2, length - pos - 2);
        } else {
            untyped __elixir__('<<>>');
        }
        
        b = untyped __elixir__('<<{0}::binary, {1}::little-unsigned-size(16), {2}::binary>>', beforePart, v, afterPart);
    }
    
    /**
     * Read a 32-bit signed integer
     */
    public function getInt32(pos: Int): Int {
        if (pos < 0 || pos + 4 > length) {
            throw "Out of bounds";
        }
        return untyped __elixir__('<<value::little-signed-size(32)>> = :binary.part({0}, {1}, 4); value', b, pos);
    }
    
    /**
     * Write a 32-bit signed integer
     */
    public function setInt32(pos: Int, v: Int): Void {
        if (pos < 0 || pos + 4 > length) {
            throw "Out of bounds";
        }
        
        var beforePart = if (pos > 0) {
            untyped __elixir__(':binary.part({0}, 0, {1})', b, pos);
        } else {
            untyped __elixir__('<<>>');
        }
        
        var afterPart = if (pos + 4 < length) {
            untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos + 4, length - pos - 4);
        } else {
            untyped __elixir__('<<>>');
        }
        
        b = untyped __elixir__('<<{0}::binary, {1}::little-signed-size(32), {2}::binary>>', beforePart, v, afterPart);
    }
    
    /**
     * Read a 64-bit signed integer
     */
    public function getInt64(pos: Int): haxe.Int64 {
        if (pos < 0 || pos + 8 > length) {
            throw "Out of bounds";
        }
        // In Elixir, we'll just return the value as-is
        // The compiler will handle Int64 abstraction
        return untyped __elixir__('<<value::little-signed-size(64)>> = :binary.part({0}, {1}, 8); value', b, pos);
    }
    
    /**
     * Write a 64-bit signed integer
     */
    public function setInt64(pos: Int, v: haxe.Int64): Void {
        if (pos < 0 || pos + 8 > length) {
            throw "Out of bounds";
        }
        
        // In Elixir, Int64 is just a regular integer
        // The compiler handles the abstraction
        var beforePart = if (pos > 0) {
            untyped __elixir__(':binary.part({0}, 0, {1})', b, pos);
        } else {
            untyped __elixir__('<<>>');
        }
        
        var afterPart = if (pos + 8 < length) {
            untyped __elixir__(':binary.part({0}, {1}, {2})', b, pos + 8, length - pos - 8);
        } else {
            untyped __elixir__('<<>>');
        }
        
        b = untyped __elixir__('<<{0}::binary, {1}::little-signed-size(64), {2}::binary>>', beforePart, v, afterPart);
    }
    
    /**
     * Read a string from the bytes
     */
    public function readString(pos: Int, len: Int): String {
        return getString(pos, len);
    }
    
    /**
     * Get hex string representation
     */
    public function toHex(): String {
        return untyped __elixir__('Base.encode16({0}, case: :lower)', b);
    }
    
    /**
     * Fast static get byte at position (no bounds checking)
     * For performance-critical code - use with caution
     * 
     * @param b The BytesData to read from
     * @param pos The position to read at
     * @return The byte value at that position
     */
    public static inline function fastGet(b: BytesData, pos: Int): Int {
        // In Elixir, we use :binary.at for byte access
        // BytesData is the same as our internal binary representation
        return untyped __elixir__(':binary.at({0}, {1})', b, pos);
    }
    
    /**
     * Create Bytes from hex string
     */
    public static function ofHex(s: String): Bytes {
        var binary = untyped __elixir__('Base.decode16!({0}, case: :mixed)', s);
        var length = untyped __elixir__('byte_size({0})', binary);
        return new Bytes(length, binary);
    }
    
    /**
     * Create Bytes from BytesData
     * Required by Haxe core type
     * 
     * @param b The BytesData to wrap
     * @return A new Bytes instance wrapping the data
     */
    public static function ofData(b: BytesData): Bytes {
        // In Elixir, BytesData is the same as our internal binary representation
        var length = untyped __elixir__('byte_size({0})', b);
        return new Bytes(length, b);
    }
}

// Encoding is defined in haxe.io.Encoding