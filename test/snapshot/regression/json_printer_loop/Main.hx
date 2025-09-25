// Test for JsonPrinter loop pattern issues
// This reproduces the loop accumulation pattern that was generating:
// - Invalid double assignment (i = g = g + 1)
// - Uninitialized accumulator variables
// - Wrong pattern (Enum.each instead of Enum.reduce)

class Main {
    static function main() {
        var printer = new JsonPrinter();
        var arr = [1, 2, 3, 4, 5];
        printer.writeArray(arr);
        
        var obj = {name: "test", values: [1, 2, 3]};
        printer.writeObject(obj);
    }
}

class JsonPrinter {
    var buffer: StringBuf;
    
    public function new() {
        buffer = new StringBuf();
    }
    
    // This pattern was generating invalid code with infrastructure variables
    public function writeArray(arr: Array<Dynamic>) {
        buffer.add("[");
        
        // This loop pattern causes issues:
        // - Infrastructure variable 'g' leaks into generated code
        // - Double assignment pattern: i = g = g + 1
        // - Uses Enum.each but should use Enum.reduce for accumulation
        var items = "";
        for (i in 0...arr.length) {
            if (i > 0) items += ", ";
            items += writeValue(arr[i]);
        }
        buffer.add(items);
        
        buffer.add("]");
    }
    
    // Similar pattern with object iteration
    public function writeObject(obj: Dynamic) {
        buffer.add("{");
        
        var fields = Reflect.fields(obj);
        var result = "";
        for (i in 0...fields.length) {
            if (i > 0) result += ", ";
            var field = fields[i];
            var value = Reflect.field(obj, field);
            result += '"$field": ${writeValue(value)}';
        }
        buffer.add(result);
        
        buffer.add("}");
    }
    
    function writeValue(v: Dynamic): String {
        if (v == null) return "null";
        if (Std.isOfType(v, Bool)) return Std.string(v);
        if (Std.isOfType(v, Float) || Std.isOfType(v, Int)) return Std.string(v);
        if (Std.isOfType(v, String)) return '"${StringTools.replace(cast v, '"', '\\"')}"';
        if (Std.isOfType(v, Array)) {
            var arr: Array<Dynamic> = cast v;
            var items = [];
            for (item in arr) {
                items.push(writeValue(item));
            }
            return "[" + items.join(", ") + "]";
        }
        return "{}";
    }
    
    public function toString(): String {
        return buffer.toString();
    }
}