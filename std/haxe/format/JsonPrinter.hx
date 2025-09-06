package haxe.format;

/**
 * JsonPrinter: Simplified implementation avoiding mutable patterns
 * 
 * WHY: The Haxe standard library JsonPrinter uses mutable StringBuf patterns
 * that don't translate well to Elixir's immutable world. This implementation
 * avoids those patterns by building strings functionally.
 * 
 * WHAT: Functional implementation of JsonPrinter that generates valid Elixir
 * 
 * HOW: Uses recursive string building without mutable state
 */
@:coreApi
class JsonPrinter {
    var replacer: Null<(key:Dynamic, value:Dynamic) -> Dynamic>;
    var space: Null<String>;
    
    public function new(?replacer: (key:Dynamic, value:Dynamic) -> Dynamic, ?space: String) {
        this.replacer = replacer;
        this.space = space;
    }
    
    /**
     * Print any value to JSON string
     */
    public static function print(o: Dynamic, ?replacer: (key:Dynamic, value:Dynamic) -> Dynamic, ?space: String): String {
        var printer = new JsonPrinter(replacer, space);
        return printer.writeValue(o, "");
    }
    
    /**
     * Write a value to JSON string
     */
    function writeValue(v: Dynamic, key: String): String {
        // Apply replacer if provided
        if (replacer != null) {
            v = replacer(key, v);
        }
        
        // Use simple type checking instead of Type.typeof for now
        // since pattern matching on ValueType enum is not working correctly
        
        if (v == null) {
            return "null";
        }
        
        if (Std.isOfType(v, Bool)) {
            return v ? "true" : "false";
        }
        
        if (Std.isOfType(v, Int)) {
            return Std.string(v);
        }
        
        if (Std.isOfType(v, Float)) {
            var s = Std.string(v);
            // Check for NaN/Infinity
            if (s == "NaN" || s == "Infinity" || s == "-Infinity") {
                return "null";
            }
            return s;
        }
        
        if (Std.isOfType(v, String)) {
            return quoteString(v);
        }
        
        if (Std.isOfType(v, Array)) {
            return writeArray(v);
        }
        
        // Default to object serialization
        return writeObject(v);
    }
    
    /**
     * Write an array to JSON
     */
    function writeArray(arr: Array<Dynamic>): String {
        var items = [];
        for (i in 0...arr.length) {
            items.push(writeValue(arr[i], Std.string(i)));
        }
        
        if (space != null && items.length > 0) {
            return "[\n  " + items.join(",\n  ") + "\n]";
        } else {
            return "[" + items.join(",") + "]";
        }
    }
    
    /**
     * Write an object to JSON
     */
    function writeObject(obj: Dynamic): String {
        var fields = Reflect.fields(obj);
        var pairs = [];
        
        for (field in fields) {
            var value = Reflect.field(obj, field);
            var key = quoteString(field);
            var val = writeValue(value, field);
            
            if (space != null) {
                pairs.push(key + ": " + val);
            } else {
                pairs.push(key + ":" + val);
            }
        }
        
        if (space != null && pairs.length > 0) {
            return "{\n  " + pairs.join(",\n  ") + "\n}";
        } else {
            return "{" + pairs.join(",") + "}";
        }
    }
    
    /**
     * Quote a string for JSON
     */
    function quoteString(s: String): String {
        // Basic JSON string escaping
        var result = '"';
        for (i in 0...s.length) {
            var c = s.charCodeAt(i);
            switch (c) {
                case 0x22: result += '\\"';  // "
                case 0x5C: result += '\\\\'; // \
                case 0x08: result += '\\b';  // backspace
                case 0x0C: result += '\\f';  // form feed
                case 0x0A: result += '\\n';  // newline
                case 0x0D: result += '\\r';  // carriage return
                case 0x09: result += '\\t';  // tab
                default:
                    if (c < 0x20) {
                        // Control characters
                        var hex = StringTools.hex(c, 4);
                        result += '\\u' + hex;
                    } else {
                        result += s.charAt(i);
                    }
            }
        }
        result += '"';
        return result;
    }
    
    // Compatibility method for existing code
    public function write(k: String, v: Dynamic): String {
        return writeValue(v, k);
    }
}