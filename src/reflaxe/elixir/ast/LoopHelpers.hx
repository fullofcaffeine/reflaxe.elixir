package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.optimizers.LoopOptimizer;
import reflaxe.elixir.ast.optimizers.LoopOptimizer.MapIterationPattern;
import reflaxe.elixir.ast.intent.LoopIntent;
import reflaxe.elixir.ast.intent.LoopIntent.LoopIntentMetadata;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * LoopHelpers: Loop Processing and Optimization Utilities
 * 
 * WHY: Centralize loop-related transformation logic
 * - Separate loop concerns from main AST builder
 * - Provide reusable loop optimization utilities
 * - Encapsulate pattern detection for loops
 * 
 * WHAT: Loop intent processing and map iteration handling
 * - Process loop intents with optimization
 * - Build map iteration patterns
 * - Transform loops to idiomatic Elixir constructs
 * 
 * HOW: Pattern matching on loop structures and delegation to optimizers
 * - Detect loop patterns and intents
 * - Apply appropriate transformations
 * - Generate idiomatic Enum operations
 */
class LoopHelpers {
    
    /**
     * Process loop intent with optimization
     * 
     * Delegates to the LoopOptimizer for actual processing
     */
    public static function processLoopIntent(intent: LoopIntent, metadata: LoopIntentMetadata, context: CompilationContext): ElixirAST {
        // Delegate to LoopOptimizer
        return LoopOptimizer.processLoopIntent(intent, metadata, context);
    }
    
    /**
     * Build map iteration pattern
     * 
     * Transforms a map iteration pattern into idiomatic Elixir
     * using Enum.each or Enum.map based on whether the body returns a value
     */
    public static function buildMapIteration(pattern: MapIterationPattern, context: CompilationContext): ElixirAST {
        // Import necessary functions
        var buildFromTypedExpr = ElixirASTBuilder.buildFromTypedExpr;
        var makeAST = ElixirASTHelpers.make;
        
        var mapAst = buildFromTypedExpr(pattern.mapExpr, context);
        var bodyAst = buildFromTypedExpr(pattern.body, context);
        
        // Analyze if body collects results
        var isCollecting = analyzesAsExpression(pattern.body);
        
        // Create pattern for destructuring: {key, value}
        var tuplePattern = PTuple([
            PVar(VariableAnalyzer.toElixirVarName(pattern.keyVar)),
            PVar(VariableAnalyzer.toElixirVarName(pattern.valueVar))
        ]);
        
        // Create anonymous function clause
        var fnClause: EFnClause = {
            args: [tuplePattern],
            body: bodyAst
        };
        
        // Choose between Enum.each and Enum.map based on usage
        var enumFunction = isCollecting ? "map" : "each";
        
        return makeAST(ECall(
            makeAST(EVar("Enum")),
            enumFunction,
            [mapAst, makeAST(EFn([fnClause]))]
        ));
    }
    
    /**
     * Simple analysis to determine if expression returns a value
     */
    public static function analyzesAsExpression(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TBlock(stmts):
                if (stmts.length > 0) {
                    analyzesAsExpression(stmts[stmts.length - 1]);
                } else {
                    false;
                }
            case TCall(_, _): true; // Function calls can return values
            case TArrayDecl(_): true; // Array literals return values  
            case TObjectDecl(_): true; // Object literals return values
            case TConst(_): true; // Constants return values
            case TLocal(_): true; // Variables return values
            case TBinop(_, _, _): true; // Binary operations return values
            case TUnop(_, _, _): true; // Unary operations return values
            case TReturn(_): false; // Return statements don't return values in the expression sense
            case TFor(_, _) | TWhile(_, _, _): false; // Loops don't return values in Elixir
            default: false;
        };
    }
    
    /**
     * Check if an expression is a simple loop body
     * 
     * Used to determine if a loop can be optimized to a simple Enum operation
     */
    public static function isSimpleLoopBody(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TBlock([single]): isSimpleLoopBody(single);
            case TCall(_, _): true;
            case TVar(_, _): false; // Variable declarations make it complex
            case TIf(_, _, _): false; // Conditionals make it complex
            case TSwitch(_, _, _): false; // Pattern matching makes it complex
            case TFor(_, _) | TWhile(_, _, _): false; // Nested loops are complex
            default: true; // Most expressions are simple
        };
    }
    
    /**
     * Extract the loop variable from a for loop expression
     */
    public static function extractLoopVariable(expr: TypedExpr): Null<TVar> {
        return switch(expr.expr) {
            case TFor(v, _): v;
            case TWhile(_, _, _): null; // While loops don't have a loop variable
            case TBlock([single]): extractLoopVariable(single);
            default: null;
        };
    }
    
    /**
     * Check if an expression contains a loop
     */
    public static function containsLoop(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TFor(_, _) | TWhile(_, _, _): true;
            case TBlock(exprs): 
                Lambda.exists(exprs, containsLoop);
            case TIf(_, thenExpr, elseExpr):
                containsLoop(thenExpr) || (elseExpr != null && containsLoop(elseExpr));
            case TSwitch(_, cases, def):
                Lambda.exists(cases, c -> containsLoop(c.expr)) || 
                (def != null && containsLoop(def));
            case TTry(e, catches):
                containsLoop(e) || Lambda.exists(catches, c -> containsLoop(c.expr));
            default: false;
        };
    }
}

// MapIterationPattern typedef is in ElixirASTBuilder.hx

#end