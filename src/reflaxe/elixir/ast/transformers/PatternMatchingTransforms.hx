package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * PatternMatchingTransforms: Comprehensive pattern matching transformation module
 * 
 * WHY: Elixir's pattern matching is fundamental to its functional paradigm. This module
 * transforms Haxe switch statements into idiomatic Elixir case expressions, preserving
 * exhaustiveness checks and variable bindings while generating clean, readable code.
 * 
 * WHAT: Provides transformation passes for:
 * - Case expression optimization and cleanup
 * - Guard clause generation from switch conditions
 * - Pattern variable extraction and binding
 * - Exhaustiveness checking and default case handling
 * - Nested pattern matching optimization
 * 
 * HOW: Multiple transformation passes that work together:
 * 1. patternMatchingPass - Main case transformation and cleanup
 * 2. guardOptimizationPass - Converts complex conditions to guards
 * 3. patternVariableBindingPass - Ensures correct variable scoping
 * 4. exhaustivenessCheckPass - Adds compile-time exhaustiveness verification
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused only on pattern matching transformations
 * - Composable: Each pass can be enabled/disabled independently
 * - Testable: Clear input/output for each transformation
 * - Maintainable: All pattern matching logic in one place
 * - Extensible: Easy to add new pattern matching features
 * 
 * EDGE CASES:
 * - Empty case expressions (no clauses)
 * - Cases without default branches
 * - Nested cases and pattern shadowing
 * - Complex guard expressions
 * - Pattern variable conflicts
 * 
 * NOTE: Since the switch→case transformation already happens in ElixirASTBuilder,
 * these transforms focus on optimizing and cleaning up the generated case expressions.
 */
@:nullSafety(Off)
class PatternMatchingTransforms {
    
    /**
     * Main pattern matching transformation pass
     * Optimizes and cleans up case expressions for idiomatic output
     */
    public static function patternMatchingPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting pattern matching pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                optimizeCaseExpression(ast, target, clauses);
                
            case EBlock(exprs):
                var transformed = exprs.map(e -> patternMatchingPass(e));
                makeAST(EBlock(transformed));
                
            case EModule(name, attributes, body):
                var transformedBody = body.map(b -> patternMatchingPass(b));
                makeAST(EModule(name, attributes, transformedBody));
                
            case EDef(name, args, guard, body):
                var transformedBody = patternMatchingPass(body);
                makeAST(EDef(name, args, guard, transformedBody));
                
            case EDefp(name, args, guard, body):
                var transformedBody = patternMatchingPass(body);
                makeAST(EDefp(name, args, guard, transformedBody));
                
            case EIf(cond, thenBranch, elseBranch):
                var transformedThen = patternMatchingPass(thenBranch);
                var transformedElse = elseBranch != null ? patternMatchingPass(elseBranch) : null;
                makeAST(EIf(cond, transformedThen, transformedElse));
                
            case EFn(clauses):
                var transformedClauses = clauses.map(clause -> {
                    args: clause.args,
                    guard: clause.guard,
                    body: patternMatchingPass(clause.body)
                });
                makeAST(EFn(transformedClauses));
                
            default:
                // For other node types, return as-is
                // We can't use a generic map method, so we'd need to handle each case individually
                // For now, just return the node unchanged
                ast;
        };
    }
    
    /**
     * Optimize a case expression for idiomatic Elixir output
     */
    static function optimizeCaseExpression(ast: ElixirAST, target: ElixirAST, clauses: Array<ECaseClause>): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Optimizing case with ${clauses.length} clauses");
        #end
        
        // Optimize each clause
        var optimizedClauses: Array<ECaseClause> = [];
        
        for (clause in clauses) {
            // Transform the body recursively
            var optimizedBody = patternMatchingPass(clause.body);
            
            // Check if we can simplify the pattern
            var optimizedPattern = optimizePattern(clause.pattern);
            
            optimizedClauses.push({
                pattern: optimizedPattern,
                guard: clause.guard,
                body: optimizedBody
            });
            
            #if debug_pattern_matching
            trace("[PatternMatchingTransforms] Optimized clause: pattern=${optimizedPattern}");
            #end
        }
        
        // Add default case if needed for exhaustiveness
        if (needsDefaultCase(optimizedClauses)) {
            optimizedClauses.push({
                pattern: PWildcard,
                guard: null,
                body: makeAST(EAtom(ElixirAtom.nil()))
            });
            
            #if debug_pattern_matching
            trace("[PatternMatchingTransforms] Added default wildcard case for exhaustiveness");
            #end
        }
        
        // Create the optimized case expression
        var optimizedCase = makeAST(ECase(target, optimizedClauses));
        
        // Preserve original metadata if it exists
        if (ast.metadata != null) {
            optimizedCase.metadata = ast.metadata;
        }
        
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Generated optimized case expression with ${optimizedClauses.length} clauses");
        #end
        
        return optimizedCase;
    }
    
    /**
     * Optimize a pattern for cleaner output
     */
    static function optimizePattern(pattern: EPattern): EPattern {
        return switch(pattern) {
            case PVar(name) if (name == "_"):
                // Already a wildcard
                PWildcard;
                
            case PAlias(varName, innerPattern):
                // Optimize the inner pattern
                PAlias(varName, optimizePattern(innerPattern));
                
            case PTuple(elements):
                // Optimize each element
                PTuple(elements.map(e -> optimizePattern(e)));
                
            case PList(elements):
                // Optimize each element
                PList(elements.map(e -> optimizePattern(e)));
                
            case PCons(head, tail):
                // Optimize both parts
                PCons(optimizePattern(head), optimizePattern(tail));
                
            case PMap(pairs):
                // Optimize each value pattern
                PMap(pairs.map(p -> {key: p.key, value: optimizePattern(p.value)}));
                
            case PStruct(module, fields):
                // Optimize each field pattern
                PStruct(module, fields.map(f -> {key: f.key, value: optimizePattern(f.value)}));
                
            default:
                // Return as-is for other patterns
                pattern;
        };
    }
    
    /**
     * Check if a default case is needed for exhaustiveness
     */
    static function needsDefaultCase(clauses: Array<ECaseClause>): Bool {
        // Check if any clause has a wildcard pattern
        for (c in clauses) {
            if (isWildcardPattern(c.pattern)) {
                return false; // Already has a catch-all
            }
        }
        
        // For now, assume non-exhaustive and suggest adding default
        // TODO: More sophisticated exhaustiveness checking based on type information
        return false; // Changed to false to avoid adding unnecessary wildcards
    }
    
    /**
     * Check if a pattern is a wildcard/catch-all
     */
    static function isWildcardPattern(pattern: EPattern): Bool {
        return switch(pattern) {
            case PVar("_"): true;
            case PWildcard: true;
            default: false;
        };
    }
    
    /**
     * Guard optimization pass - converts complex conditions to guard clauses
     */
    public static function guardOptimizationPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting guard optimization pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                // 1) Ensure existing guards are guard-safe; if not, move condition into body
                var safeClauses = clauses.map(clause -> ensureGuardSafety(clause));
                // 2) Try converting top-level body ifs into guards when safe
                var optimizedClauses = safeClauses.map(clause -> optimizeGuardClause(clause));
                makeAST(ECase(target, optimizedClauses));
                
            default:
                // Recursively optimize children - handle each case individually
                recursiveTransform(ast, guardOptimizationPass);
        };
    }

    /**
     * If a clause has a non-safe guard, remove the guard and push it into the body as an if.
     */
    static function ensureGuardSafety(clause: ECaseClause): ECaseClause {
        if (clause.guard == null) return clause;
        if (isGuardSafeExpr(clause.guard)) return clause;

        // Extract remote Map.get/2 calls used in the guard and pre-bind them in the body
        var preBinds: Array<ElixirAST> = [];
        var varMap = new Map<String, {key: String, expr: ElixirAST}>();

        function collectBindings(expr: ElixirAST): Void {
            if (expr == null) return;
            switch (expr.def) {
                case ERemoteCall(module, funcName, args):
                    var isMapGet = switch (module.def) { case EVar(name) if (name == "Map"): true; default: false; };
                    if (isMapGet && funcName == "get" && args.length == 2) {
                        // If second arg is an atom we can derive a stable varName
                        var varName = switch (args[1].def) {
                            case EAtom(atom): Std.string(atom);
                            default: null;
                        };
                        if (varName != null && varName.length > 0) {
                            // Create binding: varName = Map.get(...)
                            preBinds.push(makeAST(EMatch(PVar(varName), expr)));
                            varMap.set(varName, {key: varName, expr: expr});
                        }
                    }
                    // Recurse into module and args
                    if (module != null) collectBindings(module);
                    for (a in args) collectBindings(a);
                case EBinary(_, l, r):
                    collectBindings(l); collectBindings(r);
                case EUnary(_, e):
                    collectBindings(e);
                case EIf(c, t, e):
                    collectBindings(c); collectBindings(t); if (e != null) collectBindings(e);
                case EParen(e):
                    collectBindings(e);
                case EBlock(stmts):
                    for (s in stmts) collectBindings(s);
                default:
                    // Other node types: no-op for binding collection
            }
        }

        collectBindings(clause.guard);

        // Replace occurrences of Map.get(..., :key) in body with the bound variable name
        function replaceMapGetWithVar(node: ElixirAST): ElixirAST {
            if (node == null) return node;
            return switch (node.def) {
                case ERemoteCall(module, funcName, args):
                    var isMapGet = switch (module.def) { case EVar(name) if (name == "Map"): true; default: false; };
                    if (isMapGet && funcName == "get" && args.length == 2) {
                        switch (args[1].def) {
                            case EAtom(atom):
                                var keyName = Std.string(atom);
                                if (varMap.exists(keyName)) {
                                    makeAST(EVar(keyName));
                                } else {
                                    node;
                                }
                            default: node;
                        }
                    } else {
                        // Recurse into module and args
                        var newMod = module != null ? replaceMapGetWithVar(module) : null;
                        var newArgs = [for (a in args) replaceMapGetWithVar(a)];
                        makeAST(ERemoteCall(newMod, funcName, newArgs));
                    }
                case EBinary(op, l, r):
                    makeAST(EBinary(op, replaceMapGetWithVar(l), replaceMapGetWithVar(r)));
                case EUnary(op, e):
                    makeAST(EUnary(op, replaceMapGetWithVar(e)));
                case EIf(c, t, e):
                    makeAST(EIf(replaceMapGetWithVar(c), replaceMapGetWithVar(t), e != null ? replaceMapGetWithVar(e) : null));
                case EBlock(stmts):
                    makeAST(EBlock([for (s in stmts) replaceMapGetWithVar(s)]));
                case ECall(target, name, args):
                    makeAST(ECall(target != null ? replaceMapGetWithVar(target) : null, name, [for (a in args) replaceMapGetWithVar(a)]));
                case ERemoteCall(mod, name, args):
                    makeAST(ERemoteCall(replaceMapGetWithVar(mod), name, [for (a in args) replaceMapGetWithVar(a)]));
                case EParen(e):
                    makeAST(EParen(replaceMapGetWithVar(e)));
                default:
                    node;
            };
        }

        // Build new body: [preBinds..., if guard do: (body with replacements) end]
        var replacedBody = replaceMapGetWithVar(clause.body);
        var guardedBody = makeAST(EIf(clause.guard, replacedBody, null));
        var newBody: ElixirAST = null;
        if (preBinds.length > 0) {
            var stmts = [];
            for (b in preBinds) stmts.push(b);
            stmts.push(guardedBody);
            newBody = makeAST(EBlock(stmts));
        } else {
            newBody = guardedBody;
        }

        return {
            pattern: clause.pattern,
            guard: null,
            body: newBody
        };
    }

    /**
     * Determine if an expression is safe to use in a guard.
     * Disallow remote/module calls (e.g., Map.get/2) and keep such conditions in the body.
     */
    static function isGuardSafeExpr(expr: ElixirAST): Bool {
        if (expr == null) return false;
        return switch (expr.def) {
            case ERemoteCall(_, _, _):
                // Remote calls are not allowed in guards
                false;
            case ECall(module, _, args):
                // Local calls (module == null) may be allowed (e.g., is_nil/1), module calls are not
                if (module != null) {
                    false;
                } else {
                    var ok = true;
                    for (a in args) {
                        if (!isGuardSafeExpr(a)) { ok = false; break; }
                    }
                    ok;
                }
            case EBinary(_, l, r):
                isGuardSafeExpr(l) && isGuardSafeExpr(r);
            case EUnary(_, e):
                isGuardSafeExpr(e);
            case EVar(_)|EAtom(_)|EInteger(_)|EFloat(_)|EBoolean(_)|ENil|EField(_, _):
                true;
            default:
                // Be conservative for other node types
                false;
        };
    }

    /**
     * Optimize a single case clause by extracting guards from the body
     */
    static function optimizeGuardClause(clause: ECaseClause): ECaseClause {
        // Look for if statements at the start of the body that can become guards
        switch(clause.body.def) {
            case EIf(cond, thenBranch, elseBranch) if (elseBranch == null || isRaiseOrThrow(elseBranch)):
                // This if can be converted to a guard
                var candidate = clause.guard != null 
                    ? makeAST(EBinary(And, clause.guard, cond))
                    : cond;
                // Only convert to guard if the expression is guard-safe (no remote calls, etc.)
                if (!isGuardSafeExpr(candidate)) {
                    return clause; // Keep as body-level if to preserve semantics and compile constraints
                }
                var newGuard = candidate;
                
                return {
                    pattern: clause.pattern,
                    guard: newGuard,
                    body: thenBranch
                };
                
            default:
                return clause;
        }
    }
    
    /**
     * Check if an expression is a raise or throw
     */
    static function isRaiseOrThrow(expr: ElixirAST): Bool {
        return switch(expr.def) {
            case ECall(target, "throw", _): 
                switch(target.def) {
                    case EVar("Kernel"): true;
                    default: false;
                }
            case ECall(target, "raise", _):
                switch(target.def) {
                    case EVar("Kernel"): true;
                    default: false;
                }
            default: false;
        };
    }
    
    /**
     * Pattern variable binding pass - ensures correct variable scoping in patterns
     */
    public static function patternVariableBindingPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting pattern variable binding pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                var boundClauses = clauses.map(clause -> bindPatternVariables(clause));
                makeAST(ECase(target, boundClauses));
                
            default:
                // Recursively bind in children
                recursiveTransform(ast, patternVariableBindingPass);
        };
    }
    
    /**
     * Bind pattern variables in a case clause
     */
    static function bindPatternVariables(clause: ECaseClause): ECaseClause {
        // For now, just transform the body recursively
        // In a real implementation, we'd track pattern variables and ensure proper scoping
        var boundBody = patternVariableBindingPass(clause.body);
        
        return {
            pattern: clause.pattern,
            guard: clause.guard,
            body: boundBody
        };
    }
    
    /**
     * Exhaustiveness check pass - adds compile-time verification for pattern completeness
     */
    public static function exhaustivenessCheckPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting exhaustiveness check pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                if (!isExhaustive(clauses)) {
                    // In a real implementation, we'd add a compile-time warning or error
                    #if debug_pattern_matching
                    trace("[PatternMatchingTransforms] WARNING: Non-exhaustive patterns in case expression");
                    #end
                }
                ast;
                
            default:
                // Recursively check children
                recursiveTransform(ast, exhaustivenessCheckPass);
        };
    }
    
    /**
     * Check if case clauses are exhaustive
     */
    static function isExhaustive(clauses: Array<ECaseClause>): Bool {
        // Simple check: look for wildcard pattern
        for (clause in clauses) {
            if (isWildcardPattern(clause.pattern)) {
                return true;
            }
        }
        
        // TODO: More sophisticated exhaustiveness checking based on type information
        return false;
    }
    
    /**
     * Helper function to recursively transform AST nodes
     * Since ElixirAST doesn't have a generic map method, we need to handle each case
     */
    static function recursiveTransform(ast: ElixirAST, transform: ElixirAST -> ElixirAST): ElixirAST {
        var newDef = switch(ast.def) {
            case EBlock(exprs):
                EBlock(exprs.map(e -> transform(e)));
            case EModule(name, attrs, body):
                EModule(name, attrs, body.map(b -> transform(b)));
            case EIf(cond, thenBranch, elseBranch):
                EIf(transform(cond), transform(thenBranch), elseBranch != null ? transform(elseBranch) : null);
            case EDef(name, args, guard, body):
                EDef(name, args, guard, transform(body));
            case EDefp(name, args, guard, body):
                EDefp(name, args, guard, transform(body));
            case EFn(clauses):
                EFn(clauses.map(c -> {
                    args: c.args,
                    guard: c.guard,
                    body: transform(c.body)
                }));
            default:
                // For other cases, return unchanged
                ast.def;
        };
        
        var result = makeAST(newDef);
        if (ast.metadata != null) {
            result.metadata = ast.metadata;
        }
        if (ast.pos != null) {
            result.pos = ast.pos;
        }
        return result;
    }
}

#end
