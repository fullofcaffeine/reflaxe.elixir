package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;

/**
 * Enhanced usage detection for Elixir compiler
 * 
 * WHY: Reflaxe's MarkUnusedVariablesImpl misses usage in constructor/method arguments
 * WHAT: Comprehensive variable usage detection including nested expressions
 * HOW: Recursive AST traversal checking all expression types, not just TLocal
 */
class UsageDetector {
    /**
     * Check if a variable is used anywhere in an expression
     * @param varId The variable ID to check for
     * @param expr The expression to search within
     * @return true if the variable is used, false otherwise
     */
    public static function isVariableUsed(varId: Int, expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        return switch(expr.expr) {
            // Direct variable reference
            case TLocal(v) if (v.id == varId):
                true;
                
            // Constructor arguments - CRITICAL: Check all arguments
            case TNew(_, _, args):
                #if debug_parameter_usage
                trace('[UsageDetector] Checking TNew arguments for varId=$varId');
                #end
                for (arg in args) {
                    #if debug_parameter_usage
                    trace('[UsageDetector]   Checking arg: ${arg.expr}');
                    #end
                    if (isVariableUsed(varId, arg)) {
                        #if debug_parameter_usage
                        trace('[UsageDetector]   FOUND usage in TNew argument!');
                        #end
                        return true;
                    }
                }
                false;
                
            // Method/function calls - Check all arguments
            case TCall(e, args):
                if (isVariableUsed(varId, e)) return true;
                for (arg in args) {
                    if (isVariableUsed(varId, arg)) return true;
                }
                false;
                
            // Return statements
            case TReturn(e):
                e != null ? isVariableUsed(varId, e) : false;
                
            // If expressions
            case TIf(econd, eif, eelse):
                isVariableUsed(varId, econd) || 
                isVariableUsed(varId, eif) || 
                (eelse != null ? isVariableUsed(varId, eelse) : false);
                
            // Binary operations
            case TBinop(_, e1, e2):
                isVariableUsed(varId, e1) || isVariableUsed(varId, e2);
                
            // Unary operations
            case TUnop(_, _, e):
                isVariableUsed(varId, e);
                
            // Array access
            case TArray(e1, e2):
                isVariableUsed(varId, e1) || isVariableUsed(varId, e2);
                
            // Field access
            case TField(e, _):
                isVariableUsed(varId, e);
                
            // Block expressions
            case TBlock(exprs):
                for (e in exprs) {
                    if (isVariableUsed(varId, e)) return true;
                }
                false;
                
            // Switch/case
            case TSwitch(e, cases, edef):
                if (isVariableUsed(varId, e)) return true;
                for (c in cases) {
                    if (isVariableUsed(varId, c.expr)) return true;
                }
                edef != null ? isVariableUsed(varId, edef) : false;
                
            // Try/catch
            case TTry(e, catches):
                if (isVariableUsed(varId, e)) return true;
                for (c in catches) {
                    if (isVariableUsed(varId, c.expr)) return true;
                }
                false;
                
            // While loops
            case TWhile(econd, e, _):
                isVariableUsed(varId, econd) || isVariableUsed(varId, e);
                
            // For loops
            case TFor(v, e1, e2):
                // Don't check if it's the loop variable itself
                if (v.id == varId) return false;
                isVariableUsed(varId, e1) || isVariableUsed(varId, e2);
                
            // Object declaration
            case TObjectDecl(fields):
                for (f in fields) {
                    if (isVariableUsed(varId, f.expr)) return true;
                }
                false;
                
            // Array declaration
            case TArrayDecl(el):
                for (e in el) {
                    if (isVariableUsed(varId, e)) return true;
                }
                false;
                
            // Cast
            case TCast(e, _):
                isVariableUsed(varId, e);
                
            // Meta
            case TMeta(_, e):
                isVariableUsed(varId, e);
                
            // Parentheses
            case TParenthesis(e):
                isVariableUsed(varId, e);
                
            // Default: no usage found
            case _:
                false;
        }
    }
    
    /**
     * Check if a function parameter is truly unused
     * @param param The parameter to check
     * @param functionBody The function body expression
     * @return true if unused, false if used
     */
    public static function isParameterUnused(param: TVar, functionBody: TypedExpr): Bool {
        var isUsed = isVariableUsed(param.id, functionBody);
        #if debug_parameter_usage
        trace('[UsageDetector] Parameter ${param.name} (id=${param.id}) is ${isUsed ? "USED" : "UNUSED"}');
        trace('[UsageDetector] Function body type: ${functionBody != null ? Type.enumConstructor(functionBody.expr) : "null"}');
        #end
        
        // Special case: For static functions with simple constructor calls
        // Sometimes the analysis misses usage in constructor arguments
        // Double-check for the parameter name in constructor calls
        if (!isUsed && functionBody != null) {
            // Check if the parameter appears in a TNew expression
            isUsed = checkNewExpressionUsage(param.id, functionBody);
        }
        
        return !isUsed;
    }
    
    /**
     * Special check for parameters used in TNew expressions
     * Sometimes the regular traversal misses these
     */
    private static function checkNewExpressionUsage(varId: Int, expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        return switch(expr.expr) {
            case TBlock(exprs):
                // Check all expressions in the block
                for (e in exprs) {
                    if (checkNewExpressionUsage(varId, e)) return true;
                }
                false;
                
            case TVar(_, init) if (init != null):
                // Check variable initialization
                checkNewExpressionUsage(varId, init);
                
            case TNew(_, _, args):
                // Check each argument directly
                for (arg in args) {
                    if (arg != null && switch(arg.expr) {
                        case TLocal(v): v.id == varId;
                        default: isVariableUsed(varId, arg);
                    }) return true;
                }
                false;
                
            case TReturn(e):
                e != null ? checkNewExpressionUsage(varId, e) : false;
                
            default:
                // Fall back to regular check
                isVariableUsed(varId, expr);
        }
    }
}

#end