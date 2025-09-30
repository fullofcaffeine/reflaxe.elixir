/**
 * Regression Test: __elixir__() Expansion in Generated Code
 *
 * BUG HISTORY:
 * - Issue: __elixir__() appears as literal function call in generated Elixir
 * - Root Cause: CallExprBuilder doesn't detect and expand __elixir__() calls
 * - Impact: Generated code has undefined function errors
 * - Symptom: def from_string(s) do __elixir__("...", s) end
 * - Date Discovered: 2025-01-29
 * - Priority: CRITICAL (blocks todo-app completely)
 *
 * EXPECTED BEHAVIOR:
 * - __elixir__() should be expanded at compile time
 * - Generated code should contain inline Elixir, NOT function calls
 * - Parameter substitution {0}, {1} should work correctly
 *
 * IDIOMATIC OUTPUT EXAMPLES:
 * Test 1: untyped __elixir__("DateTime.utc_now()")
 *   Should generate: DateTime.utc_now()
 *   NOT: __elixir__("DateTime.utc_now()")
 *
 * Test 2: untyped __elixir__("\"Hello, {0}!\"", name)
 *   Should generate: "Hello, #{name}!"
 *   NOT: __elixir__("\"Hello, {0}!\"", name)
 */

class Main {
    static function main() {
        trace("=== Test 1: Simple __elixir__ call ===");

        // Test 1: No parameters - should expand to inline Elixir
        var currentTime = untyped __elixir__("DateTime.utc_now()");
        trace("Current time: " + currentTime);

        trace("\n=== Test 2: __elixir__ with parameter substitution ===");

        // Test 2: Single parameter - {0} should be substituted
        var name = "Alice";
        var greeting = untyped __elixir__("\"Hello, {0}!\"", name);
        trace("Greeting: " + greeting);

        trace("\n=== Test 3: Multiple parameters ===");

        // Test 3: Multiple parameters - {0}, {1}, {2} should be substituted
        var x = 10;
        var y = 20;
        var result = untyped __elixir__("{0} + {1}", x, y);
        trace("Result: " + result);

        trace("\n=== Test 4: Complex Elixir expression ===");

        // Test 4: Complex expression with case statement
        var dateStr = "2025-01-29T12:00:00Z";
        var parsedDate = untyped __elixir__("
            case DateTime.from_iso8601({0}) do
                {:ok, dt, _} -> dt
                _ -> DateTime.utc_now()
            end
        ", dateStr);
        trace("Parsed date: " + parsedDate);
    }
}