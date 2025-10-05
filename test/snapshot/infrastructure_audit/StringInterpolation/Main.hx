/**
 * Infrastructure Audit: StringInterpolation Pass
 *
 * Tests whether the stringInterpolationPass (ElixirASTTransformer.hx line 2668)
 * correctly transforms string concatenation to idiomatic Elixir interpolation.
 *
 * Expected Behavior:
 * - "Hello " + name + "!" should become "Hello #{name}!"
 * - Complex concatenations should use interpolation, not <>
 * - Mixed types should be handled gracefully
 */
class Main {
    static function main() {
        // Test 1: Simple string concatenation
        var name = "World";
        var greeting = "Hello " + name + "!";
        trace(greeting);

        // Test 2: Multiple variables
        var firstName = "John";
        var lastName = "Doe";
        var fullName = firstName + " " + lastName;
        trace(fullName);

        // Test 3: String with numbers
        var age = 25;
        var message = "Age: " + age;
        trace(message);

        // Test 4: Complex concatenation
        var user = "Alice";
        var score = 100;
        var level = "Advanced";
        var status = "User " + user + " has score " + score + " at level " + level;
        trace(status);

        // Test 5: Concatenation in expression
        var result = "Result: " + (10 + 20);
        trace(result);
    }
}
