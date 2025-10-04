package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.ERescueClause;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;

/**
 * ExceptionBuilder: Handles try/catch/throw exception patterns
 * 
 * WHY: Centralizes exception handling transformation from Haxe to Elixir
 * - Simplifies ElixirASTBuilder by extracting ~70 lines of exception code
 * - Provides consistent exception pattern transformation
 * - Handles try/catch blocks with proper rescue clauses
 * - Manages throw/break/continue control flow exceptions
 * 
 * WHAT: Transforms Haxe exception handling to idiomatic Elixir patterns
 * - TTry/TCatch → try/rescue blocks with pattern matching
 * - TThrow → Elixir throw with proper atom formatting
 * - TBreak/TContinue → Special control flow exceptions
 * - Exception variable naming and pattern extraction
 * 
 * HOW: AST transformation with Elixir exception semantics
 * - Converts catch clauses to rescue clauses with patterns
 * - Handles exception variable binding in rescue blocks
 * - Transforms control flow breaks to throwable atoms
 * - Preserves exception handling semantics across languages
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on exception handling
 * - Open/Closed Principle: Can extend exception patterns without modifying core
 * - Testability: Exception handling can be tested independently
 * - Maintainability: Clear boundaries for exception-related code
 * 
 * EDGE CASES:
 * - Empty catch blocks (generate nil body)
 * - Multiple catch clauses (multiple rescue patterns)
 * - Nested try blocks (proper scoping)
 * - Control flow exceptions (break/continue in loops)
 * - Rethrow patterns (re-raising exceptions)
 */
@:nullSafety(Off)
class ExceptionBuilder {
    
    /**
     * Build try/catch exception handling block
     * 
     * WHY: Exception handling is fundamental for error recovery
     * WHAT: Converts TTry with catch clauses to Elixir try/rescue
     * HOW: Transforms body and catch clauses to rescue patterns
     * 
     * @param e The expression to try
     * @param catches Array of catch clauses
     * @param context Compilation context
     * @return ElixirASTDef for try/rescue block
     */
    public static function buildTry(e: TypedExpr, catches: Array<{v:TVar, expr:TypedExpr}>, context: CompilationContext): Null<ElixirASTDef> {
        #if debug_ast_builder
        trace('[ExceptionBuilder] Building try/catch block');
        trace('[ExceptionBuilder]   ${catches.length} catch clauses');
        #end
        
        // Build the try body
        var body = if (context.compiler != null) {
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);
        } else {
            return null;
        };
        
        if (body == null) {
            #if debug_ast_builder
            trace('[ExceptionBuilder] Failed to build try body');
            #end
            return null;
        }
        
        // Build rescue clauses from catch blocks
        var rescueClauses: Array<ERescueClause> = [];
        
        for (c in catches) {
            // Create pattern for the exception variable
            var pattern = PVar(VariableAnalyzer.toElixirVarName(c.v.name));
            
            // Build the catch body
            var catchBody = if (context.compiler != null) {
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(c.expr, context);
            } else {
                makeAST(ENil);
            };
            
            if (catchBody == null) {
                catchBody = makeAST(ENil);
            }
            
            rescueClauses.push({
                pattern: pattern,
                body: catchBody
            });
            
            #if debug_ast_builder
            trace('[ExceptionBuilder] Added rescue clause for: ${c.v.name}');
            #end
        }
        
        // Generate try/rescue block
        // ETry(body, rescueClauses, elseClauses, afterBlock, catchAllBlock)
        return ETry(body, rescueClauses, [], null, null);
    }
    
    /**
     * Build throw expression
     * 
     * WHY: Exceptions need to be raised in Elixir
     * WHAT: Converts TThrow to Elixir throw
     * HOW: Wraps expression in EThrow
     * 
     * @param e The expression to throw
     * @param context Compilation context
     * @return ElixirASTDef for throw expression
     */
    public static function buildThrow(e: TypedExpr, context: CompilationContext): Null<ElixirASTDef> {
        #if debug_ast_builder
        trace('[ExceptionBuilder] Building throw expression');
        #end
        
        var throwExpr = if (context.compiler != null) {
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);
        } else {
            return null;
        };
        
        if (throwExpr == null) {
            #if debug_ast_builder
            trace('[ExceptionBuilder] Failed to build throw expression');
            #end
            return null;
        }
        
        return EThrow(throwExpr);
    }
    
    /**
     * Build break control flow exception
     * 
     * WHY: Loops need break capability in Elixir
     * WHAT: Generates throw(:break) for loop control
     * HOW: Creates atom throw that loop handlers catch
     * 
     * @return ElixirASTDef for break exception
     */
    public static function buildBreak(): ElixirASTDef {
        #if debug_ast_builder
        trace('[ExceptionBuilder] Building break exception');
        #end
        
        // Throw :break atom that will be caught by loop transformation
        return EThrow(makeAST(EAtom("break")));
    }
    
    /**
     * Build continue control flow exception
     * 
     * WHY: Loops need continue capability in Elixir
     * WHAT: Generates throw(:continue) for loop control
     * HOW: Creates atom throw that loop handlers catch
     * 
     * @return ElixirASTDef for continue exception
     */
    public static function buildContinue(): ElixirASTDef {
        #if debug_ast_builder
        trace('[ExceptionBuilder] Building continue exception');
        #end
        
        // Throw :continue atom that will be caught by loop transformation
        return EThrow(makeAST(EAtom("continue")));
    }
    
    /**
     * Check if a catch clause catches all exceptions
     * 
     * WHY: Some catch clauses are catch-all handlers
     * WHAT: Detects wildcard or Dynamic type catches
     * HOW: Checks variable type for catch-all patterns
     * 
     * @param v The catch variable
     * @return true if this catches all exceptions
     */
    public static function isCatchAll(v: TVar): Bool {
        // Check if the catch variable type is Dynamic or unspecified
        return switch(v.t) {
            case TDynamic(_): true;
            case null: true;  // Untyped catch
            default: false;
        };
    }
    
    /**
     * Get exception type name for pattern matching
     * 
     * WHY: Different exception types need different patterns
     * WHAT: Extracts the exception type for rescue matching
     * HOW: Analyzes type to generate appropriate pattern
     * 
     * @param t The exception type
     * @return Exception type name or null for catch-all
     */
    public static function getExceptionTypeName(t: Type): Null<String> {
        return switch(t) {
            case TInst(c, _):
                var cls = c.get();
                cls.name;
            case TAbstract(a, _):
                var abs = a.get();
                abs.name;
            default:
                null;  // Catch-all
        };
    }
}

#end