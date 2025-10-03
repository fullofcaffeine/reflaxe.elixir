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
     * Last substitution map from preprocessing
     * Used to pass substitution context to builders that re-compile sub-expressions
     *
     * WHY: Band-aid fix - Builders re-compile original TypedExpr nodes,
     *      losing preprocessor substitutions. This preserves them.
     * WHAT: Maps TVar.id to the substituted TypedExpr
     * HOW: Updated by preprocess(), read by getLastSubstitutions()
     */
    static var lastSubstitutions: Map<Int, TypedExpr> = new Map();

    /**
     * Get the substitution map from the last preprocessing run
     *
     * WHY: Allow ElixirCompiler to capture substitutions for context
     * WHAT: Returns the substitution map created during last preprocess() call
     * HOW: Simply returns the static field set by preprocess()
     *
     * @return Map of TVar.id → substituted TypedExpr
     */
    public static function getLastSubstitutions(): Map<Int, TypedExpr> {
        return lastSubstitutions;
    }

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

        // Simplified debug output - just track what we're processing
        #if debug_preprocessor
        trace('[Preprocessor] Processing expression');
        #end

        // Check for Map iteration patterns first (special handling needed)
        if (isMapIterationPattern(expr)) {
            #if debug_preprocessor
            trace('[TypedExprPreprocessor] DETECTED: Map iteration pattern');
            #end
            return transformMapIteration(expr);
        }

        // Only process if expression contains infrastructure variable patterns
        // Don't try to filter TEnumParameter universally as it breaks pattern matching
        #if debug_preprocessor
        trace('[TypedExprPreprocessor] Checking for infrastructure pattern...');
        #end

        if (!containsInfrastructurePattern(expr)) {
            #if debug_preprocessor
            trace('[TypedExprPreprocessor] No pattern found, returning early');
            #end
            return expr; // No transformation needed
        }

        #if debug_preprocessor
        trace('[TypedExprPreprocessor] Starting preprocessing - pattern detected');
        #end

        // CRITICAL FIX: Use existing substitutions map instead of creating new one
        // This allows accumulation across multiple preprocess() calls
        var substitutions = lastSubstitutions != null ? lastSubstitutions : new Map<Int, TypedExpr>();

        // Process the expression
        var result = processExpr(expr, substitutions);

        // Store/update substitutions for later retrieval by compiler
        lastSubstitutions = substitutions;

        #if debug_preprocessor
        trace('[TypedExprPreprocessor] Preprocessing complete');
        trace('[TypedExprPreprocessor] Substitutions created: ${Lambda.count(substitutions)} entries');
        if (Lambda.count(substitutions) > 0) {
            trace('[TypedExprPreprocessor] ===== SUBSTITUTION MAP CONTENTS =====');
            for (id in substitutions.keys()) {
                var subExpr = substitutions.get(id);
                var exprType = Type.enumConstructor(subExpr.expr);
                trace('[TypedExprPreprocessor]   ID ${id} => ${exprType}');
            }
            trace('[TypedExprPreprocessor] ====================================');
        } else {
            trace('[TypedExprPreprocessor] WARNING: No substitutions were created!');
        }
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
        #if debug_preprocessor
        var exprType = Type.enumConstructor(expr.expr);
        #end

        var result = switch(expr.expr) {
            case TVar(v, init):
                var isInfra = init != null && isInfrastructureVar(v.name);
                #if debug_preprocessor
                trace('[containsInfrastructurePattern] Found TVar: ${v.name} (ID: ${v.id}), init=${init != null}, isInfra=$isInfra');
                #end
                isInfra;
            case TBlock(exprs):
                #if debug_preprocessor
                trace('[containsInfrastructurePattern] Checking TBlock with ${exprs.length} exprs');
                #end
                Lambda.exists(exprs, e -> containsInfrastructurePattern(e));
            case TReturn(e) if (e != null):
                #if debug_preprocessor
                trace('[containsInfrastructurePattern] Checking TReturn, inner expr type: ${Type.enumConstructor(e.expr)}');
                #end
                var hasPattern = containsInfrastructurePattern(e);
                #if debug_preprocessor
                trace('[containsInfrastructurePattern] TReturn inner has pattern: $hasPattern');
                #end
                hasPattern;
            case TFunction(func):
                #if debug_preprocessor
                trace('[containsInfrastructurePattern] Checking TFunction, has body: ${func.expr != null}');
                #end
                func.expr != null && containsInfrastructurePattern(func.expr);
            case TIf(cond, e1, e2):
                #if debug_preprocessor
                trace('[containsInfrastructurePattern] Checking TIf');
                #end
                containsInfrastructurePattern(cond) ||
                containsInfrastructurePattern(e1) ||
                (e2 != null && containsInfrastructurePattern(e2));
            case TSwitch(e, cases, edef):
                #if debug_preprocessor
                trace('[containsInfrastructurePattern] Checking TSwitch');
                #end
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
                #if debug_preprocessor
                var exprType = switch(expr.expr) {
                    case TConst(_): "TConst";
                    case TLocal(_): "TLocal";
                    case TField(_): "TField";
                    case TCall(_): "TCall";
                    case TBinop(_): "TBinop";
                    case TUnop(_): "TUnop";
                    case TParenthesis(_): "TParenthesis";
                    case TMeta(_): "TMeta";
                    default: "Other";
                };
                trace('[containsInfrastructurePattern] No pattern in ${exprType}');
                #end
                false;
        };

        #if debug_preprocessor
        if (result) {
            trace('[containsInfrastructurePattern] ✓ Pattern DETECTED');
        }
        #end

        return result;
    }

    /**
     * Recursively apply substitutions throughout the entire AST tree
     *
     * WHY: The adjacency-based approach fails when intervening statements exist between
     *      TVar and TSwitch (like IF validation in TodoPubSub). Recursive traversal
     *      ensures EVERY TLocal reference is checked, regardless of intervening code.
     *
     * WHAT: Uses TypedExprTools.map() to recursively traverse and transform the AST,
     *       substituting all TLocal references to infrastructure variables.
     *
     * HOW: Pattern from RemoveTemporaryVariablesImpl.hx line 169 - proven Reflaxe approach
     *
     * @param expr Expression to recursively process
     * @param subs Map of variable IDs to substitute expressions
     * @return Transformed expression with all substitutions applied
     */
    static function applySubstitutionsRecursively(expr: TypedExpr, subs: Map<Int, TypedExpr>): TypedExpr {
        return switch(expr.expr) {
            // Base case: Substitute TLocal infrastructure variables
            case TLocal(v):
                if (subs.exists(v.id)) {
                    #if debug_preprocessor
                    trace('[applySubstitutionsRecursively] ✓ Substituting ${v.name} (ID: ${v.id})');
                    #end
                    subs.get(v.id);
                } else {
                    #if debug_preprocessor
                    trace('[applySubstitutionsRecursively] TLocal ${v.name} (ID: ${v.id}) - NO substitution');
                    #end
                    expr;
                }

            // Handle TVar explicitly to ensure init expression is processed
            case TVar(v, init):
                #if debug_preprocessor
                trace('[applySubstitutionsRecursively] Processing TVar: ${v.name}, hasInit: ${init != null}');
                #end

                if (init != null) {
                    // CRITICAL: Recursively process the init expression
                    // This is where nested infrastructure variables are found!
                    var processedInit = applySubstitutionsRecursively(init, subs);
                    return {expr: TVar(v, processedInit), pos: expr.pos, t: expr.t};
                } else {
                    return expr;
                }

            // Handle blocks explicitly for better control
            case TBlock(exprs):
                #if debug_preprocessor
                trace('[applySubstitutionsRecursively] Processing TBlock with ${exprs.length} expressions');
                #end

                // CRITICAL FIX: Check if block contains infrastructure variables
                // If yes, we need to register them BEFORE applying substitutions
                var hasInfraVars = Lambda.exists(exprs, e -> switch(e.expr) {
                    case TVar(v, init): init != null && isInfrastructureVar(v.name);
                    case _: false;
                });

                if (hasInfraVars) {
                    #if debug_preprocessor
                    trace('[applySubstitutionsRecursively] Block contains infrastructure variables - using processBlock');
                    trace('[applySubstitutionsRecursively] Before processBlock - substitutions map size: ${Lambda.count(subs)}');
                    #end
                    // Use processBlock which properly registers variables before substituting
                    // CRITICAL: Return the result from processBlock!
                    var result = processBlock(exprs, expr.pos, expr.t, subs);
                    #if debug_preprocessor
                    trace('[applySubstitutionsRecursively] After processBlock - substitutions map size: ${Lambda.count(subs)}');
                    trace('[applySubstitutionsRecursively] Result AST type: ${Type.enumConstructor(result.expr)}');
                    #end
                    return result;
                } else {
                    // No infrastructure variables - just apply substitutions recursively
                    var transformed = exprs.map(e -> applySubstitutionsRecursively(e, subs));
                    return {expr: TBlock(transformed), pos: expr.pos, t: expr.t};
                }

            // Recursively process all other expression types
            default:
                haxe.macro.TypedExprTools.map(expr, e -> applySubstitutionsRecursively(e, subs));
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
            // Handle blocks that might contain infrastructure variables
            case TBlock(exprs):
                processBlock(exprs, expr.pos, expr.t, substitutions);
                
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

            // For all other expressions, delegate to recursive substitution
            default:
                applySubstitutionsRecursively(expr, substitutions);
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

        // NEW APPROACH: Register infrastructure variables, then apply recursive substitution
        // This handles intervening statements automatically
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

            // Check if this is an infrastructure variable declaration
            switch(current.expr) {
                case TVar(v, init):
                    #if debug_preprocessor
                    trace('[processBlock] Found TVar: ${v.name} (ID: ${v.id}), init=${init != null}, isInfra=${isInfrastructureVar(v.name)}');
                    #end

                    if (init != null && isInfrastructureVar(v.name)) {
                        #if debug_preprocessor
                        trace('[processBlock] ✓ INFRASTRUCTURE VARIABLE DETECTED: "${v.name}" (ID: ${v.id})');
                        trace('[processBlock] Init expression type: ${Type.enumConstructor(init.expr)}');
                        trace('[processBlock] Registering substitution...');
                        #end

                        // Register the substitution (ID-based)
                        substitutions.set(v.id, init);

                        #if debug_preprocessor
                        trace('[processBlock] ✓ REGISTERED: "${v.name}" (ID ${v.id}) => ${Type.enumConstructor(init.expr)}');
                        var allKeys = [for (k in substitutions.keys()) k];
                        var allNames = [];
                        for (k in allKeys) {
                            // We can't get the name from the ID directly, but we can show the ID list
                            allNames.push('ID:${k}');
                        }
                        trace('[processBlock] Substitutions map now has ${allKeys.length} entries: ${allNames.join(", ")}');
                        #end

                        // Skip this TVar in output (infrastructure variables are eliminated)
                        i++;
                        continue;
                    } else {
                        #if debug_preprocessor
                        trace('[processBlock] Not infrastructure variable, processing normally');
                        #end

                        // CRITICAL: Process non-infrastructure TVars too!
                        var transformed = applySubstitutionsRecursively(current, substitutions);
                        processed.push(transformed);
                        i++;
                    }

                default:
                    // For all other expressions, apply recursive substitution
                    #if debug_preprocessor
                    trace('[processBlock] Applying recursive substitution to expression $i');
                    #end

                    var transformed = applySubstitutionsRecursively(current, substitutions);
                    processed.push(transformed);
                    i++;
            }
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
                    // Filter out orphaned enum parameter assignments in case bodies
                    // These are redundant because the pattern already extracts the values
                    var filteredExprs = [];
                    for (expr in exprs) {
                        switch(expr.expr) {
                            case TVar(v, init) if (init != null):
                                // Check if this is an enum parameter extraction
                                switch(init.expr) {
                                    case TEnumParameter(_, _, _):
                                        #if debug_preprocessor
                                        trace('[TypedExprPreprocessor] Filtering redundant enum parameter assignment in case body: ${v.name}');
                                        #end
                                        // Skip this assignment - pattern already extracted the value
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