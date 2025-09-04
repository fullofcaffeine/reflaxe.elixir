package reflaxe.elixir.helpers;

/**
 * MutabilityDetector: Analyzes TypedExpr AST to detect variable mutations
 * 
 * WHY: When compiling while loops to Elixir's reduce_while, we need to know which
 * variables are mutated inside the loop body. These variables must become part of
 * the accumulator to properly thread state through the functional iteration.
 * 
 * WHAT: Detects mutation patterns including:
 * - Direct assignment: x = newValue
 * - Compound assignment: x += 1, x *= 2
 * - Method calls that mutate: buf.add(value)
 * 
 * HOW: Recursively traverses the AST looking for assignment patterns to TLocal variables.
 * Returns a set of variable IDs that are mutated within the expression.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only detects mutations, doesn't transform
 * - Reusable: Can be used for any mutation detection needs
 * - Testable: Pure function with clear inputs/outputs
 * - Maintainable: All mutation patterns in one place
 * 
 * CONDITIONAL COMPILATION:
 * This class is wrapped in #if (macro || reflaxe_runtime) because:
 * - It operates on Haxe's TypedExpr AST which only exists at compile-time
 * - The Type import provides macro-only APIs including TypedExpr
 * - Without this guard, Haxe would try to compile macro code for runtime
 * - This entire helper disappears after compilation - not part of generated Elixir
 */
#if (macro || reflaxe_runtime)

import haxe.macro.Type;

@:nullSafety(Off)
class MutabilityDetector {
    
    /**
     * Detect all variables that are mutated within an expression
     * 
     * @param expr The expression to analyze for mutations
     * @return Map of variable ID to variable info for all mutated variables
     */
    public static function detectMutatedVariables(expr: TypedExpr): Map<Int, TVar> {
        var mutatedVars = new Map<Int, TVar>();
        detectMutationsRecursive(expr, mutatedVars);
        return mutatedVars;
    }
    
    /**
     * Check if a specific variable is mutated within an expression
     * 
     * @param varId The variable ID to check for
     * @param expr The expression to search within
     * @return True if the variable is mutated anywhere in the expression
     */
    public static function isVariableMutated(varId: Int, expr: TypedExpr): Bool {
        var mutatedVars = detectMutatedVariables(expr);
        return mutatedVars.exists(varId);
    }
    
    /**
     * Recursively detect mutations in the AST
     */
    static function detectMutationsRecursive(expr: TypedExpr, mutatedVars: Map<Int, TVar>): Void {
        if (expr == null) return;
        
        switch(expr.expr) {
            // Direct assignment: x = value
            case TBinop(OpAssign, e1, e2):
                switch(e1.expr) {
                    case TLocal(v):
                        // Local variable assignment
                        mutatedVars.set(v.id, v);
                    default:
                        // Could be field assignment or array access
                        detectMutationsRecursive(e1, mutatedVars);
                }
                detectMutationsRecursive(e2, mutatedVars);
                
            // Compound assignment: x += 1, x *= 2, etc.
            case TBinop(OpAssignOp(_), e1, e2):
                switch(e1.expr) {
                    case TLocal(v):
                        // Local variable compound assignment
                        mutatedVars.set(v.id, v);
                    default:
                        detectMutationsRecursive(e1, mutatedVars);
                }
                detectMutationsRecursive(e2, mutatedVars);
                
            // Unary operations that mutate: ++x, x++, --x, x--
            case TUnop(OpIncrement | OpDecrement, _, e):
                switch(e.expr) {
                    case TLocal(v):
                        mutatedVars.set(v.id, v);
                    default:
                        detectMutationsRecursive(e, mutatedVars);
                }
                
            // Method calls that might mutate (e.g., buf.add(value))
            // We can't know for sure without type analysis, but we recurse into arguments
            case TCall(e, el):
                detectMutationsRecursive(e, mutatedVars);
                for (arg in el) {
                    detectMutationsRecursive(arg, mutatedVars);
                }
                
            // Blocks - check all expressions
            case TBlock(el):
                for (e in el) {
                    detectMutationsRecursive(e, mutatedVars);
                }
                
            // Conditionals - check all branches
            case TIf(econd, eif, eelse):
                detectMutationsRecursive(econd, mutatedVars);
                detectMutationsRecursive(eif, mutatedVars);
                if (eelse != null) {
                    detectMutationsRecursive(eelse, mutatedVars);
                }
                
            // Switch/case - check all cases
            case TSwitch(e, cases, edef):
                detectMutationsRecursive(e, mutatedVars);
                for (c in cases) {
                    for (v in c.values) {
                        detectMutationsRecursive(v, mutatedVars);
                    }
                    detectMutationsRecursive(c.expr, mutatedVars);
                }
                if (edef != null) {
                    detectMutationsRecursive(edef, mutatedVars);
                }
                
            // Loops - check condition and body
            case TWhile(econd, e, _):
                detectMutationsRecursive(econd, mutatedVars);
                detectMutationsRecursive(e, mutatedVars);
                
            case TFor(v, e1, e2):
                detectMutationsRecursive(e1, mutatedVars);
                detectMutationsRecursive(e2, mutatedVars);
                
            // Try/catch
            case TTry(e, catches):
                detectMutationsRecursive(e, mutatedVars);
                for (c in catches) {
                    detectMutationsRecursive(c.expr, mutatedVars);
                }
                
            // Variable declarations - check initializer
            case TVar(v, expr):
                if (expr != null) {
                    detectMutationsRecursive(expr, mutatedVars);
                }
                
            // Return statements
            case TReturn(e):
                if (e != null) {
                    detectMutationsRecursive(e, mutatedVars);
                }
                
            // Throw statements
            case TThrow(e):
                detectMutationsRecursive(e, mutatedVars);
                
            // Array access
            case TArrayDecl(el):
                for (e in el) {
                    detectMutationsRecursive(e, mutatedVars);
                }
                
            // Object declaration
            case TObjectDecl(fields):
                for (f in fields) {
                    detectMutationsRecursive(f.expr, mutatedVars);
                }
                
            // Function definitions - check body
            case TFunction(tfunc):
                if (tfunc.expr != null) {
                    detectMutationsRecursive(tfunc.expr, mutatedVars);
                }
                
            // Field access - might be part of a mutation chain
            case TField(e, _):
                detectMutationsRecursive(e, mutatedVars);
                
            // Parentheses
            case TParenthesis(e):
                detectMutationsRecursive(e, mutatedVars);
                
            // Type cast
            case TCast(e, _):
                detectMutationsRecursive(e, mutatedVars);
                
            // Meta
            case TMeta(_, e):
                detectMutationsRecursive(e, mutatedVars);
                
            // Continue and break don't mutate
            case TContinue | TBreak:
                // No mutations
                
            // Leaf nodes - no mutations to detect
            case TLocal(_) | TIdent(_) | TConst(_):
                // No mutations in leaf nodes
                
            // New expressions
            case TNew(_, _, el):
                for (e in el) {
                    detectMutationsRecursive(e, mutatedVars);
                }
                
            // Enum-related expressions
            case TEnumParameter(e, _, _):
                detectMutationsRecursive(e, mutatedVars);
                
            case TEnumIndex(e):
                detectMutationsRecursive(e, mutatedVars);
                
            // Any other binary operations
            case TBinop(_, e1, e2):
                detectMutationsRecursive(e1, mutatedVars);
                detectMutationsRecursive(e2, mutatedVars);
                
            // Any other unary operations
            case TUnop(_, _, e):
                detectMutationsRecursive(e, mutatedVars);
                
            // Array access expressions
            case TArray(e1, e2):
                detectMutationsRecursive(e1, mutatedVars);
                detectMutationsRecursive(e2, mutatedVars);
                
            // Type expressions (no mutations)
            case TTypeExpr(_):
                // No mutations in type expressions
        }
    }
    
    /**
     * Extract variable references that need to be included in accumulator
     * This includes both mutated variables and any variables they depend on
     * 
     * @param expr The expression to analyze
     * @param mutatedVars The set of variables that are mutated
     * @return List of variables that need to be in the accumulator
     */
    public static function extractAccumulatorVariables(expr: TypedExpr, mutatedVars: Map<Int, TVar>): Array<TVar> {
        // For now, just return the mutated variables
        // In the future, we might need to include variables that mutated vars depend on
        var result: Array<TVar> = [];
        for (v in mutatedVars) {
            result.push(v);
        }
        return result;
    }
}
#end