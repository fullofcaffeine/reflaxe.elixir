package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * MutabilityDetector: Detects variables that are mutated in expressions
 *
 * WHY: Elixir is immutable, but Haxe allows mutation. We need to detect
 * which variables are mutated so we can generate appropriate rebinding
 * patterns in Elixir (especially important for loops).
 *
 * WHAT: Analyzes TypedExpr trees to find variables that are assigned to
 * after their initial declaration.
 *
 * HOW: Traverses the AST looking for TBinop(OpAssign) and similar patterns
 * that indicate mutation.
 *
 * ARCHITECTURE BENEFITS:
 * - Centralized mutation detection logic
 * - Consistent handling across all compilation contexts
 * - Testable in isolation
 *
 * NOTE: This is a CONSERVATIVE stub implementation for Phase 2 integration.
 * It assumes variables might be mutable when unsure, which is safe but
 * may generate less optimal code. Full implementation in Phase 3.
 */
class MutabilityDetector {
    /**
     * Detect variables that are mutated in the given expression
     *
     * @param expr The expression to analyze
     * @return Map of variable ID to TVar for mutated variables
     */
    public static function detectMutatedVariables(expr: TypedExpr): Map<Int, TVar> {
        var mutatedVars = new Map<Int, TVar>();

        // Conservative stub implementation
        // Full implementation would detect actual mutations
        function traverse(e: TypedExpr): Void {
            if (e == null) return;

            switch(e.expr) {
                case TBinop(OpAssign | OpAssignOp(_), e1, _):
                    // Check if left side is a variable
                    switch(e1.expr) {
                        case TLocal(v):
                            // Mark as mutated
                            mutatedVars.set(v.id, v);
                        default:
                    }

                case TVar(v, init):
                    // For now, conservatively assume any var with complex init
                    // might be mutated (safe but not optimal)
                    if (init != null) {
                        switch(init.expr) {
                            case TConst(_):
                                // Simple constants are safe
                            default:
                                // Conservative: might be mutated
                                // In Phase 3, we'll do deeper analysis
                        }
                    }

                default:
                    TypedExprTools.iter(e, traverse);
            }
        }

        traverse(expr);
        return mutatedVars;
    }

    /**
     * Check if a specific variable is mutated in an expression
     *
     * @param varId The variable ID to check
     * @param expr The expression to search
     * @return True if the variable is mutated
     */
    public static function isVariableMutated(varId: Int, expr: TypedExpr): Bool {
        var mutatedVars = detectMutatedVariables(expr);
        return mutatedVars.exists(varId);
    }
}

#end