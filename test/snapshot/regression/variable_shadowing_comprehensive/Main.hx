package;

/**
 * Comprehensive test for variable shadowing patterns
 * Tests ALL scenarios that cause "variable unused" warnings in Elixir
 *
 * This test ensures our fix for redundant nil initialization handles:
 * - Basic patterns (this1 = nil; this1 = value)
 * - Patterns with intervening statements
 * - Patterns inside conditionals
 * - Multiple shadowing in same block
 * - Query builder patterns (common in Ecto)
 */
class Main {
    public static function main() {
        testBasicShadowing();
        testShadowingWithInterveningStatements();
        testShadowingInIfBlocks();
        testQueryBuilderPattern();
        testAbstractConstructorPattern();
        trace("All shadowing tests complete");
    }

    // Test 1: Basic shadowing pattern
    static function testBasicShadowing() {
        var value = "test";
        var this1: Dynamic = null;
        this1 = value;
        trace('Basic shadowing: $this1');
    }

    // Test 2: Shadowing with intervening statements (Ecto query pattern)
    static function testShadowingWithInterveningStatements() {
        var query = "SELECT * FROM users";
        var this1: Dynamic = null;
        var newQuery = query + " WHERE active = true";
        this1 = newQuery;
        query = this1;
        trace('Query with intervening: $query');
    }

    // Test 3: Shadowing inside if blocks (Users context pattern)
    static function testShadowingInIfBlocks() {
        var filter = {name: "John", email: "john@example.com", isActive: true};

        if (filter != null) {
            var query = "SELECT * FROM users";
            var this1: Dynamic = null;
            this1 = query;
            query = this1;

            if (filter.name != null) {
                var value = '%${filter.name}%';
                var newQuery = '$query WHERE name LIKE \'$value\'';
                var this2: Dynamic = null;
                this2 = newQuery;
                query = this2;
            }

            if (filter.email != null) {
                var value = '%${filter.email}%';
                var newQuery = '$query AND email LIKE \'$value\'';
                var this3: Dynamic = null;
                this3 = newQuery;
                query = this3;
            }

            if (filter.isActive == true) {
                var value = filter.isActive;
                var newQuery = '$query AND active = $value';
                var this4: Dynamic = null;
                this4 = newQuery;
                query = this4;
            }

            trace('Complex query: $query');
        }
    }

    // Test 4: Query builder pattern (simulates Ecto.Query)
    static function testQueryBuilderPattern() {
        var baseQuery = buildBaseQuery();

        // First transformation
        var transformed1 = applyFilter(baseQuery, "name", "Alice");
        var temp1: Dynamic = null;
        temp1 = transformed1;
        baseQuery = temp1;

        // Second transformation
        var transformed2 = applyFilter(baseQuery, "age", "25");
        var temp2: Dynamic = null;
        temp2 = transformed2;
        baseQuery = temp2;

        trace('Query builder result: $baseQuery');
    }

    static function buildBaseQuery(): String {
        return "SELECT * FROM users";
    }

    static function applyFilter(query: String, field: String, value: String): String {
        return '$query WHERE $field = \'$value\'';
    }

    // Test 5: Abstract constructor pattern
    static function testAbstractConstructorPattern() {
        // Pattern from abstract type constructors
        var this1: Dynamic = null;
        this1 = createAbstractValue("test_value");
        var result = this1;
        trace('Abstract constructor: $result');
    }

    static function createAbstractValue(value: String): Dynamic {
        return {type: "abstract", value: value};
    }
}