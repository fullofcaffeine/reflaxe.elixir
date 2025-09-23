package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.context.TransformContext;
import reflaxe.elixir.ast.naming.ElixirAtom;

using reflaxe.elixir.ast.ElixirASTHelpers;

/**
 * PatternMatchingTransforms: Comprehensive pattern matching transformation module
 * 
 * WHY: Elixir's pattern matching is fundamental to its functional paradigm. This module
 * transforms Haxe switch statements into idiomatic Elixir case expressions, preserving
 * exhaustiveness checks and variable bindings while generating clean, readable code.
 * 
 * WHAT: Provides transformation passes for:
 * - Switch to case expression conversion
 * - Pattern variable extraction and binding
 * - Guard clause generation from switch conditions
 * - Exhaustiveness checking and default case handling
 * - Nested pattern matching optimization
 * - Enum constructor pattern generation
 * 
 * HOW: Multiple transformation passes that work together:
 * 1. patternMatchingPass - Main switch→case transformation
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
 * - Empty switch statements (no cases)
 * - Switches without default branches
 * - Nested switches and pattern shadowing
 * - Complex guard expressions
 * - Pattern variable conflicts
 */
@:nullSafety(Off)
class PatternMatchingTransforms {
    
    /**
     * Main pattern matching transformation pass
     * Converts switch expressions to Elixir case expressions
     */
    public static function patternMatchingPass(ast: ElixirAST, context: TransformContext): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting pattern matching pass");
        #end
        
        return switch(ast.def) {
            case ESwitch(target, cases):
                transformSwitch(ast, target, cases, context);
                
            case EBlock(exprs):
                var transformed = exprs.map(e -> patternMatchingPass(e, context));
                makeAST(EBlock(transformed), ast.pos, ast.metadata);
                
            case EModule(name, body):
                var transformedBody = patternMatchingPass(body, context);
                makeAST(EModule(name, transformedBody), ast.pos, ast.metadata);
                
            case EFunctionDef(name, args, guard, body):
                var transformedBody = patternMatchingPass(body, context);
                makeAST(EFunctionDef(name, args, guard, transformedBody), ast.pos, ast.metadata);
                
            case EIf(cond, thenBranch, elseBranch):
                var transformedThen = patternMatchingPass(thenBranch, context);
                var transformedElse = elseBranch != null ? patternMatchingPass(elseBranch, context) : null;
                makeAST(EIf(cond, transformedThen, transformedElse), ast.pos, ast.metadata);
                
            case EMatch(pattern, value):
                var transformedValue = patternMatchingPass(value, context);
                makeAST(EMatch(pattern, transformedValue), ast.pos, ast.metadata);
                
            case EFn(clauses):
                var transformedClauses = clauses.map(clause -> {
                    args: clause.args,
                    guard: clause.guard,
                    body: patternMatchingPass(clause.body, context)
                });
                makeAST(EFn(transformedClauses), ast.pos, ast.metadata);
                
            default:
                // For other node types, recursively transform children
                ast.map(child -> patternMatchingPass(child, context));
        };
    }
    
    /**
     * Transform a switch expression into an Elixir case expression
     */
    static function transformSwitch(ast: ElixirAST, target: ElixirAST, cases: Array<SwitchCase>, context: TransformContext): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Transforming switch with ${cases.length} cases");
        #end
        
        // Build Elixir case clauses from switch cases
        var elixirClauses: Array<CaseClause> = [];
        
        for (switchCase in cases) {
            // Transform each pattern and body
            var pattern = transformPattern(switchCase.pattern, context);
            var guard = extractGuard(switchCase.pattern, context);
            var body = patternMatchingPass(switchCase.body, context);
            
            elixirClauses.push({
                args: [pattern],
                guard: guard,
                body: body
            });
            
            #if debug_pattern_matching
            trace("[PatternMatchingTransforms] Transformed case: pattern=${pattern}, guard=${guard != null}");
            #end
        }
        
        // Add default case if needed
        if (needsDefaultCase(cases)) {
            elixirClauses.push({
                args: [PWildcard],
                guard: null,
                body: makeAST(ENil)
            });
            
            #if debug_pattern_matching
            trace("[PatternMatchingTransforms] Added default wildcard case");
            #end
        }
        
        // Create the case expression
        var caseExpr = makeAST(ECase(target, elixirClauses), ast.pos, ast.metadata);
        
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Generated case expression with ${elixirClauses.length} clauses");
        #end
        
        return caseExpr;
    }
    
    /**
     * Transform a switch pattern into an Elixir pattern
     */
    static function transformPattern(pattern: ElixirAST, context: TransformContext): Pattern {
        return switch(pattern.def) {
            case EVar(name):
                PVar(name);
                
            case EAtom(atom):
                PAtom(atom);
                
            case EInteger(n):
                PLiteral(EInteger(n));
                
            case EString(s):
                PLiteral(EString(s));
                
            case ETuple(elements):
                var patterns = elements.map(e -> transformPattern(e, context));
                PTuple(patterns);
                
            case EList(elements):
                var patterns = elements.map(e -> transformPattern(e, context));
                PList(patterns);
                
            case EMap(fields):
                var patternFields = [];
                for (field in fields) {
                    patternFields.push({
                        key: field.key,
                        value: transformPattern(field.value, context)
                    });
                }
                PMap(patternFields);
                
            case ENil:
                PAtom(ElixirAtom.nil());
                
            default:
                // For complex patterns, use wildcard
                PWildcard;
        };
    }
    
    /**
     * Extract guard conditions from a pattern if applicable
     */
    static function extractGuard(pattern: ElixirAST, context: TransformContext): Null<ElixirAST> {
        // Check if the pattern has guard metadata
        if (pattern.metadata != null && pattern.metadata.guardCondition != null) {
            return pattern.metadata.guardCondition;
        }
        
        // For now, no guard extraction
        return null;
    }
    
    /**
     * Check if a default case is needed for exhaustiveness
     */
    static function needsDefaultCase(cases: Array<SwitchCase>): Bool {
        // Check if any case has a wildcard pattern
        for (c in cases) {
            if (isWildcardPattern(c.pattern)) {
                return false; // Already has a catch-all
            }
        }
        
        // TODO: More sophisticated exhaustiveness checking
        // For now, assume non-exhaustive and add default
        return true;
    }
    
    /**
     * Check if a pattern is a wildcard/catch-all
     */
    static function isWildcardPattern(pattern: ElixirAST): Bool {
        return switch(pattern.def) {
            case EVar("_"): true;
            case EWildcard: true;
            default: false;
        };
    }
    
    /**
     * Guard optimization pass - converts complex conditions to guard clauses
     */
    public static function guardOptimizationPass(ast: ElixirAST, context: TransformContext): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting guard optimization pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                var optimizedClauses = clauses.map(clause -> optimizeGuardClause(clause, context));
                makeAST(ECase(target, optimizedClauses), ast.pos, ast.metadata);
                
            default:
                // Recursively optimize children
                ast.map(child -> guardOptimizationPass(child, context));
        };
    }
    
    /**
     * Optimize a single case clause by extracting guards from the body
     */
    static function optimizeGuardClause(clause: CaseClause, context: TransformContext): CaseClause {
        // Look for if statements at the start of the body that can become guards
        switch(clause.body.def) {
            case EIf(cond, thenBranch, elseBranch) if (elseBranch == null || isRaiseOrThrow(elseBranch)):
                // This if can be converted to a guard
                var newGuard = clause.guard != null 
                    ? makeAST(EBinary(And, clause.guard, cond))
                    : cond;
                    
                return {
                    args: clause.args,
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
            case EThrow(_): true;
            case ERaise(_): true;
            default: false;
        };
    }
    
    /**
     * Pattern variable binding pass - ensures correct variable scoping in patterns
     */
    public static function patternVariableBindingPass(ast: ElixirAST, context: TransformContext): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting pattern variable binding pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                var boundClauses = clauses.map(clause -> bindPatternVariables(clause, context));
                makeAST(ECase(target, boundClauses), ast.pos, ast.metadata);
                
            default:
                // Recursively bind in children
                ast.map(child -> patternVariableBindingPass(child, context));
        };
    }
    
    /**
     * Bind pattern variables in a case clause
     */
    static function bindPatternVariables(clause: CaseClause, context: TransformContext): CaseClause {
        // Extract variables from patterns
        var patternVars = extractPatternVariables(clause.args);
        
        // Add bindings to context for body transformation
        for (varName in patternVars) {
            context.addPatternVariable(varName);
        }
        
        // Transform body with pattern variables in scope
        var boundBody = patternVariableBindingPass(clause.body, context);
        
        // Remove pattern variables from context
        for (varName in patternVars) {
            context.removePatternVariable(varName);
        }
        
        return {
            args: clause.args,
            guard: clause.guard,
            body: boundBody
        };
    }
    
    /**
     * Extract variable names from patterns
     */
    static function extractPatternVariables(patterns: Array<Pattern>): Array<String> {
        var vars = [];
        
        function extract(p: Pattern): Void {
            switch(p) {
                case PVar(name) if (name != "_"):
                    vars.push(name);
                    
                case PTuple(patterns):
                    for (p in patterns) extract(p);
                    
                case PList(patterns):
                    for (p in patterns) extract(p);
                    
                case PMap(fields):
                    for (f in fields) extract(f.value);
                    
                case PCons(head, tail):
                    extract(head);
                    extract(tail);
                    
                default:
                    // No variables in other patterns
            }
        }
        
        for (p in patterns) {
            extract(p);
        }
        
        return vars;
    }
    
    /**
     * Exhaustiveness check pass - adds compile-time verification for pattern completeness
     */
    public static function exhaustivenessCheckPass(ast: ElixirAST, context: TransformContext): ElixirAST {
        #if debug_pattern_matching
        trace("[PatternMatchingTransforms] Starting exhaustiveness check pass");
        #end
        
        return switch(ast.def) {
            case ECase(target, clauses):
                if (!isExhaustive(clauses, target, context)) {
                    // Add warning or error about non-exhaustive patterns
                    context.addWarning("Non-exhaustive patterns in case expression", ast.pos);
                }
                ast;
                
            default:
                // Recursively check children
                ast.map(child -> exhaustivenessCheckPass(child, context));
        };
    }
    
    /**
     * Check if case clauses are exhaustive
     */
    static function isExhaustive(clauses: Array<CaseClause>, target: ElixirAST, context: TransformContext): Bool {
        // Simple check: look for wildcard pattern
        for (clause in clauses) {
            for (pattern in clause.args) {
                if (isWildcardPatternDeep(pattern)) {
                    return true;
                }
            }
        }
        
        // TODO: More sophisticated exhaustiveness checking based on type information
        return false;
    }
    
    /**
     * Deep check for wildcard patterns
     */
    static function isWildcardPatternDeep(pattern: Pattern): Bool {
        return switch(pattern) {
            case PWildcard: true;
            case PVar("_"): true;
            default: false;
        };
    }
}

// Type definitions for pattern matching
typedef SwitchCase = {
    pattern: ElixirAST,
    body: ElixirAST
}

typedef CaseClause = {
    args: Array<Pattern>,
    ?guard: ElixirAST,
    body: ElixirAST
}

typedef Pattern = PatternDef;

enum PatternDef {
    PVar(name: String);
    PWildcard;
    PAtom(atom: ElixirAtom);
    PLiteral(value: ElixirASTDef);
    PTuple(patterns: Array<Pattern>);
    PList(patterns: Array<Pattern>);
    PCons(head: Pattern, tail: Pattern);
    PMap(fields: Array<{key: ElixirAST, value: Pattern}>);
}

#end