package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPatterns;
import reflaxe.elixir.CompilationContext;

/**
 * ControlFlowBuilder: Builds ElixirAST nodes for control flow constructs
 *
 * WHY: Control flow in Haxe needs careful transformation to idiomatic
 * Elixir patterns. Elixir's functional nature requires different
 * approaches for conditionals, exceptions, and returns.
 *
 * WHAT: Converts control flow nodes to Elixir constructs:
 * - TIf conditionals → if/else or case expressions
 * - TTry/catch → try/rescue/catch blocks
 * - TThrow → raise or throw
 * - TReturn → function returns (context-aware)
 * - TContinue/TBreak → loop control (handled by LoopBuilder)
 * - Ternary operators → inline if expressions
 *
 * HOW: Analyzes context to determine the most appropriate Elixir
 * construct. Simple conditionals become if/else, complex patterns
 * use case, exceptions map to rescue/catch based on type.
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles control flow
 * - Context Awareness: Understands function vs loop context
 * - Error Handling: Proper exception transformation
 * - Pattern Matching: Leverages Elixir's pattern matching where appropriate
 *
 * EDGE CASES:
 * - Returns in nested functions
 * - Early returns in loops
 * - Multiple catch blocks
 * - Finally blocks (after in Elixir)
 * - Conditional returns vs expressions
 *
 * @see ElixirASTBuilder for integration
 * @see CompilationContext for return context management
 */
class ControlFlowBuilder {

    /**
     * Build an if/else conditional
     *
     * WHY: If statements are expressions in Elixir
     * WHAT: Converts TIf to if/else expression
     * HOW: Handles both statement and expression contexts
     *
     * @param condition The condition to evaluate
     * @param thenExpr Expression for true branch
     * @param elseExpr Optional expression for false branch
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildIf(
        condition: TypedExpr,
        thenExpr: TypedExpr,
        elseExpr: Null<TypedExpr>,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        // Check for pattern matching opportunities
        if (isPatternMatchCandidate(condition)) {
            return buildPatternMatchIf(condition, thenExpr, elseExpr, context);
        }

        // Build standard if/else
        var condAST = exprBuilder(condition);
        var thenAST = exprBuilder(thenExpr);
        var elseAST = elseExpr != null ? exprBuilder(elseExpr) : makeAST(ENil);

        return makeAST(EIf(condAST, thenAST, elseAST));
    }

    /**
     * Build a try/catch block
     *
     * WHY: Exception handling differs between Haxe and Elixir
     * WHAT: Converts TTry to try/rescue/catch/after
     * HOW: Maps Haxe exceptions to Elixir error handling
     *
     * @param tryExpr The expression to try
     * @param catches Array of catch clauses
     * @param finallyExpr Optional finally block
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildTry(
        tryExpr: TypedExpr,
        catches: Array<{v: TVar, expr: TypedExpr}>,
        finallyExpr: Null<TypedExpr>,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var tryAST = exprBuilder(tryExpr);

        // Build rescue clauses for exceptions
        var rescueClauses = [];
        var catchClauses = [];

        for (c in catches) {
            var clause = buildCatchClause(c.v, c.expr, context);
            if (isExceptionType(c.v.t)) {
                rescueClauses.push(clause);
            } else {
                catchClauses.push(clause);
            }
        }

        // Build after clause if finally exists
        var afterAST = finallyExpr != null ? exprBuilder(finallyExpr) : null;

        return makeAST(ETry(
            tryAST,
            rescueClauses,
            catchClauses,
            null, // else clause
            afterAST
        ));
    }

    /**
     * Build a throw expression
     *
     * WHY: Throw maps to raise or throw depending on context
     * WHAT: Converts TThrow to appropriate Elixir construct
     * HOW: Analyzes exception type to determine handling
     *
     * @param expr The expression to throw
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildThrow(
        expr: TypedExpr,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var exprAST = exprBuilder(expr);

        // Determine if this is an exception or a throw
        if (isException(expr)) {
            // Use raise for exceptions
            return makeAST(ERaise(exprAST));
        } else {
            // Use throw for non-local returns
            return makeAST(EThrow(exprAST));
        }
    }

    /**
     * Build a return statement
     *
     * WHY: Returns need context awareness in Elixir
     * WHAT: Converts TReturn to appropriate return
     * HOW: Handles function vs anonymous function context
     *
     * @param expr Optional return value
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildReturn(
        expr: Null<TypedExpr>,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var returnValue = expr != null ? exprBuilder(expr) : makeAST(ENil);

        // In Elixir, the last expression is the return value
        // Explicit return is only needed for early returns
        if (context.isInAnonymousFunction) {
            // In anonymous functions, we can't use return
            // Need to structure code to avoid early returns
            return returnValue;
        } else {
            // In named functions, we can use explicit return
            return makeAST(EReturn(returnValue));
        }
    }

    /**
     * Build a ternary conditional (? :)
     *
     * WHY: Ternary operators become inline if expressions
     * WHAT: Converts to compact if/else
     * HOW: Creates inline if expression
     */
    public static function buildTernary(
        condition: TypedExpr,
        thenExpr: TypedExpr,
        elseExpr: TypedExpr,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        // In Elixir, use inline if
        var condAST = exprBuilder(condition);
        var thenAST = exprBuilder(thenExpr);
        var elseAST = exprBuilder(elseExpr);

        // Generate: if condition, do: then_expr, else: else_expr
        return makeAST(EInlineIf(condAST, thenAST, elseAST));
    }

    /**
     * Build a cond expression (multiple conditions)
     *
     * WHY: Multiple if/else chains are better as cond in Elixir
     * WHAT: Converts chained conditionals to cond
     * HOW: Analyzes if/else chain and generates cond clauses
     */
    public static function buildCond(
        conditions: Array<{condition: TypedExpr, body: TypedExpr}>,
        defaultBody: Null<TypedExpr>,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var clauses = [];

        for (c in conditions) {
            clauses.push({
                condition: exprBuilder(c.condition),
                body: exprBuilder(c.body)
            });
        }

        // Add default clause if present
        if (defaultBody != null) {
            clauses.push({
                condition: makeAST(EBoolean(true)),
                body: exprBuilder(defaultBody)
            });
        }

        return makeAST(ECond(clauses));
    }

    /**
     * Build a with expression (sequential pattern matching)
     *
     * WHY: With expressions provide railway-oriented programming
     * WHAT: Converts sequential operations to with expression
     * HOW: Chains pattern matches with early exit on failure
     */
    public static function buildWith(
        bindings: Array<{pattern: EPattern, expr: TypedExpr}>,
        body: TypedExpr,
        elseClause: Null<Array<{pattern: EPattern, body: TypedExpr}>>,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var withBindings = bindings.map(b -> {
            pattern: b.pattern,
            expr: exprBuilder(b.expr)
        });

        var bodyAST = exprBuilder(body);

        var elseClauses = elseClause != null ?
            elseClause.map(c -> {
                pattern: c.pattern,
                body: exprBuilder(c.body)
            }) : null;

        return makeAST(EWith(withBindings, bodyAST, elseClauses));
    }

    // Helper functions
    static var exprBuilder: TypedExpr -> ElixirAST;

    static function isPatternMatchCandidate(condition: TypedExpr): Bool {
        // Check if condition would benefit from pattern matching
        return switch(condition.expr) {
            case TCall(_, _): true; // Function calls returning tuples
            case TField(_, _): true; // Field access that might be pattern matched
            default: false;
        };
    }

    static function buildPatternMatchIf(
        condition: TypedExpr,
        thenExpr: TypedExpr,
        elseExpr: Null<TypedExpr>,
        context: CompilationContext
    ): ElixirAST {
        // Convert to case expression for pattern matching
        var condAST = exprBuilder(condition);
        var thenAST = exprBuilder(thenExpr);
        var elseAST = elseExpr != null ? exprBuilder(elseExpr) : makeAST(ENil);

        return makeAST(ECase(
            condAST,
            [
                {
                    pattern: PLiteral(EBoolean(true)),
                    guard: null,
                    body: thenAST
                },
                {
                    pattern: PWildcard,
                    guard: null,
                    body: elseAST
                }
            ]
        ));
    }

    static function buildCatchClause(
        catchVar: TVar,
        expr: TypedExpr,
        context: CompilationContext
    ): ECatchClause {
        // Build pattern for catch variable
        var pattern = if (isExceptionType(catchVar.t)) {
            // Exception pattern
            PException(catchVar.name, null);
        } else {
            // General catch pattern
            PVar(catchVar.name);
        };

        return {
            pattern: pattern,
            guard: null,
            body: exprBuilder(expr)
        };
    }

    static function isExceptionType(t: Type): Bool {
        // Check if type is an exception type
        return switch(t) {
            case TInst(cls, _):
                var c = cls.get();
                // Check if class extends or is named like an exception
                c.name.indexOf("Exception") != -1 ||
                c.name.indexOf("Error") != -1;
            default:
                false;
        };
    }

    static function isException(expr: TypedExpr): Bool {
        // Check if expression is an exception
        return isExceptionType(expr.t);
    }

    // AST construction helper
    static function makeAST(def: ElixirASTDef): ElixirAST {
        return {
            def: def,
            metadata: {},
            pos: null
        };
    }
}

#end