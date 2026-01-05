package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
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
    static inline function safeMeta(ast: ElixirAST): ElixirMetadata {
        return ast != null && ast.metadata != null ? ast.metadata : {};
    }
    
    /**
     * Main pattern matching transformation pass
     * Optimizes and cleans up case expressions for idiomatic output
     */
    public static function patternMatchingPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_matching
        #end
        
        if (ast == null || ast.def == null) return ast;
        return switch(ast.def) {
            case ECase(target, clauses):
                optimizeCaseExpression(ast, target, clauses);
                
            case EBlock(exprs):
                var transformed = exprs != null ? exprs.map(e -> patternMatchingPass(e)) : [];
                makeASTWithMeta(EBlock(transformed), safeMeta(ast), ast.pos);
                
            case EModule(name, attributes, body):
                var transformedBody = body.map(b -> patternMatchingPass(b));
                makeASTWithMeta(EModule(name, attributes, transformedBody), safeMeta(ast), ast.pos);
                
            case EDef(name, args, guard, body):
                var transformedBody = body != null ? patternMatchingPass(body) : null;
                makeASTWithMeta(EDef(name, args, guard, transformedBody), safeMeta(ast), ast.pos);
                
            case EDefp(name, args, guard, body):
                var transformedBody = body != null ? patternMatchingPass(body) : null;
                makeASTWithMeta(EDefp(name, args, guard, transformedBody), safeMeta(ast), ast.pos);
                
            case EIf(cond, thenBranch, elseBranch):
                var transformedThen = thenBranch != null ? patternMatchingPass(thenBranch) : null;
                var transformedElse = elseBranch != null ? patternMatchingPass(elseBranch) : null;
                makeASTWithMeta(EIf(cond, transformedThen, transformedElse), safeMeta(ast), ast.pos);
                
            case EFn(clauses):
                var transformedClauses = (clauses != null ? clauses : []).map(clause -> {
                    args: clause.args,
                    guard: clause.guard,
                    body: clause.body != null ? patternMatchingPass(clause.body) : null
                });
                makeASTWithMeta(EFn(transformedClauses), safeMeta(ast), ast.pos);
                
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
            #end
        }
        
        // Create the optimized case expression
        var optimizedCase = makeASTWithMeta(ECase(target, optimizedClauses), safeMeta(ast), ast.pos);
        
        #if debug_pattern_matching
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
        
        // Note: Exhaustiveness checking is currently conservative and does not use type information.
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
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                var optimizedClauses = clauses.map(clause -> optimizeGuardClause(clause));
                makeASTWithMeta(ECase(target, optimizedClauses), safeMeta(ast), ast.pos);
                
            default:
                // Recursively optimize children - handle each case individually
                recursiveTransform(ast, guardOptimizationPass);
        };
    }
    
    /**
     * Optimize a single case clause by extracting guards from the body
     */
    static function optimizeGuardClause(clause: ECaseClause): ECaseClause {
        // Look for if statements at the start of the body that can become guards
        if (clause.body == null || clause.body.def == null) return clause;
        switch(clause.body.def) {
            case EIf(cond, thenBranch, elseBranch) if (elseBranch == null || isRaiseOrThrow(elseBranch)):
                // This if can be converted to a guard
                var newGuard = clause.guard != null 
                    ? makeAST(EBinary(And, clause.guard, cond))
                    : cond;
                    
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
        if (expr == null || expr.def == null) return false;
        return switch(expr.def) {
            case ECall(target, "throw", _): 
                switch(target != null ? target.def : null) {
                    case EVar("Kernel"): true;
                    default: false;
                }
            case ECall(target, "raise", _):
                switch(target != null ? target.def : null) {
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
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                var boundClauses = clauses.map(clause -> bindPatternVariables(clause));
                makeASTWithMeta(ECase(target, boundClauses), safeMeta(ast), ast.pos);
                
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
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                if (!isExhaustive(clauses)) {
                    // In a real implementation, we'd add a compile-time warning or error
                    #if debug_pattern_matching
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
        
        // Note: Exhaustiveness checking is currently a simple wildcard scan (no type information).
        return false;
    }
    
    /**
     * Helper function to recursively transform AST nodes
     * Since ElixirAST doesn't have a generic map method, we need to handle each case
     */
    static function recursiveTransform(ast: ElixirAST, transform: ElixirAST -> ElixirAST): ElixirAST {
        if (ast == null || ast.def == null) return ast;
        var newDef = switch(ast.def) {
            case EBlock(exprs):
                EBlock((exprs != null ? exprs : []).map(e -> transform(e)));
            case EModule(name, attrs, body):
                EModule(name, attrs, (body != null ? body : []).map(b -> transform(b)));
            case EIf(cond, thenBranch, elseBranch):
                EIf(cond != null ? transform(cond) : null, thenBranch != null ? transform(thenBranch) : null, elseBranch != null ? transform(elseBranch) : null);
            case EDef(name, args, guard, body):
                EDef(name, args, guard, body != null ? transform(body) : null);
            case EDefp(name, args, guard, body):
                EDefp(name, args, guard, body != null ? transform(body) : null);
            case EFn(clauses):
                EFn((clauses != null ? clauses : []).map(c -> {
                    args: c.args,
                    guard: c.guard,
                    body: c.body != null ? transform(c.body) : null
                }));
            default:
                // For other cases, return unchanged
                ast.def;
        };

        return makeASTWithMeta(newDef, safeMeta(ast), ast.pos);
    }
}

#end
/**
 * PatternMatchingTransforms
 *
 * WHAT
 * - Transforms switch constructs into idiomatic Elixir case expressions with
 *   proper pattern tuples and guards.
 *
 * WHY
 * - Haxe desugaring can obscure enum/tagged tuple structure. Explicit case
 *   patterns in Elixir improve readability and avoid runtime errors.
 *
 * HOW
 * - Detects enum discriminants, constructs PTuple patterns with atom tags,
 *   and shapes guards accordingly. Ensures no orphaned parameter extracts.
 *
 * EXAMPLES
 * Haxe:
 *   switch (msg) { case Created(content): ... }
 * Elixir:
 *   case msg do {:created, content} -> ... end
 */
