/**
 * Regression Test: Variable Naming Consistency Between Declaration and Reference
 *
 * BUG HISTORY:
 * - Issue: Declaration uses _variableName, reference uses variableName (mismatch)
 * - Root Cause: VariableBuilder and VariableCompiler use separate naming systems
 * - Impact: undefined variable errors in generated Elixir
 * - Symptom: _changeset = ...; Repo.update(changeset) # ERROR: changeset undefined
 * - Date Discovered: 2025-01-29
 * - Priority: HIGH (causes compilation failures in todo-app)
 *
 * EXPECTED BEHAVIOR:
 * - Used variables: consistent name WITHOUT underscore prefix
 * - Unused variables: consistent name WITH underscore prefix
 * - Declaration and ALL references use IDENTICAL names
 *
 * IDIOMATIC OUTPUT EXAMPLES:
 * var usedVar = 1; trace(usedVar);
 *   Declaration: usedVar = 1
 *   Reference: usedVar (NOT _usedVar, NOT used_var)
 *
 * var unusedVar = 2; // never referenced
 *   Declaration: _unusedVar = 2
 *   Reference: N/A (variable is unused)
 *
 * CURRENT BUG:
 * - Declaration gets: _changeset = ...
 * - Reference gets: changeset (MISMATCH!)
 * - Result: undefined variable error
 */

class Main {
    static function main() {
        trace("=== Test 1: Used variable (no underscore) ===");

        // This variable IS used - should NOT have underscore prefix
        var usedVariable = 42;
        trace("Used: " + usedVariable);  // Reference should match declaration

        trace("\n=== Test 2: Unused variable (with underscore) ===");

        // This variable is NEVER used - should HAVE underscore prefix
        var unusedVariable = 100;
        // Note: Never referenced - should be compiled as _unusedVariable

        trace("\n=== Test 3: Partially used variables ===");

        var firstVar = 1;   // Used
        var secondVar = 2;  // NOT used
        var thirdVar = 3;   // Used

        trace("First: " + firstVar);
        // secondVar intentionally not used
        trace("Third: " + thirdVar);

        trace("\n=== Test 4: Variable in conditional ===");

        var conditionalVar = "test";
        if (conditionalVar != null) {
            trace("Conditional: " + conditionalVar);  // Reference must match
        }

        trace("\n=== Test 5: Multiple references ===");

        var multiRef = 10;
        trace("Ref 1: " + multiRef);
        trace("Ref 2: " + multiRef);
        trace("Ref 3: " + multiRef);
        // ALL references must use same name as declaration
    }
}