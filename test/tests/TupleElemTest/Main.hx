package;

class Main {
    public static function main() {
        var tuple = {value: 42, tag: "ok"};
        
        // Direct field access (should work)
        var tag = tuple.tag;
        var value = tuple.value;
        
        // Simulated tuple element access
        var result: Dynamic = ["ok", 42];
        var firstElem = untyped result.elem(0);
        var secondElem = untyped result.elem(1);
        
        trace(tag);
        trace(value);
        trace(firstElem);
        trace(secondElem);
    }
}