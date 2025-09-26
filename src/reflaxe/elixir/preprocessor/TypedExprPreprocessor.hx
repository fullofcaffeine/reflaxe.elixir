package reflaxe.elixir.preprocessor;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.TypedExprDef;
import haxe.macro.TypedExprTools;
using Lambda;

/**
 * TypedExprPreprocessor: Infrastructure Variable Elimination at TypedExpr Level
 * 
 * ## What are Infrastructure Variables?
 * 
 * Infrastructure variables are compiler-generated temporary variables that Haxe creates
 * during the desugaring of high-level language constructs. These variables have names
 * following patterns like `g`, `_g`, `g1`, `g2`, `_g1`, `_g2`, etc.
 * 
 * ## Why Do They Exist?
 * 
 * When Haxe compiles high-level constructs (switch statements, for loops, etc.), it
 * transforms them into lower-level representations. This process often requires
 * temporary variables to hold intermediate values. For example:
 * 
 * ```haxe
 * // Original Haxe code
 * switch(obj.field) {
 *     case Value1: doSomething();
 *     case Value2: doOther();
 * }
 * 
 * // Haxe internally desugars to something like:
 * var _g = obj.field;  // Infrastructure variable!
 * switch(_g) {
 *     case Value1: doSomething();
 *     case Value2: doOther();
 * }
 * ```
 * 
 * ## Why Are They a Problem for Elixir?
 * 
 * 1. **Non-idiomatic Code**: Elixir developers expect clean pattern matching without
 *    temporary variables like `_g = field` followed by `case _g do`.
 * 
 * 2. **Readability**: Code with infrastructure variables looks machine-generated rather
 *    than hand-written, reducing maintainability.
 * 
 * 3. **Unnecessary Assignments**: Elixir's pattern matching can work directly on
 *    expressions, making these temporary variables redundant.
 * 
 * ## Our Solution
 * 
 * This preprocessor intercepts TypedExpr trees BEFORE they reach the AST builder and:
 * 1. Detects infrastructure variable patterns
 * 2. Substitutes variables with their original expressions
 * 3. Removes unnecessary temporary variable declarations
 * 4. Ensures the generated Elixir code is clean and idiomatic
 * 
 * ## Examples of Infrastructure Variable Patterns
 * 
 * ### Switch Pattern
 * ```
 * TVar(_g, field_expr) + TSwitch(TLocal(_g), cases, default)
 * → TSwitch(field_expr, cases, default)
 * ```
 * 
 * ### Nested Assignment Pattern
 * ```
 * TVar(_g, expr1) + TVar(output, TLocal(_g)) + TSwitch(TLocal(_g), ...)
 * → TVar(output, TSwitch(expr1, ...))
 * ```
 * 
 * ## Architecture Benefits
 * 
 * - **Single Responsibility**: Only handles infrastructure variable elimination
 * - **Early Intervention**: Fixes patterns before they reach AST builder
 * - **Clean Output**: Generated Elixir has no trace of infrastructure variables
 * - **Composable**: Works with existing LoopBuilder and other transformers
 * 
 * ## Edge Cases
 * 
 * - Nested switches may have multiple infrastructure variables (_g, _g1, _g2)
 * - Some patterns may legitimately use variables named `g` (unlikely but possible)
 * - Complex expressions might need careful substitution to preserve semantics
 * - Infrastructure variables in loop constructs are handled by LoopBuilder
 */
class TypedExprPreprocessor {
    
    /**
     * Infrastructure variable pattern matching g, g1, g2, _g, _g1, _g2, etc.
     */
    static final INFRASTRUCTURE_VAR_PATTERN = ~/^_?g[0-9]*$/;
    
    /**
     * Main entry point for preprocessing TypedExpr trees
     * 
     * WHY: Public API for the compiler to preprocess expressions
     * WHAT: Transforms a TypedExpr tree to eliminate infrastructure variables
     * HOW: First checks if the expression contains the pattern, then transforms if needed
     * 
     * @param expr The TypedExpr to preprocess
     * @return Transformed TypedExpr with infrastructure variables eliminated
     */
    public static function preprocess(expr: TypedExpr): TypedExpr {
        if (expr == null) {
            return null;
        }
        
        // Only process if expression contains infrastructure variable patterns
        // Don't try to filter TEnumParameter universally as it breaks pattern matching
        if (!containsInfrastructurePattern(expr)) {
            return expr; // No transformation needed
        }
        
        #if debug_preprocessor
        trace('[TypedExprPreprocessor] Starting preprocessing - pattern detected');
        #end
        
        // Create initial substitution map
        var substitutions = new Map<String, TypedExpr>();
        
        // Process the expression
        var result = processExpr(expr, substitutions);
        
        #if debug_preprocessor
        trace('[TypedExprPreprocessor] Preprocessing complete');
        trace('[TypedExprPreprocessor] Substitutions made: ${[for (k in substitutions.keys()) k]}');
        #end
        
        return result;
    }
    
    /**
     * Check if an expression contains infrastructure variable patterns
     * 
     * WHY: Avoid unnecessary transformations on expressions without the pattern
     * WHAT: Recursively checks for TVar with infrastructure variable names
     * HOW: Traverses the expression tree looking for specific patterns
     * 
     * @param expr Expression to check
     * @return True if the pattern is found
     */
    static function containsInfrastructurePattern(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
                // Found infrastructure variable assignment
                true;
            case TBlock(exprs):
                Lambda.exists(exprs, e -> containsInfrastructurePattern(e));
            case TReturn(e) if (e != null):
                containsInfrastructurePattern(e);
            case TFunction(func):
                func.expr != null && containsInfrastructurePattern(func.expr);
            case TIf(cond, e1, e2):
                containsInfrastructurePattern(cond) || 
                containsInfrastructurePattern(e1) || 
                (e2 != null && containsInfrastructurePattern(e2));
            case TSwitch(e, cases, edef):
                containsInfrastructurePattern(e) ||
                Lambda.exists(cases, c -> Lambda.exists(c.values, v -> containsInfrastructurePattern(v)) || 
                                          containsInfrastructurePattern(c.expr)) ||
                (edef != null && containsInfrastructurePattern(edef));
            case TTry(e, catches):
                containsInfrastructurePattern(e) ||
                Lambda.exists(catches, c -> containsInfrastructurePattern(c.expr));
            case TWhile(cond, e, _):
                containsInfrastructurePattern(cond) || containsInfrastructurePattern(e);
            case TFor(v, iter, e):
                containsInfrastructurePattern(iter) || containsInfrastructurePattern(e);
            default:
                false; // Most expressions don't contain the pattern
        };
    }
    
    /**
     * Process a TypedExpr with substitution tracking
     * 
     * WHY: Core transformation logic with variable substitution
     * WHAT: Recursively processes expressions, detecting patterns and applying transformations
     * HOW: Pattern matches on expression type and applies appropriate transformation
     * 
     * @param expr Expression to process
     * @param substitutions Map of variable names to substitute expressions
     * @return Transformed expression
     */
    static function processExpr(expr: TypedExpr, substitutions: Map<String, TypedExpr>): TypedExpr {
        return switch(expr.expr) {
            // Handle blocks that might contain switch patterns
            case TBlock(exprs):
                processBlock(exprs, expr.pos, expr.t, substitutions);
                
            // Handle local variable references that might need substitution
            case TLocal(v) if (substitutions.exists(v.name)):
                #if debug_preprocessor
                trace('[TypedExprPreprocessor] Substituting ${v.name} with original expression');
                #end
                substitutions.get(v.name);
                
            // Handle parenthesis - process the inner expression and preserve substitutions
            case TParenthesis(inner):
                var processedInner = processExpr(inner, substitutions);
                // If the inner expression was transformed, update the parenthesis
                if (processedInner != inner) {
                    {expr: TParenthesis(processedInner), pos: expr.pos, t: expr.t};
                } else {
                    expr;
                }
                
            // Handle switch statements directly (in case they're not in a block)
            case TSwitch(e, cases, edef):
                processSwitchExpr(e, cases, edef, expr.pos, expr.t, substitutions);
                
            // Skip TVar assignments for infrastructure variables that aren't used elsewhere
            case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
                // Infrastructure variable assignment - track for substitution
                substitutions.set(v.name, init);
                // Return empty block to skip generating the assignment
                {expr: TBlock([]), pos: expr.pos, t: expr.t};
                
            // Recursively process other expression types
            default:
                TypedExprTools.map(expr, e -> processExpr(e, substitutions));
        };
    }
    
    /**
     * Process a TBlock looking for infrastructure variable patterns
     * 
     * WHY: Most infrastructure variables are created in blocks before their usage
     * WHAT: Detects patterns like TVar(_g, expr) followed by TSwitch(TLocal(_g))
     * HOW: Scans block statements, identifies patterns, and transforms them
     * 
     * PATTERN DETECTED:
     * TBlock([
     *   TVar(_g, field_expr),     // Infrastructure variable assignment
     *   TSwitch(TLocal(_g), ...)  // Switch using infrastructure variable
     * ])
     * 
     * TRANSFORMS TO:
     * TSwitch(field_expr, ...)     // Direct switch on original expression
     */
    static function processBlock(exprs: Array<TypedExpr>, pos: haxe.macro.Expr.Position, t: Type, substitutions: Map<String, TypedExpr>): TypedExpr {
        var processed = [];
        var i = 0;
        
        while (i < exprs.length) {
            var current = exprs[i];
            
            // Check for infrastructure variable pattern
            if (i < exprs.length - 1) {
                switch(current.expr) {
                    case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
                        var next = exprs[i + 1];
                        
                        #if debug_preprocessor
                        trace('[TypedExprPreprocessor] Found infrastructure variable: ${v.name}');
                        trace('[TypedExprPreprocessor] Next expression type: ${next.expr}');
                        #end
                        
                        // Check if next expression is a switch using this variable
                        switch(next.expr) {
                            case TSwitch(e, cases, edef):
                                if (usesVariable(e, v.name)) {
                                    #if debug_preprocessor
                                    trace('[TypedExprPreprocessor] Detected switch pattern with ${v.name}');
                                    #end
                                    
                                    // Transform: substitute the variable with its initialization
                                    var transformedSwitch = processSwitchExpr(
                                        substituteVariable(e, v.name, init),
                                        cases,
                                        edef,
                                        next.pos,
                                        next.t,
                                        substitutions
                                    );
                                    
                                    // Skip the TVar and add the transformed switch
                                    processed.push(transformedSwitch);
                                    i += 2; // Skip both TVar and TSwitch
                                    continue;
                                }
                            
                            case TVar(v2, init2) if (init2 != null):
                                // Check for assignment pattern: output = _g = expr
                                switch(init2.expr) {
                                    case TLocal(localVar) if (localVar.name == v.name):
                                        #if debug_preprocessor
                                        trace('[TypedExprPreprocessor] Found assignment pattern: ${v2.name} = ${v.name} = ...');
                                        #end
                                        
                                        // Look ahead for switch
                                        if (i + 2 < exprs.length) {
                                            var third = exprs[i + 2];
                                            switch(third.expr) {
                                                case TSwitch(e, cases, edef) if (usesVariable(e, v.name)):
                                                    // Transform the whole pattern
                                                    var transformedSwitch = processSwitchExpr(
                                                        substituteVariable(e, v.name, init),
                                                        cases,
                                                        edef,
                                                        third.pos,
                                                        third.t,
                                                        substitutions
                                                    );
                                                    
                                                    // Create direct assignment of switch result
                                                    var assignment = {
                                                        expr: TVar(v2, transformedSwitch),
                                                        pos: current.pos,
                                                        t: current.t
                                                    };
                                                    
                                                    processed.push(assignment);
                                                    i += 3; // Skip all three expressions
                                                    continue;
                                                    
                                                default:
                                            }
                                        }
                                        
                                    default:
                                }
                                
                            default:
                        }
                        
                        // If no pattern matched, track substitution for later use
                        substitutions.set(v.name, init);
                        // Don't add the TVar to processed (skip it)
                        i++;
                        continue;
                        
                    default:
                }
            }
            
            // Process the current expression normally
            processed.push(processExpr(current, substitutions));
            i++;
        }
        
        // Return the transformed block
        return {
            expr: TBlock(processed),
            pos: pos,
            t: t
        };
    }
    
    /**
     * Process a switch expression with substitutions
     * 
     * WHY: Switch expressions might reference infrastructure variables
     * WHAT: Applies substitutions and processes cases  
     * HOW: Recursively processes switch target and case expressions
     * 
     * SPECIAL HANDLING: Removes orphaned g variable assignments in case bodies
     */
    static function processSwitchExpr(e: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, edef: Null<TypedExpr>, 
                                      pos: haxe.macro.Expr.Position, t: Type, 
                                      substitutions: Map<String, TypedExpr>): TypedExpr {
        // Process the switch target
        var processedTarget = processExpr(e, substitutions);
        
        // Process cases with special handling for orphaned assignments
        var processedCases = cases.map(c -> {
            // Process case body and filter out orphaned infrastructure variable assignments
            var processedBody = switch(c.expr.expr) {
                case TBlock(exprs):
                    // Filter out orphaned g variable assignments at the start of blocks
                    var filteredExprs = [];
                    for (expr in exprs) {
                        switch(expr.expr) {
                            case TVar(v, init) if (isInfrastructureVar(v.name) && init != null):
                                // Check if this is an orphaned enum parameter extraction
                                switch(init.expr) {
                                    case TEnumParameter(_, _, _):
                                        #if debug_preprocessor
                                        trace('[TypedExprPreprocessor] Filtering orphaned assignment in case body: ${v.name}');
                                        #end
                                        // Skip this assignment
                                        continue;
                                    default:
                                        // Keep other assignments
                                        filteredExprs.push(processExpr(expr, substitutions));
                                }
                            default:
                                filteredExprs.push(processExpr(expr, substitutions));
                        }
                    }
                    {expr: TBlock(filteredExprs), pos: c.expr.pos, t: c.expr.t};
                    
                default:
                    processExpr(c.expr, substitutions);
            };
            
            {
                values: c.values.map(v -> processExpr(v, substitutions)),
                expr: processedBody
            }
        });
        
        // Process default case
        var processedDefault = edef != null ? processExpr(edef, substitutions) : null;
        
        return {
            expr: TSwitch(processedTarget, processedCases, processedDefault),
            pos: pos,
            t: t
        };
    }
    
    /**
     * Check if a variable name matches the infrastructure pattern
     * 
     * Infrastructure variables are compiler-generated temporaries with names like:
     * - g, g1, g2, g3, ...
     * - _g, _g1, _g2, _g3, ...
     * 
     * WHY: Need to identify infrastructure variables consistently
     * WHAT: Returns true if the name matches g, g1, _g, _g1, etc.
     * HOW: Uses regex pattern matching
     */
    public static function isInfrastructureVar(name: String): Bool {
        return INFRASTRUCTURE_VAR_PATTERN.match(name);
    }
    
    /**
     * Check if an expression uses a specific variable
     * 
     * WHY: Need to detect when infrastructure variables are referenced
     * WHAT: Returns true if the expression contains TLocal(varName)
     * HOW: Recursively traverses the expression tree
     */
    static function usesVariable(expr: TypedExpr, varName: String): Bool {
        var found = false;
        
        function check(e: TypedExpr): TypedExpr {
            switch(e.expr) {
                case TLocal(v) if (v.name == varName):
                    found = true;
                default:
            }
            if (!found) {
                TypedExprTools.iter(e, check);
            }
            return e;
        }
        
        check(expr);
        return found;
    }
    
    /**
     * Substitute all occurrences of a variable with another expression
     * 
     * WHY: Need to replace infrastructure variables with their original expressions
     * WHAT: Returns a new expression with all TLocal(varName) replaced
     * HOW: Recursively maps over the expression tree
     */
    static function substituteVariable(expr: TypedExpr, varName: String, replacement: TypedExpr): TypedExpr {
        return TypedExprTools.map(expr, function(e: TypedExpr): TypedExpr {
            return switch(e.expr) {
                case TLocal(v) if (v.name == varName):
                    replacement;
                default:
                    e;
            };
        });
    }
}

#end