class Main {
    public static function main() {
        // Test ternary operators that generate temp variables
        testBasicTernary();
        testNestedTernary();
        testTernaryInFunction();
    }

    static function testBasicTernary() {
        var config: Dynamic = {name: "test"};
        // This should generate: id = if(config != nil, do: config.id, else: "default")
        // WITHOUT duplicate temp_string = nil
        var id = config != null ? config.id : "default";
        trace("ID: " + id);
    }

    static function testNestedTernary() {
        var a = 5;
        var b = 10;
        // This should generate clean nested ternary without duplicate temp vars
        var result = a > 0 ? (b > 0 ? "both positive" : "a positive") : "a not positive";
        trace("Result: " + result);
    }

    static function testTernaryInFunction() {
        var module = "MyModule";
        var args = [1, 2, 3];
        var id: String = null;
        
        // This pattern is from ChildSpecBuilder - should not generate duplicate nil
        var spec = createSpec(module, args, id);
        trace("Spec: " + spec);
    }

    static function createSpec(module: String, args: Array<Int>, id: String) {
        // Pattern that generates temp_string in ChildSpecBuilder
        var actualId = id != null ? id : module;
        return {
            id: actualId,
            module: module,
            args: args
        };
    }
}