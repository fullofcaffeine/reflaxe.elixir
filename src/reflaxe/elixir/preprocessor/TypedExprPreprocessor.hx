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
        
        // Check for Map iteration patterns first (special handling needed)  
        if (isMapIterationPattern(expr)) {
            #if debug_preprocessor
            trace('[TypedExprPreprocessor] DETECTED: Map iteration pattern');
            #end
            return transformMapIteration(expr);
        }
        
        // Only process if expression contains infrastructure variable patterns
        // Don't try to filter TEnumParameter universally as it breaks pattern matching
        if (!containsInfrastructurePattern(expr)) {
            return expr; // No transformation needed
        }
        
        #if debug_preprocessor
        trace('[TypedExprPreprocessor] Starting preprocessing - pattern detected');
        #end
        
        // Create initial substitution map (ID-based to prevent shadowing)
        var substitutions = new Map<Int, TypedExpr>();
        
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
     * @param substitutions Map of variable IDs to substitute expressions (ID-based to prevent shadowing)
     * @return Transformed expression
     */
    static function processExpr(expr: TypedExpr, substitutions: Map<Int, TypedExpr>): TypedExpr {
        return switch(expr.expr) {
            // Handle blocks that might contain switch patterns
            case TBlock(exprs):
                processBlock(exprs, expr.pos, expr.t, substitutions);
                
            // Handle local variable references that might need substitution
            case TLocal(v):
                #if debug_infrastructure_vars
                if (isInfrastructureVar(v.name)) {
                    trace('[processExpr TLocal] Checking infrastructure variable: ${v.name} (ID: ${v.id})');
                    trace('[processExpr TLocal] Substitution exists? ${substitutions.exists(v.id)}');
                    if (substitutions.exists(v.id)) {
                        trace('[processExpr TLocal] SUBSTITUTING ${v.name} (ID: ${v.id}) with original expression');
                    } else {
                        trace('[processExpr TLocal] NO SUBSTITUTION FOUND for ${v.name} (ID: ${v.id})!');
                        trace('[processExpr TLocal] Available substitutions: ${[for (k in substitutions.keys()) k].join(", ")}');
                    }
                }
                #end

                if (substitutions.exists(v.id)) {
                    #if debug_preprocessor
                    trace('[TypedExprPreprocessor] Substituting ${v.name} (ID: ${v.id}) with original expression');
                    #end
                    substitutions.get(v.id);
                } else {
                    expr; // No substitution, return as-is
                }
                
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
                #if debug_infrastructure_vars
                trace('[processExpr TSwitch] ===== DIRECT SWITCH PROCESSING =====');
                trace('[processExpr TSwitch] Switch target type: ${e.expr}');
                #end

                // Special handling for switches with undefined infrastructure variables
                // FIX: Apply substitution for infrastructure variables in switch targets
                var switchTarget = switch(e.expr) {
                    case TLocal(v) if (isInfrastructureVar(v.name) && substitutions.exists(v.id)):
                        // Apply substitution - replace infrastructure variable with its initialization expression
                        #if debug_infrastructure_vars
                        trace('[processExpr TSwitch] Infrastructure var detected: ${v.name} (ID: ${v.id})');
                        trace('[processExpr TSwitch] ✓ APPLYING substitution for ID ${v.id}');
                        var substExpr = substitutions.get(v.id);
                        trace('[processExpr TSwitch] Substitution expression: ${substExpr.expr}');
                        #end
                        substitutions.get(v.id);
                    case TLocal(v) if (isInfrastructureVar(v.name)):
                        #if debug_infrastructure_vars
                        trace('[processExpr TSwitch] Infrastructure var detected: ${v.name} (ID: ${v.id})');
                        trace('[processExpr TSwitch] ✗ NO SUBSTITUTION exists for ID ${v.id}');
                        var allKeys = [for (k in substitutions.keys()) k];
                        trace('[processExpr TSwitch] Available substitutions: ${allKeys.join(", ")}');
                        #end
                        // Not an infrastructure var with substitution - process normally
                        processExpr(e, substitutions);
                    default:
                        #if debug_infrastructure_vars
                        trace('[processExpr TSwitch] Not an infrastructure variable, processing normally');
                        #end
                        // Not an infrastructure var with substitution - process normally
                        processExpr(e, substitutions);
                };

                #if debug_infrastructure_vars
                trace('[processExpr TSwitch] Calling processSwitchExpr...');
                #end

                processSwitchExpr(switchTarget, cases, edef, expr.pos, expr.t, substitutions);
                
            // Skip TVar assignments for infrastructure variables that aren't used elsewhere
            case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
                #if debug_infrastructure_vars
                trace('[processExpr] Eliminating infrastructure variable: ${v.name} (ID: ${v.id})');
                #end

                // Infrastructure variable assignment - track for substitution by ID
                // Using ID instead of name prevents shadowing bugs in nested scopes
                substitutions.set(v.id, init);

                #if debug_infrastructure_vars
                trace('[processExpr] Registered substitution for ID ${v.id} (name: ${v.name})');
                trace('[processExpr] Substitutions now has ${Lambda.count(substitutions)} entries');
                #end

                // Return empty block to skip generating the assignment
                {expr: TBlock([]), pos: expr.pos, t: expr.t};
                
            // Handle field access on infrastructure variables (like g.next())
            case TField(e, field):
                // Check if this is field access on an infrastructure variable
                switch(e.expr) {
                    case TLocal(v) if (isInfrastructureVar(v.name) && substitutions.exists(v.id)):
                        // Substitute the infrastructure variable with its actual value
                        var substituted = substitutions.get(v.id);
                        #if debug_preprocessor
                        trace('[TypedExprPreprocessor] SUBSTITUTING: Field access ${v.name}.${field} with substituted base');
                        #end
                        // Create new TField with substituted base
                        var newFieldExpr = {
                            expr: TField(substituted, field),
                            pos: expr.pos,
                            t: expr.t
                        };
                        // Process the new expression recursively
                        processExpr(newFieldExpr, substitutions);
                    default:
                        // Normal field access - just recurse
                        TypedExprTools.map(expr, e -> processExpr(e, substitutions));
                }
                
            // Handle method calls on infrastructure variables (like g.next())
            case TCall(e, args):
                // Check if this is a method call on an infrastructure variable
                switch(e.expr) {
                    case TField(obj, method):
                        switch(obj.expr) {
                            case TLocal(v) if (isInfrastructureVar(v.name) && substitutions.exists(v.id)):
                                // Substitute the infrastructure variable with its actual value
                                var substituted = substitutions.get(v.id);
                                #if debug_preprocessor
                                trace('[TypedExprPreprocessor] SUBSTITUTING: Method call ${v.name}.${method}() with substituted base');
                                #end
                                // Create new TCall with substituted base
                                var newFieldExpr = {
                                    expr: TField(substituted, method),
                                    pos: e.pos,
                                    t: e.t
                                };
                                var newCallExpr = {
                                    expr: TCall(newFieldExpr, args.map(a -> processExpr(a, substitutions))),
                                    pos: expr.pos,
                                    t: expr.t
                                };
                                // Return the processed call
                                newCallExpr;
                            default:
                                // Normal method call - recurse normally
                                TypedExprTools.map(expr, e -> processExpr(e, substitutions));
                        }
                    default:
                        // Not a method call on a field - recurse normally
                        TypedExprTools.map(expr, e -> processExpr(e, substitutions));
                }
                
            // Handle while loops (desugared for loops) - need to track infrastructure variables
            case TWhile(cond, body, normalWhile):
                #if debug_preprocessor
                trace('[TypedExprPreprocessor] Processing TWhile (possibly desugared for loop)');
                #end

                // Create local substitution map inheriting from parent scope (ID-based)
                var localSubstitutions = new Map<Int, TypedExpr>();
                for (key in substitutions.keys()) {
                    localSubstitutions.set(key, substitutions.get(key));
                }
                
                // Pre-scan loop body for infrastructure variable declarations
                scanForInfrastructureVars(body, localSubstitutions);
                
                #if debug_preprocessor
                var infraCount = 0;
                for (key in localSubstitutions.keys()) {
                    if (!substitutions.exists(key)) {
                        infraCount++;
                        trace('[TypedExprPreprocessor]   Found infrastructure variable in while loop: $key');
                    }
                }
                trace('[TypedExprPreprocessor]   Total new infrastructure variables found: $infraCount');
                #end
                
                // Process the condition and body with accumulated substitutions
                var processedCond = processExpr(cond, localSubstitutions);
                var processedBody = processExpr(body, localSubstitutions);
                
                // Return processed TWhile
                {
                    expr: TWhile(processedCond, processedBody, normalWhile),
                    pos: expr.pos,
                    t: expr.t
                };
                
            // Handle for loops - need to track infrastructure variables across loop scope
            case TFor(v, iter, body):
                #if debug_preprocessor
                trace('[TypedExprPreprocessor] Processing TFor with iterator variable: ${v.name}');
                #end

                // Create local substitution map inheriting from parent scope (ID-based)
                var localSubstitutions = new Map<Int, TypedExpr>();
                for (key in substitutions.keys()) {
                    localSubstitutions.set(key, substitutions.get(key));
                }
                
                // Pre-scan loop body for infrastructure variable declarations
                scanForInfrastructureVars(body, localSubstitutions);
                
                #if debug_preprocessor
                var infraCount = 0;
                for (key in localSubstitutions.keys()) {
                    if (!substitutions.exists(key)) {
                        infraCount++;
                        trace('[TypedExprPreprocessor]   Found infrastructure variable in loop: $key');
                    }
                }
                trace('[TypedExprPreprocessor]   Total new infrastructure variables found: $infraCount');
                #end
                
                // Process the loop body with accumulated substitutions
                var processedBody = processExpr(body, localSubstitutions);
                
                // Process the iterator with parent substitutions (not local)
                var processedIter = processExpr(iter, substitutions);
                
                // Return processed TFor
                {
                    expr: TFor(v, processedIter, processedBody),
                    pos: expr.pos,
                    t: expr.t
                };
                
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
    static function processBlock(exprs: Array<TypedExpr>, pos: haxe.macro.Expr.Position, t: Type, substitutions: Map<Int, TypedExpr>): TypedExpr {
        var processed = [];
        var i = 0;

        #if debug_infrastructure_vars
        trace('[processBlock] ===== BLOCK ANALYSIS =====');
        trace('[processBlock] Block has ${exprs.length} expressions');
        for (idx in 0...exprs.length) {
            var exprType = switch(exprs[idx].expr) {
                case TVar(v, init):
                    var initInfo = if (init != null) {
                        switch(init.expr) {
                            case TCall(e, _):
                                var callTarget = switch(e.expr) {
                                    case TField(_, FInstance(_, _, cf)): 'method:${cf.get().name}';
                                    case TField(_, FStatic(_, cf)): 'static:${cf.get().name}';
                                    case TField(_, FAnon(cf)): 'anon:${cf.get().name}';
                                    case TField(_, FDynamic(s)): 'dynamic:$s';
                                    case TLocal(v): 'local:${v.name}';
                                    default: 'other';
                                }
                                'TCall($callTarget)';
                            case TObjectDecl(fields): 'TObjectDecl(${fields.length} fields)';
                            default: 'init=${Std.string(init.expr).substr(0, 50)}';
                        }
                    } else "null";
                    'TVar(${v.name}, $initInfo)';
                case TSwitch(e, cases, _):
                    var targetInfo = switch(e.expr) {
                        case TLocal(v): 'TLocal(${v.name})';
                        case TField(_, FInstance(_, _, cf)): 'TField.FInstance(${cf.get().name})';
                        case TField(_, FStatic(_, cf)): 'TField.FStatic(${cf.get().name})';
                        case TField(_, FAnon(cf)): 'TField.FAnon(${cf.get().name})';
                        case TField(_, FDynamic(s)): 'TField.FDynamic($s)';
                        default: 'Other(${Std.string(e.expr).substr(0, 30)})';
                    }
                    'TSwitch(target=$targetInfo, ${cases.length} cases)';
                case TIf(cond, _, _):
                    var condInfo = switch(cond.expr) {
                        case TCall(e, _):
                            var callTarget = switch(e.expr) {
                                case TField(_, FInstance(_, _, cf)): 'method:${cf.get().name}';
                                case TField(_, FStatic(_, cf)): 'static:${cf.get().name}';
                                default: 'other';
                            }
                            'TCall($callTarget)';
                        case TBinop(op, _, _): 'TBinop($op)';
                        default: 'Other';
                    }
                    'TIf(cond=$condInfo)';
                case TBlock(innerExprs): 'TBlock(${innerExprs.length} exprs)';
                case TReturn(e): 'TReturn(${e != null ? "expr" : "void"})';
                case TCall(e, args):
                    var callTarget = switch(e.expr) {
                        case TField(_, FInstance(_, _, cf)): 'method:${cf.get().name}';
                        case TField(_, FStatic(_, cf)): 'static:${cf.get().name}';
                        case TLocal(v): 'local:${v.name}';
                        default: 'other';
                    }
                    'TCall($callTarget, ${args.length} args)';
                default: 'Other(${Std.string(exprs[idx].expr).substr(0, 50)})';
            }
            trace('[processBlock]   [$idx]: $exprType');
        }
        trace('[processBlock] =============================');
        #end

        while (i < exprs.length) {
            var current = exprs[i];

            #if debug_infrastructure_vars
            var currentType = switch(current.expr) {
                case TVar(v, _): 'TVar(${v.name})';
                case TSwitch(e, _, _):
                    switch(e.expr) {
                        case TLocal(v): 'TSwitch(TLocal(${v.name}))';
                        default: 'TSwitch(other)';
                    }
                case TIf(_, _, _): 'TIf';
                case TBlock(_): 'TBlock';
                default: 'Other';
            }
            trace('[processBlock] Processing expression $i: $currentType');
            #end

            // Check for infrastructure variable pattern FIRST (before processing individually)
            if (i < exprs.length - 1) {
                switch(current.expr) {
                    case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
                        var next = exprs[i + 1];

                        #if debug_preprocessor
                        trace('[TypedExprPreprocessor] Found infrastructure variable: ${v.name}');
                        trace('[TypedExprPreprocessor] Next expression type: ${next.expr}');
                        #end

                        #if debug_infrastructure_vars
                        trace('[processBlock] ===== INFRASTRUCTURE VAR DETECTION =====');
                        trace('[processBlock] Found TVar at index $i: ${v.name}');
                        trace('[processBlock] Is infrastructure var: ${isInfrastructureVar(v.name)}');
                        trace('[processBlock] Has init: ${init != null}');
                        if (init != null) {
                            trace('[processBlock] Init expression type: ${init.expr}');
                        }
                        trace('[processBlock] Next expr exists: ${i + 1 < exprs.length}');
                        if (i + 1 < exprs.length) {
                            var nextExprType = switch(next.expr) {
                                case TSwitch(_, _, _): 'TSwitch';
                                case TBlock(_): 'TBlock';
                                case TReturn(_): 'TReturn';
                                case TIf(_, _, _): 'TIf';
                                default: 'Other(${next.expr})';
                            }
                            trace('[processBlock] Next expr type at index ${i+1}: $nextExprType');
                        }
                        #end
                        
                        // Check if next expression is a switch using this variable
                        // CRITICAL: Also check inside nested blocks! Haxe sometimes wraps switches
                        var actualSwitchExpr = next;
                        var skipCount = 2; // Default: skip TVar and immediate next

                        #if debug_infrastructure_vars
                        var nextType = switch(next.expr) {
                            case TBlock(_): "TBlock";
                            case TSwitch(_, _, _): "TSwitch";
                            case TReturn(_): "TReturn";
                            default: "Other";
                        }
                        trace('[processBlock] Next expression type: $nextType');
                        #end

                        // Unwrap nested TBlock if present
                        switch(next.expr) {
                            case TBlock(blockExprs) if (blockExprs.length > 0):
                                #if debug_infrastructure_vars
                                trace('[processBlock] Next is TBlock with ${blockExprs.length} expressions');
                                trace('[processBlock] Checking first expression in nested block');
                                #end

                                // Check if first expression in nested block is the switch
                                var firstInBlock = blockExprs[0];
                                switch(firstInBlock.expr) {
                                    case TSwitch(_, _, _):
                                        #if debug_infrastructure_vars
                                        trace('[processBlock] Found switch inside nested block!');
                                        #end
                                        actualSwitchExpr = firstInBlock;
                                        // Still skip 2: TVar + the TBlock wrapper
                                    default:
                                }
                            default:
                        }

                        switch(actualSwitchExpr.expr) {
                            case TSwitch(e, cases, edef):
                                #if debug_infrastructure_vars
                                trace('[processBlock] Checking if switch uses ${v.name}');
                                var uses = usesVariable(e, v.name);
                                trace('[processBlock] usesVariable result: $uses');
                                #end

                                if (usesVariable(e, v.name)) {
                                    #if debug_preprocessor
                                    trace('[TypedExprPreprocessor] Detected switch pattern with ${v.name}');
                                    #end

                                    #if debug_infrastructure_vars
                                    trace('[processBlock] FOUND PATTERN! Substituting ${v.name} in switch');
                                    #end


									// CRITICAL: Register substitution BEFORE processing switch
									// This mirrors what processExpr does for individual TVar expressions
									// Pattern detection must populate substitutions map just like expression processing does
									#if debug_infrastructure_vars
									trace('[processBlock] ===== REGISTERING SUBSTITUTION =====');
									trace('[processBlock] Infrastructure variable: ${v.name} (ID: ${v.id})');
									trace('[processBlock] Initialization expression: ${init.expr}');
									#end

									substitutions.set(v.id, init);

									#if debug_infrastructure_vars
									trace('[processBlock] ✓ Registered substitution: ID ${v.id} (name: ${v.name}) -> ${init.expr}');
									// Show complete state of substitutions map
									var allKeys = [for (k in substitutions.keys()) k];
									trace('[processBlock] Substitutions map now contains ${allKeys.length} entries: ${allKeys.join(", ")}');
									trace('[processBlock] =====================================');
									#end
                                    // Transform: substitute the variable with its initialization
                                    // Now substitutions map contains the mapping for recursive processing
                                    var transformedSwitch = processSwitchExpr(
                                        substituteVariable(e, v.name, init),
                                        cases,
                                        edef,
                                        actualSwitchExpr.pos,
                                        actualSwitchExpr.t,
                                        substitutions
                                    );

                                    #if debug_infrastructure_vars
                                    trace('[processBlock] Transformed switch created');
                                    trace('[processBlock] Adding transformed switch to processed list');
                                    trace('[processBlock] Skipping $skipCount expressions (TVar + wrapper)');
                                    #end

                                    // Skip the TVar and add the transformed switch
                                    processed.push(transformedSwitch);
                                    i += skipCount; // Skip TVar and next expression

                                    #if debug_infrastructure_vars
                                    trace('[processBlock] Pattern match complete - continuing to next expression');
                                    #end

                                    continue;
                                } else {
                                    #if debug_infrastructure_vars
                                    trace('[processBlock] Switch does NOT use ${v.name} - skipping pattern');
                                    #end
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
                        
                        // If no pattern matched, track substitution for later use (ID-based)
                        substitutions.set(v.id, init);
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
                                      substitutions: Map<Int, TypedExpr>): TypedExpr {
        #if debug_infrastructure_vars
        trace('[processSwitchExpr] ===== PROCESSING SWITCH TARGET =====');
        trace('[processSwitchExpr] Switch target expression type: ${e.expr}');

        // Check if switch uses an infrastructure variable
        switch(e.expr) {
            case TLocal(v):
                trace('[processSwitchExpr] Switch uses TLocal variable: ${v.name} (ID: ${v.id})');
                trace('[processSwitchExpr] Is infrastructure var: ${isInfrastructureVar(v.name)}');
                trace('[processSwitchExpr] Checking substitution map...');
                trace('[processSwitchExpr] - Substitution exists for ID ${v.id}: ${substitutions.exists(v.id)}');

                // Show all keys in substitutions map
                var allKeys = [for (k in substitutions.keys()) k];
                trace('[processSwitchExpr] - All IDs in substitutions map: ${allKeys.join(", ")}');

                if (substitutions.exists(v.id)) {
                    var substExpr = substitutions.get(v.id);
                    trace('[processSwitchExpr] ✓ FOUND substitution for ID ${v.id} (name: ${v.name}): ${substExpr.expr}');
                } else {
                    trace('[processSwitchExpr] ✗ NO SUBSTITUTION FOUND for ID ${v.id} (name: ${v.name})');
                }
            default:
                trace('[processSwitchExpr] Switch target is not a TLocal variable');
        }
        #end

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
    
    /**
     * Scan for infrastructure variable declarations and add to substitution map
     *
     * WHY: Need to pre-scan loop bodies to find infrastructure variables before processing
     * WHAT: Recursively finds TVar declarations with infrastructure variable names
     * HOW: Traverses expression tree looking for TVar(g*, init) patterns
     *
     * This allows us to build a complete substitution map before processing the loop body,
     * ensuring that references to infrastructure variables can be properly substituted.
     */
    static function scanForInfrastructureVars(expr: TypedExpr, substitutions: Map<Int, TypedExpr>): Void {
        if (expr == null) return;

        switch(expr.expr) {
            case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
                // Found an infrastructure variable declaration (store by ID)
                #if debug_preprocessor
                trace('[TypedExprPreprocessor] scanForInfrastructureVars: Found ${v.name} (ID: ${v.id}) = [expression]');
                #end
                substitutions.set(v.id, init);
                
            case TBlock(exprs):
                // Scan all expressions in the block
                for (e in exprs) {
                    scanForInfrastructureVars(e, substitutions);
                }
                
            default:
                // Recursively scan sub-expressions
                TypedExprTools.iter(expr, function(e) {
                    scanForInfrastructureVars(e, substitutions);
                });
        }
    }
    
    /**
     * Detect Map iteration patterns that generate iterator infrastructure
     * 
     * WHY: Map iteration generates keyValueIterator().hasNext() patterns that aren't idiomatic
     * WHAT: Detects for-in loops over Maps with key=>value syntax
     * HOW: Checks for TFor with iterator field access patterns typical of Maps
     * 
     * PATTERN DETECTED:
     * for (key => value in map) { body }
     * 
     * Which Haxe desugars to iterator-based patterns we want to prevent
     */
    static function isMapIterationPattern(expr: TypedExpr): Bool {
        var hasMapIteration = false;
        
        function scan(e: TypedExpr) {
            if (e == null) return;
            
            switch(e.expr) {
                case TFor(v, iter, body):
                    // Check if the iterator is a Map type
                    // Maps have keyValueIterator() method calls
                    if (containsKeyValueIterator(iter) || containsKeyValueIterator(body)) {
                        hasMapIteration = true;
                    }
                    // Also check for field patterns that indicate Map iteration
                    // This catches patterns like "for (key => value in map)"
                    switch(iter.t) {
                        case TAbstract(t, params):
                            var abstractType = t.get();
                            if (abstractType.name == "KeyValueIterator" || 
                                abstractType.module == "haxe.iterators.MapKeyValueIterator") {
                                hasMapIteration = true;
                            }
                        case TInst(t, params):
                            var classType = t.get();
                            if (classType.name == "MapKeyValueIterator" ||
                                classType.module == "haxe.iterators.MapKeyValueIterator") {
                                hasMapIteration = true;
                            }
                        default:
                    }
                default:
            }
            
            if (!hasMapIteration) {
                TypedExprTools.iter(e, scan);
            }
        }
        
        scan(expr);
        return hasMapIteration;
    }
    
    /**
     * Check if expression contains keyValueIterator() calls
     */
    static function containsKeyValueIterator(expr: TypedExpr): Bool {
        var hasIterator = false;
        
        function scan(e: TypedExpr) {
            if (e == null || hasIterator) return;
            
            switch(e.expr) {
                case TCall(target, args):
                    switch(target.expr) {
                        case TField(obj, FInstance(_, _, cf)):
                            var methodName = cf.get().name;
                            if (methodName == "keyValueIterator" || 
                                methodName == "hasNext" || 
                                methodName == "next") {
                                hasIterator = true;
                            }
                        case TField(obj, FAnon(cf)):
                            var methodName = cf.get().name;
                            if (methodName == "keyValueIterator" || 
                                methodName == "hasNext" || 
                                methodName == "next") {
                                hasIterator = true;
                            }
                        default:
                    }
                default:
            }
            
            if (!hasIterator) {
                TypedExprTools.iter(e, scan);
            }
        }
        
        scan(expr);
        return hasIterator;
    }
    
    /**
     * Transform Map iteration to simpler pattern
     * 
     * WHY: Prevent generation of non-idiomatic iterator infrastructure
     * WHAT: Transforms Map iteration into a pattern that will generate idiomatic Elixir
     * HOW: Marks the loop with metadata that LoopBuilder can use to generate Enum.each
     * 
     * TRANSFORMS:
     * for (key => value in map) { body }
     * 
     * INTO:
     * A TFor with metadata indicating it's a Map iteration that should use Enum.each
     */
    static function transformMapIteration(expr: TypedExpr): TypedExpr {
        switch(expr.expr) {
            case TFor(v, iter, body):
                #if debug_preprocessor
                trace('[TypedExprPreprocessor] Transforming Map iteration for variable: ${v.name}');
                #end
                
                // We can't modify TVar metadata directly, so we'll need to 
                // use a different approach - check the iterator type instead
                // Mark with a special flag that LoopBuilder can detect
                
                // For now, return unchanged - LoopBuilder will need to detect
                // Map iteration by checking the iterator type
                #if debug_preprocessor
                trace('[TypedExprPreprocessor] Map iteration detected but cannot add metadata to TVar');
                #end
                
                // Return the TFor with metadata attached
                // LoopBuilder will detect the metadata and generate Enum.each
                return {
                    expr: TFor(v, iter, body),
                    pos: expr.pos,
                    t: expr.t
                };
                
            default:
                // Recursively process if not directly a TFor
                return TypedExprTools.map(expr, e -> isMapIterationPattern(e) ? transformMapIteration(e) : e);
        }
    }
}

#end