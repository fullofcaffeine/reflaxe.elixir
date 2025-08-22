package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.Type.TypedExpr;

using Lambda;

/**
 * YCombinatorCompiler: Y Combinator Pattern Detection and Generation
 * 
 * WHY: Separate complex Y combinator detection logic from main compiler
 * - Y combinator patterns are generated for while loops and complex iteration patterns
 * - Pattern detection requires sophisticated AST analysis to prevent syntax errors
 * - Complex logic was embedded in ElixirCompiler causing maintainability issues
 * - Extraction enables focused testing and documentation of Y combinator patterns
 * 
 * WHAT: Y combinator pattern detection and generation utilities
 * - Detects when expressions will generate Y combinator patterns at compile time
 * - Provides AST analysis for complex loop structures and iterations
 * - Handles Reflect.fields patterns that require special Y combinator generation
 * - Prevents malformed Y combinator patterns that cause Elixir compilation errors
 * 
 * HOW: AST analysis and pattern detection algorithms
 * - Traverses TypedExpr AST to identify patterns requiring Y combinators
 * - Analyzes TWhile, TFor, and Reflect.fields expressions for complexity
 * - Provides decision logic for when to use Y combinator vs simpler patterns
 * - Integrates with loop compilation to ensure consistent pattern generation
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused on Y combinator pattern concerns only
 * - Open/Closed Principle: Extensible for new Y combinator patterns
 * - Testability: Isolated pattern detection logic can be unit tested
 * - Maintainability: Clear separation between Y combinator and other compilation logic
 * - Performance: Optimized pattern detection without cluttering main compiler
 * 
 * EDGE CASES:
 * - Complex nested loops that may require multiple Y combinator levels
 * - Reflect.fields iterations that generate special patterns
 * - State variable management in Y combinator patterns
 * - Performance optimization for deeply nested AST analysis
 * 
 * FUTURE DIRECTION:
 * Y combinator patterns are a transitional solution for complex loop compilation.
 * These patterns will be replaced with more idiomatic Elixir approaches:
 * - Stream-based iteration for large datasets (Stream.iterate, Stream.unfold)
 * - Tail-recursive functions with accumulator patterns
 * - GenServer-based iteration for stateful loops
 * - Process-based parallelization for concurrent iteration
 * - Native Elixir recursion patterns instead of JavaScript-style Y combinators
 * 
 * The Y combinator approach was adopted from JavaScript compilation patterns but
 * doesn't align with Elixir's functional programming paradigms. Future versions
 * will generate native Elixir patterns that are more performant and idiomatic.
 * 
 * @see documentation/Y_COMBINATOR_PATTERNS.md - Complete Y combinator documentation
 * @see documentation/FUTURE_ELIXIR_PATTERNS.md - Planned idiomatic replacements
 */
@:nullSafety(Off)
class YCombinatorCompiler {
    var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Detect if an AST expression will generate a Y combinator pattern.
     * 
     * WHY: Prevent Y combinator syntax errors by detecting patterns before compilation
     * WHAT: Analyzes TypedExpr AST structure to identify Y combinator generation patterns
     * HOW: Recursively traverses AST looking for TWhile, complex TFor, and Reflect.fields patterns
     * 
     * This function analyzes the AST structure BEFORE string compilation
     * to identify patterns that will result in Y combinator generation,
     * allowing us to take corrective action to prevent malformed syntax.
     * 
     * @param expr The TypedExpr to analyze
     * @return True if this expression will generate a Y combinator
     */
    public function detectYCombinatorInAST(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TBlock(expressions):
                // Check if block contains patterns that generate Y combinators
                for (e in expressions) {
                    if (detectYCombinatorInAST(e)) return true;
                }
                return false;
                
            case TFor(v, it, e):
                // TFor loops may generate Y combinators, especially with Reflect.fields
                switch (it.expr) {
                    case TCall(callExpr, args):
                        switch (callExpr.expr) {
                            case TField(obj, fieldAccess):
                                switch (fieldAccess) {
                                    case FStatic(_, cf):
                                        // Check if this is Reflect.fields
                                        var isReflectFields = cf.get().name == "fields";
                                        if (isReflectFields) trace('[Y_COMBINATOR] Found Reflect.fields pattern - will generate Y combinator');
                                        return isReflectFields;
                                    case _: return false;
                                }
                            case _: return false;
                        }
                    case _: return false;
                }
                
            case TWhile(_, _, true):
                trace('[Y_COMBINATOR] Found TWhile - will generate Y combinator');
                // While loops generate Y combinators
                return true;
                
            case _:
                return false;
        }
        
        var result = false;
        if (result) trace('[Y_COMBINATOR] AST detection result: Y combinator pattern detected');
        return result;
    }
    
    /**
     * Enhanced Y combinator pattern detection with comprehensive AST analysis.
     * 
     * WHY: Provide more thorough analysis to prevent complex Y combinator syntax errors
     * WHAT: Deep AST traversal to identify all potential Y combinator generation points
     * HOW: Recursively analyzes all expression types that might generate Y combinators
     * 
     * This enhanced version provides deeper analysis than detectYCombinatorInAST
     * and is used when we need comprehensive pattern detection across complex expressions.
     * Y combinator syntax errors. This enhanced version traces the AST structure
     * to provide more detailed analysis of potential Y combinator generation.
     * 
     * Key detection patterns:
     * - TWhile loops (always generate Y combinators)
     * - TFor loops with Reflect.fields (generate Y combinators)
     * - Nested expressions that contain Y combinator patterns
     * - Complex iteration patterns requiring functional recursion
     * 
     * @param expr The TypedExpr to analyze comprehensively
     * @return True if any expression uses Reflect.fields (indicating Y combinator generation)
     */
    public function hasReflectFieldsPattern(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TFor(v, it, e):
                // Check if the iterator is Reflect.fields
                switch (it.expr) {
                    case TCall(callExpr, args):
                        switch (callExpr.expr) {
                            case TField(obj, fieldAccess):
                                switch (fieldAccess) {
                                    case FStatic(_, cf):
                                        var methodName = cf.get().name;
                                        if (methodName == "fields") {
                                            trace('[Y_COMBINATOR] Reflect.fields pattern detected in TFor');
                                            return true;
                                        }
                                    case _:
                                }
                            case _:
                        }
                    case _:
                }
                
                // Recursively check the body for nested patterns
                return hasReflectFieldsPattern(e);
                
            case TBlock(expressions):
                // Check all expressions in the block
                for (expr in expressions) {
                    if (hasReflectFieldsPattern(expr)) return true;
                }
                return false;
                
            case TWhile(cond, body, normalWhile):
                // Check condition and body for Reflect.fields patterns
                return hasReflectFieldsPattern(cond) || hasReflectFieldsPattern(body);
                
            case TIf(cond, ifExpr, elseExpr):
                // Check all branches for patterns
                var hasPattern = hasReflectFieldsPattern(cond) || hasReflectFieldsPattern(ifExpr);
                if (elseExpr != null) {
                    hasPattern = hasPattern || hasReflectFieldsPattern(elseExpr);
                }
                return hasPattern;
                
            case _:
                return false;
        }
    }
    
    /**
     * Check if expression contains patterns that will generate Y combinator structures.
     * 
     * WHY: Provide lightweight pattern detection for common Y combinator scenarios
     * WHAT: Quick check for the most common Y combinator generation patterns
     * HOW: Fast pattern matching on known Y combinator triggers
     * 
     * This is a lighter-weight version of detectYCombinatorInAST that focuses
     * on the most common patterns that generate Y combinators in Elixir compilation.
     * 
     * @param expr The expression to check
     * @return True if expression contains Y combinator patterns
     */
    public function containsYCombinatorPattern(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        return switch (expr.expr) {
            case TWhile(_, _, _): true;  // While loops always use Y combinators
            case TFor(_, it, _): hasReflectFieldsPattern(expr);  // Some for loops use Y combinators
            case TBlock(expressions):
                // Check if any expression in block uses Y combinators
                expressions.exists(e -> containsYCombinatorPattern(e));
            case _: false;
        }
    }
    
    /**
     * Analyze expression complexity to determine if Y combinator is needed.
     * 
     * WHY: Optimize compilation by using Y combinators only when necessary
     * WHAT: Complexity analysis to determine the most efficient compilation approach
     * HOW: Heuristic analysis of expression structure and nesting depth
     * 
     * Y combinators add overhead, so they should only be used when the complexity
     * of the expression justifies the functional recursion approach.
     * 
     * @param expr The expression to analyze
     * @return True if expression complexity justifies Y combinator usage
     */
    public function requiresYCombinator(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        return switch (expr.expr) {
            case TWhile(_, body, _):
                // While loops with complex bodies benefit from Y combinators
                isComplexExpression(body);
            case TFor(_, it, body):
                // For loops with Reflect.fields or complex iteration patterns
                hasReflectFieldsPattern(expr) || isComplexExpression(body);
            case _:
                false;
        }
    }
    
    /**
     * Determine if an expression is complex enough to warrant Y combinator usage.
     * 
     * WHY: Balance compilation complexity with performance
     * WHAT: Heuristic-based complexity analysis of expressions
     * HOW: Analyzes nesting depth, operation count, and pattern complexity
     * 
     * @param expr The expression to analyze for complexity
     * @return True if expression is complex enough for Y combinator approach
     */
    private function isComplexExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        return switch (expr.expr) {
            case TBlock(expressions):
                // Complex if many statements or nested structures
                expressions.length > 3 || expressions.exists(e -> isComplexExpression(e));
            case TWhile(_, _, _) | TFor(_, _, _):
                // Nested loops are always complex
                true;
            case TIf(_, ifExpr, elseExpr):
                // Complex conditionals with nested structures
                isComplexExpression(ifExpr) || (elseExpr != null && isComplexExpression(elseExpr));
            case TCall(_, args):
                // Function calls with many arguments or complex arguments
                args.length > 2 || args.exists(arg -> isComplexExpression(arg));
            case _:
                false;
        }
    }
}