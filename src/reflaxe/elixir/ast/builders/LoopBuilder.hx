package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPatterns;
import reflaxe.elixir.CompilationContext;

/**
 * LoopBuilder: Builds ElixirAST nodes for loop constructs
 *
 * WHY: Loops in Haxe need to be transformed to functional Elixir patterns.
 * Elixir doesn't have traditional imperative loops - instead it uses
 * recursion, Enum functions, and comprehensions. This module handles
 * these complex transformations.
 *
 * WHAT: Converts loop nodes to appropriate Elixir constructs:
 * - TWhile loops → recursive functions or Enum operations
 * - TFor loops → Enum.map/reduce or comprehensions
 * - Array.map/filter patterns → Enum operations
 * - Do-while patterns → recursive functions with initial execution
 * - Break/continue → early returns in recursive functions
 *
 * HOW: Analyzes loop patterns to determine the most idiomatic Elixir
 * transformation. Simple iterations become Enum operations, complex
 * state mutations become recursive functions, and collection operations
 * use comprehensions where appropriate.
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles loop transformations
 * - Pattern Recognition: Identifies and optimizes common loop patterns
 * - Idiomatic Output: Generates functional Elixir, not imperative translations
 * - Testability: Loop transformations can be tested in isolation
 *
 * EDGE CASES:
 * - Nested loops with shared state
 * - Break/continue in nested contexts
 * - Loop variable mutations
 * - Early returns from loops
 * - Infinite loops (while true)
 *
 * @see ElixirASTBuilder for integration
 * @see CompilationContext for loop counter management
 */
class LoopBuilder {

    /**
     * Build a while loop expression
     *
     * WHY: While loops don't exist in Elixir, must transform to recursion
     * WHAT: Converts TWhile to recursive function or Enum operation
     * HOW: Analyzes loop pattern and generates appropriate functional code
     *
     * @param condition Loop continuation condition
     * @param body Loop body to execute
     * @param doWhile True if this is a do-while pattern
     * @param context Compilation context with state
     * @param buildExpr Callback for recursive expression building
     */
    public static function buildWhile(
        condition: TypedExpr,
        body: TypedExpr,
        doWhile: Bool,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        // Store expression builder for helper functions
        exprBuilder = buildExpr;

        // Detect special patterns
        if (isInfiniteLoop(condition)) {
            return buildInfiniteLoop(body, context);
        }

        if (isSimpleCountingLoop(condition, body)) {
            return buildCountingLoop(condition, body, context);
        }

        // Default: Build recursive function
        return buildRecursiveWhile(condition, body, doWhile, context);
    }

    /**
     * Build a for loop expression
     *
     * WHY: For loops need transformation to Enum operations
     * WHAT: Converts TFor to Enum.map, Enum.each, or comprehensions
     * HOW: Analyzes iteration pattern and collection type
     *
     * @param init Loop initialization
     * @param condition Loop condition
     * @param increment Loop increment expression
     * @param body Loop body
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildFor(
        init: TypedExpr,
        condition: TypedExpr,
        increment: TypedExpr,
        body: TypedExpr,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        // Store expression builder
        exprBuilder = buildExpr;

        // Detect for-in pattern (iterating over collection)
        if (isForInPattern(init, condition)) {
            return buildForIn(init, condition, body, context);
        }

        // Detect counting pattern (for i = 0; i < n; i++)
        if (isCountingPattern(init, condition, increment)) {
            return buildCountingFor(init, condition, increment, body, context);
        }

        // Default: Convert to while loop equivalent
        return buildForAsWhile(init, condition, increment, body, context);
    }

    /**
     * Build a break statement
     *
     * WHY: Break doesn't exist in functional loops
     * WHAT: Converts to early return or throw for non-local exit
     * HOW: Depends on loop context - may use special return value
     */
    public static function buildBreak(context: CompilationContext): ElixirAST {
        // In a recursive function, break becomes a return with special value
        if (context.currentLoopContext != null) {
            return makeAST(EReturn(makeAST(ETuple([
                makeAST(EAtom("break")),
                makeAST(ENil)
            ]))));
        }

        // Outside loop context, this is an error
        return makeAST(EComment("ERROR: break outside loop"));
    }

    /**
     * Build a continue statement
     *
     * WHY: Continue needs to trigger next iteration in functional style
     * WHAT: Converts to recursive call or next iteration marker
     * HOW: Depends on loop transformation used
     */
    public static function buildContinue(context: CompilationContext): ElixirAST {
        // In recursive function, continue becomes recursive call
        if (context.currentLoopContext != null) {
            var loopFunc = context.currentLoopContext.functionName;
            var loopArgs = context.currentLoopContext.stateVariables;
            return makeAST(ECall(
                makeAST(EVar(loopFunc)),
                loopArgs.map(v -> makeAST(EVar(v)))
            ));
        }

        // Outside loop context, this is an error
        return makeAST(EComment("ERROR: continue outside loop"));
    }

    // Helper functions
    static var exprBuilder: TypedExpr -> ElixirAST;

    static function buildInfiniteLoop(body: TypedExpr, context: CompilationContext): ElixirAST {
        // Generate: Stream.cycle([nil]) |> Enum.each(fn _ -> body end)
        var bodyAST = exprBuilder(body);

        return makeAST(EPipe([
            makeAST(ECall(
                makeAST(EField(makeAST(EVar("Stream")), "cycle")),
                [makeAST(EList([makeAST(ENil)]))]
            )),
            makeAST(ECall(
                makeAST(EField(makeAST(EVar("Enum")), "each")),
                [makeAST(EFunction(["_"], bodyAST))]
            ))
        ]));
    }

    static function buildCountingLoop(condition: TypedExpr, body: TypedExpr, context: CompilationContext): ElixirAST {
        // Extract loop bounds from condition
        var bounds = extractLoopBounds(condition);
        if (bounds == null) {
            return buildRecursiveWhile(condition, body, false, context);
        }

        // Generate: Enum.each(start..end, fn i -> body end)
        var rangeAST = makeAST(EBinop(
            ERange,
            makeAST(EInteger(bounds.start)),
            makeAST(EInteger(bounds.end))
        ));

        var bodyAST = exprBuilder(body);

        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "each")),
            [rangeAST, makeAST(EFunction(["i"], bodyAST))]
        ));
    }

    static function buildRecursiveWhile(
        condition: TypedExpr,
        body: TypedExpr,
        doWhile: Bool,
        context: CompilationContext
    ): ElixirAST {
        // Generate unique loop function name
        var loopName = "loop_" + context.loopCounter++;

        // Build recursive function
        var condAST = exprBuilder(condition);
        var bodyAST = exprBuilder(body);

        // Create recursive function definition
        var loopFunc = makeAST(EFunction(
            [], // No parameters for simple while
            makeAST(EIf(
                condAST,
                makeAST(EBlock([
                    bodyAST,
                    makeAST(ECall(makeAST(EVar(loopName)), []))
                ])),
                makeAST(EAtom("ok"))
            ))
        ));

        // For do-while, execute body once before loop
        if (doWhile) {
            return makeAST(EBlock([
                bodyAST,
                makeAST(EBind(loopName, loopFunc)),
                makeAST(ECall(makeAST(EVar(loopName)), []))
            ]));
        }

        // Regular while: define and call
        return makeAST(EBlock([
            makeAST(EBind(loopName, loopFunc)),
            makeAST(ECall(makeAST(EVar(loopName)), []))
        ]));
    }

    static function buildForIn(
        init: TypedExpr,
        condition: TypedExpr,
        body: TypedExpr,
        context: CompilationContext
    ): ElixirAST {
        // Extract collection and iterator variable
        var collection = extractCollection(init);
        var iterVar = extractIteratorVariable(init);

        if (collection == null || iterVar == null) {
            // Fallback to generic for handling
            return buildForAsWhile(init, condition, null, body, context);
        }

        var collectionAST = exprBuilder(collection);
        var bodyAST = exprBuilder(body);

        // Generate: Enum.each(collection, fn var -> body end)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "each")),
            [collectionAST, makeAST(EFunction([iterVar], bodyAST))]
        ));
    }

    static function buildCountingFor(
        init: TypedExpr,
        condition: TypedExpr,
        increment: TypedExpr,
        body: TypedExpr,
        context: CompilationContext
    ): ElixirAST {
        // Extract start, end, and step values
        var start = extractInitValue(init);
        var end = extractEndValue(condition);
        var step = extractStepValue(increment);

        // Generate range with step if needed
        var rangeAST = if (step == 1) {
            makeAST(EBinop(
                ERange,
                makeAST(EInteger(start)),
                makeAST(EInteger(end))
            ));
        } else {
            makeAST(ECall(
                makeAST(EField(makeAST(EVar("Range")), "new")),
                [
                    makeAST(EInteger(start)),
                    makeAST(EInteger(end)),
                    makeAST(EInteger(step))
                ]
            ));
        };

        var bodyAST = exprBuilder(body);

        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "each")),
            [rangeAST, makeAST(EFunction(["i"], bodyAST))]
        ));
    }

    static function buildForAsWhile(
        init: TypedExpr,
        condition: TypedExpr,
        increment: TypedExpr,
        body: TypedExpr,
        context: CompilationContext
    ): ElixirAST {
        // Convert for loop to equivalent while loop
        var initAST = if (init != null) exprBuilder(init) else makeAST(ENil);

        var loopBody = if (increment != null) {
            makeAST(EBlock([
                exprBuilder(body),
                exprBuilder(increment)
            ]));
        } else {
            exprBuilder(body);
        };

        var whileAST = buildWhile(condition, {
            expr: TBlock([body, increment].filter(e -> e != null)),
            t: body.t,
            pos: body.pos
        }, false, context, exprBuilder);

        return makeAST(EBlock([initAST, whileAST]));
    }

    // Pattern detection helpers
    static function isInfiniteLoop(condition: TypedExpr): Bool {
        return switch(condition.expr) {
            case TConst(TBool(true)): true;
            default: false;
        };
    }

    static function isSimpleCountingLoop(condition: TypedExpr, body: TypedExpr): Bool {
        // Check if this is a simple i < n pattern
        return switch(condition.expr) {
            case TBinop(OpLt, {expr: TLocal(_)}, {expr: TConst(TInt(_))}): true;
            case TBinop(OpLt, {expr: TLocal(_)}, {expr: TLocal(_)}): true;
            default: false;
        };
    }

    static function isForInPattern(init: TypedExpr, condition: TypedExpr): Bool {
        // Detect for-in iteration pattern
        // This would need more sophisticated analysis
        return false; // Simplified for now
    }

    static function isCountingPattern(init: TypedExpr, condition: TypedExpr, increment: TypedExpr): Bool {
        // Detect for(i = 0; i < n; i++) pattern
        if (init == null || condition == null || increment == null) return false;

        // Check for i = number initialization
        var hasInit = switch(init.expr) {
            case TVar(_, {expr: TConst(TInt(_))}): true;
            default: false;
        };

        // Check for i < something condition
        var hasCondition = switch(condition.expr) {
            case TBinop(OpLt | OpLte, _, _): true;
            default: false;
        };

        // Check for i++ or i += 1 increment
        var hasIncrement = switch(increment.expr) {
            case TUnop(OpIncrement, _, _): true;
            case TBinop(OpAssignOp(OpAdd), _, {expr: TConst(TInt(1))}): true;
            default: false;
        };

        return hasInit && hasCondition && hasIncrement;
    }

    // Extraction helpers
    static function extractLoopBounds(condition: TypedExpr): Null<{start: Int, end: Int}> {
        // Simplified extraction - would need more analysis
        return switch(condition.expr) {
            case TBinop(OpLt, _, {expr: TConst(TInt(n))}):
                {start: 0, end: n - 1};
            case TBinop(OpLte, _, {expr: TConst(TInt(n))}):
                {start: 0, end: n};
            default:
                null;
        };
    }

    static function extractCollection(init: TypedExpr): Null<TypedExpr> {
        // Extract collection from for-in initialization
        return null; // Simplified
    }

    static function extractIteratorVariable(init: TypedExpr): Null<String> {
        // Extract iterator variable name
        return switch(init.expr) {
            case TVar(v, _): v.name;
            default: null;
        };
    }

    static function extractInitValue(init: TypedExpr): Int {
        return switch(init.expr) {
            case TVar(_, {expr: TConst(TInt(n))}): n;
            default: 0;
        };
    }

    static function extractEndValue(condition: TypedExpr): Int {
        return switch(condition.expr) {
            case TBinop(OpLt, _, {expr: TConst(TInt(n))}): n - 1;
            case TBinop(OpLte, _, {expr: TConst(TInt(n))}): n;
            default: 0;
        };
    }

    static function extractStepValue(increment: TypedExpr): Int {
        return switch(increment.expr) {
            case TUnop(OpIncrement, _, _): 1;
            case TBinop(OpAssignOp(OpAdd), _, {expr: TConst(TInt(n))}): n;
            default: 1;
        };
    }

    // AST construction helpers
    static function makeAST(def: ElixirASTDef): ElixirAST {
        return {
            def: def,
            metadata: {},
            pos: null
        };
    }
}

#end