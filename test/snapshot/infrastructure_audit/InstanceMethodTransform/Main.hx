/**
 * Infrastructure Audit: InstanceMethodTransform Pass
 *
 * Tests whether the instanceMethodTransformPass (ElixirASTTransformer.hx line 2367)
 * correctly transforms array.method() calls to idiomatic Elixir Module.method(array) patterns.
 *
 * Expected Behavior:
 * - array.push(x) should become Enum or List operations
 * - array.map(fn) should become Enum.map(array, fn)
 * - array.filter(fn) should become Enum.filter(array, fn)
 * - Method calls properly converted to module function calls
 */
class Main {
    static function main() {
        // Test 1: Array methods - map
        var numbers = [1, 2, 3, 4, 5];
        var doubled = numbers.map(x -> x * 2);
        trace(doubled);

        // Test 2: Array methods - filter
        var evens = numbers.filter(n -> n % 2 == 0);
        trace(evens);

        // Test 3: Method chaining
        var result = numbers
            .filter(n -> n > 2)
            .map(n -> n * 3);
        trace(result);

        // Test 4: Array join
        var joined = ["a", "b", "c"].join(", ");
        trace(joined);

        // Test 5: Array length
        var len = numbers.length;
        trace(len);
    }
}
