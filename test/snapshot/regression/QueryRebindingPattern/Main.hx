/**
 * Regression Test: Idiomatic Conditional Variable Rebinding Pattern
 *
 * BUG HISTORY:
 * - Issue: Conditional rebinding generates intermediate variables (_this1, _query2, etc.)
 * - Root Cause: Rebinding system doesn't detect idiomatic pattern
 * - Impact: Verbose, non-idiomatic Elixir code
 * - Symptom: Multiple intermediate variables instead of simple if expression
 * - Date Discovered: 2025-01-29
 * - Priority: MEDIUM (works but not idiomatic)
 *
 * EXPECTED BEHAVIOR:
 * - Conditional rebinding should use idiomatic Elixir pattern
 * - Pattern: variable = if condition, do: transform(variable), else: variable end
 * - NO intermediate _this1 or similar variables
 *
 * IDIOMATIC OUTPUT EXAMPLE:
 * Haxe:
 *   var query = initialValue();
 *   if (condition) {
 *       query = transform(query);
 *   }
 *
 * Should generate:
 *   query = initial_value()
 *   query = if condition do
 *       transform(query)
 *   else
 *       query
 *   end
 *
 * Should NOT generate:
 *   _query2 = initial_value()
 *   _this1 = nil
 *   this1 = query2
 *   _query = this1  # Confusing!
 *
 * CURRENT BUG:
 * - Generates multiple intermediate variables
 * - Variable shadowing creates confusion
 * - Non-idiomatic pattern that Elixir devs wouldn't write
 */

// Mock functions for testing rebinding pattern
function initialQuery(): String {
    return "SELECT * FROM users";
}

function addFilter(query: String, field: String, value: String): String {
    return query + " WHERE " + field + " = " + value;
}

function addSort(query: String, field: String): String {
    return query + " ORDER BY " + field;
}

class Main {
    static function main() {
        trace("=== Test 1: Simple conditional rebinding ===");

        var query1 = initialQuery();
        var applyFilter = true;

        if (applyFilter) {
            query1 = addFilter(query1, "status", "active");
        }

        trace("Query 1: " + query1);

        trace("\n=== Test 2: Multiple conditional rebindings ===");

        var query2 = initialQuery();
        var filterByStatus = true;
        var sortByName = true;

        if (filterByStatus) {
            query2 = addFilter(query2, "status", "active");
        }

        if (sortByName) {
            query2 = addSort(query2, "name");
        }

        trace("Query 2: " + query2);

        trace("\n=== Test 3: Nested conditional rebinding ===");

        var query3 = initialQuery();
        var applyAdvancedFilters = true;

        if (applyAdvancedFilters) {
            query3 = addFilter(query3, "role", "admin");

            var includeInactive = false;
            if (!includeInactive) {
                query3 = addFilter(query3, "active", "true");
            }
        }

        trace("Query 3: " + query3);

        trace("\n=== Test 4: Rebinding with else branch ===");

        var query4 = initialQuery();
        var useSpecialQuery = false;

        if (useSpecialQuery) {
            query4 = addFilter(query4, "special", "yes");
        } else {
            query4 = addFilter(query4, "standard", "yes");
        }

        trace("Query 4: " + query4);
    }
}