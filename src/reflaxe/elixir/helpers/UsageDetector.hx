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

        #if debug_parameter_usage
        if (varId == 44997 || varId == 44987) {
            var exprType = Type.enumConstructor(expr.expr);
            if (exprType == "TWhile") {
                trace('[UsageDetector] *** FOUND TWhile for key varId=$varId ***');
            }
        }
        #end

        return switch(expr.expr) {
            // Direct variable reference
            case TLocal(v):
                #if debug_parameter_usage
                if (varId == 45014 || varId == 45024 || varId == 45004) {
                    trace('[UsageDetector] TLocal check: v.id=${v.id}, varId=$varId, match=${v.id == varId}');
                }
                #end
                if (v.id == varId) {
                    #if debug_parameter_usage
                    if (varId == 44997 || varId == 45007 || varId == 44987) {
                        trace('[UsageDetector] *** FOUND MATCH for key! ***');
                    }
                    #end
                    true;
                } else {
                    false;
                }
                
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
                #if debug_parameter_usage
                if (varId == 44997 || varId == 45007 || varId == 44987) {
                    trace('[UsageDetector] TCall checking for key varId=$varId');
                    trace('[UsageDetector]   Checking function expression...');
                }
                #end
                if (isVariableUsed(varId, e)) return true;
                #if debug_parameter_usage
                if (varId == 44997 || varId == 45007 || varId == 44987) {
                    trace('[UsageDetector]   Checking ${args.length} arguments...');
                }
                #end
                for (arg in args) {
                    if (isVariableUsed(varId, arg)) {
                        #if debug_parameter_usage
                        if (varId == 44997 || varId == 45007 || varId == 44987) {
                            trace('[UsageDetector]   FOUND in argument!');
                        }
                        #end
                        return true;
                    }
                }
                false;
                
            // Return statements
            case TReturn(e):
                #if debug_parameter_usage
                if (varId == 45299 || varId == 45307) {
                    trace('[UsageDetector] *** TReturn check for varId=$varId ***');
                    trace('[UsageDetector]   Return expr type: ${e != null ? Type.enumConstructor(e.expr) : "null"}');
                    var result = e != null ? isVariableUsed(varId, e) : false;
                    trace('[UsageDetector]   Result: $result');
                    return result;
                }
                #end
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
                
            // Variable declarations with initialization
            case TVar(v, init):
                // Don't check if it's the variable itself being declared
                if (v.id == varId) return false;
                // Check if the variable is used in the initialization expression
                init != null ? isVariableUsed(varId, init) : false;

            // Block expressions
            case TBlock(exprs):
                #if debug_parameter_usage
                if ((varId == 45014 || varId == 45024 || varId == 45004) && exprs.length > 0) {
                    trace('[UsageDetector] TBlock for varId=$varId with ${exprs.length} expressions');
                    for (i in 0...exprs.length) {
                        var exprType = Type.enumConstructor(exprs[i].expr);
                        trace('[UsageDetector]   Expr[$i]: $exprType');
                        var used = isVariableUsed(varId, exprs[i]);
                        if (used) {
                            trace('[UsageDetector]   *** FOUND in expr $i, returning true ***');
                            return true;
                        }
                    }
                    trace('[UsageDetector]   Not found in any block expression, returning false');
                    false;
                } else {
                #end
                    for (e in exprs) {
                        if (isVariableUsed(varId, e)) return true;
                    }
                    false;
                #if debug_parameter_usage
                }
                #end
                
            // Switch/case
            case TSwitch(e, cases, edef):
                #if debug_parameter_usage
                if (varId == 45274 || varId == 45282) {
                    trace('[UsageDetector] *** Special TSwitch check for varId=$varId ***');
                    trace('[UsageDetector]   Switch expr type: ${e != null ? Type.enumConstructor(e.expr) : "null"}');
                    var used = isVariableUsed(varId, e);
                    trace('[UsageDetector]   isVariableUsed(e) returned: $used');
                }
                #end
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
                #if debug_parameter_usage
                if (varId == 45014 || varId == 45024 || varId == 45004) {
                    trace('[UsageDetector] TWhile for key varId=$varId');
                    var condUsed = isVariableUsed(varId, econd);
                    trace('[UsageDetector]   Condition used: $condUsed');
                    var bodyUsed = isVariableUsed(varId, e);
                    trace('[UsageDetector]   Body used: $bodyUsed');
                    var result = condUsed || bodyUsed;
                    trace('[UsageDetector]   TWhile result: $result');
                    result;
                } else {
                    isVariableUsed(varId, econd) || isVariableUsed(varId, e);
                }
                #else
                isVariableUsed(varId, econd) || isVariableUsed(varId, e);
                #end
                
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
                return isVariableUsed(varId, e);

            // Meta
            case TMeta(_, e):
                return isVariableUsed(varId, e);

            // Enum index checking (for switch statements on enums)
            case TEnumIndex(e):
                #if debug_parameter_usage
                trace('[UsageDetector] TEnumIndex checking for varId=$varId');
                #end
                return isVariableUsed(varId, e);

            // Enum parameter extraction (for getting values from enum constructors)
            case TEnumParameter(e, _, _):
                #if debug_parameter_usage
                trace('[UsageDetector] TEnumParameter checking for varId=$varId');
                #end
                return isVariableUsed(varId, e);

            // Parentheses
            case TParenthesis(e):
                #if debug_parameter_usage
                if (varId == 45274 || varId == 45282) {
                    trace('[UsageDetector] TParenthesis for special varId=$varId');
                    trace('[UsageDetector]   Inner type: ${e != null ? Type.enumConstructor(e.expr) : "null"}');
                    if (e != null) {
                        switch (e.expr) {
                            case TLocal(v):
                                trace('[UsageDetector]   Found TLocal: ${v.name} (id=${v.id})');
                            default:
                        }
                    }
                    var result = isVariableUsed(varId, e);
                    trace('[UsageDetector]   Result: $result');
                    return result;
                }
                #end
                return isVariableUsed(varId, e);
                
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
        #if debug_parameter_usage
        if (param.name == "key" && param.id == 45007) {
            trace('[UsageDetector] === START CHECKING key id=45007 ===');
        }
        if (param.name == "result" || param.name == "key") {
            trace('[UsageDetector] *** CHECKING PARAMETER "${param.name}" (id=${param.id}) ***');
            trace('[UsageDetector] Function body type: ${functionBody != null ? Type.enumConstructor(functionBody.expr) : "null"}');
            if (functionBody != null && functionBody.expr != null) {
                switch (functionBody.expr) {
                    case TBlock(exprs):
                        trace('[UsageDetector]   TBlock with ${exprs.length} expressions');
                        for (i in 0...exprs.length) {
                            trace('[UsageDetector]     Expr[$i]: ${Type.enumConstructor(exprs[i].expr)}');
                        }
                    default:
                }
            }
        }
        #end
        var isUsed = isVariableUsed(param.id, functionBody);
        #if debug_parameter_usage
        if (param.name == "key") {
            trace('[UsageDetector] *** KEY PARAMETER ${param.name} (${param.id}) isUsed=$isUsed ***');
        }
        if (param.name == "key" && (param.id == 45014 || param.id == 45024 || param.id == 45004)) {
            trace('[UsageDetector] *** SPECIAL DEBUG for key (${param.id}) ***');
            trace('[UsageDetector]   isUsed result: $isUsed');
            trace('[UsageDetector]   About to examine function body for this specific key');
            // Let's do a manual check to see what's happening
            debugTraverseForVariable(param.id, functionBody, 0);
        }
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
    
    #if debug_parameter_usage
    /**
     * Debug function to trace variable usage traversal
     */
    private static function debugTraverseForVariable(varId: Int, expr: TypedExpr, depth: Int): Void {
        if (expr == null) return;
        var indent = [for (i in 0...depth) "  "].join("");

        switch(expr.expr) {
            case TLocal(v) if (v.id == varId):
                trace('$indent[DEBUG] FOUND USAGE: TLocal(${v.name}) with id=$varId');
            case TCall(e, args):
                trace('$indent[DEBUG] TCall - checking function and ${args.length} args');
                debugTraverseForVariable(varId, e, depth + 1);
                for (arg in args) {
                    debugTraverseForVariable(varId, arg, depth + 1);
                }
            case TWhile(econd, body, _):
                trace('$indent[DEBUG] TWhile - checking condition and body');
                debugTraverseForVariable(varId, econd, depth + 1);
                debugTraverseForVariable(varId, body, depth + 1);
            case TBlock(exprs):
                trace('$indent[DEBUG] TBlock with ${exprs.length} expressions');
                for (e in exprs) {
                    debugTraverseForVariable(varId, e, depth + 1);
                }
            case TVar(v, init):
                trace('$indent[DEBUG] TVar(${v.name}, id=${v.id})');
                if (init != null) {
                    trace('$indent[DEBUG]   Has initialization expression');
                    debugTraverseForVariable(varId, init, depth + 1);
                }
            case TField(e, _):
                trace('$indent[DEBUG] TField');
                debugTraverseForVariable(varId, e, depth + 1);
            case TBinop(op, e1, e2):
                trace('$indent[DEBUG] TBinop');
                debugTraverseForVariable(varId, e1, depth + 1);
                debugTraverseForVariable(varId, e2, depth + 1);
            case TIf(econd, eif, eelse):
                trace('$indent[DEBUG] TIf');
                debugTraverseForVariable(varId, econd, depth + 1);
                debugTraverseForVariable(varId, eif, depth + 1);
                if (eelse != null) debugTraverseForVariable(varId, eelse, depth + 1);
            default:
                trace('$indent[DEBUG] Other: ${Type.enumConstructor(expr.expr)}');
        }
    }
    #end

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