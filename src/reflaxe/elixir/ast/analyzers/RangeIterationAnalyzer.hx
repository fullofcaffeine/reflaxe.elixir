package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.loop_ir.LoopIR;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;

/**
 * RangeIterationAnalyzer: Detects Simple Range Loops
 *
 * WHY: Many loops are simple iterations from 0 to n or between bounds.
 * These should become Range operations in Elixir, not complex reduce_while.
 *
 * WHAT: Detects patterns like:
 * - for (i in 0...n)
 * - for (i in start...end)
 * - while (i < limit) with i++
 * - Haxe's desugared array iteration patterns
 *
 * HOW: Pattern matches on loop structure to identify:
 * - Start and end values
 * - Step size (usually 1)
 * - Index variable name
 * - Whether it's inclusive or exclusive
 *
 * ARCHITECTURE BENEFITS:
 * - Focused on single pattern type
 * - High confidence detection
 * - Enables Range generation
 * - Simplifies subsequent emission
 */
// Type definition must be at module level, not inside class
typedef RangeInfo = {
    start: TypedExpr,
    end: TypedExpr,
    step: Int,
    indexVar: String,
    isInclusive: Bool
}

class RangeIterationAnalyzer extends BaseLoopAnalyzer {

    var detectedRange: Null<RangeInfo> = null;

    public function analyze(expr: TypedExpr, ir: LoopIR): Void {
        switch(expr.expr) {
            case TFor(v, iterator, body):
                analyzeForLoop(v, iterator, body, ir);

            case TWhile(cond, body, true):  // normal while
                analyzeWhileLoop(cond, body, ir);

            case _:
                // Not a loop we handle
        }
    }

    function analyzeForLoop(v: TVar, iterator: TypedExpr, body: TypedExpr, ir: LoopIR): Void {
        // Check for range pattern: 0...n or start...end
        switch(iterator.expr) {
            case TBinop(OpInterval, startExpr, endExpr):
                // Haxe's ... operator (exclusive range)
                detectedRange = {
                    start: startExpr,
                    end: endExpr,
                    step: 1,
                    indexVar: v.name,
                    isInclusive: false
                };

                ir.kind = ForRange;
                // Store the range info for later use
                detectedRange = {
                    start: startExpr,
                    end: endExpr,
                    step: 1,
                    indexVar: v.name,
                    isInclusive: false
                };
                // Don't build AST during analysis - just mark the pattern
                // The emitter will get the original TFor expr and extract what it needs
                ir.source = Collection(makeAST(ENil));  // Will be replaced by emitter
                ir.elementPattern = {
                    varName: v.name,
                    pattern: makeAST(ENil), // Placeholder
                    type: v.t
                };

                trace('Detected range iteration: ${v.name} in ${printExpr(startExpr)}...${printExpr(endExpr)}');

            case _:
                // Not a simple range
        }
    }

    function analyzeWhileLoop(cond: TypedExpr, body: TypedExpr, ir: LoopIR): Void {
        // Pattern: while (i < limit) with i++ in body

        // Extract condition pattern
        var condPattern = extractWhileCondition(cond);
        if (condPattern == null) return;

        // Look for increment in body
        var increment = findIncrement(body, condPattern.indexVar);
        if (increment == null) return;

        // This is a range loop!
        detectedRange = {
            start: makeConstInt(0),  // Assume 0 if not found
            end: condPattern.limit,
            step: increment.step,
            indexVar: condPattern.indexVar,
            isInclusive: condPattern.isInclusive
        };

        ir.kind = While;  // Will be transformed to ForRange
        // Don't build AST during analysis - causes infinite recursion!
        ir.source = Range(
            makeAST(ENil),  // Placeholder - emitter will build from detectedRange
            makeAST(ENil),  // Placeholder - emitter will build from detectedRange
            detectedRange.step
        );
        ir.elementPattern = {
            varName: condPattern.indexVar,
            pattern: makeAST(ENil), // Placeholder
            type: condPattern.type
        };

        trace('Detected while-based range: ${condPattern.indexVar} from 0 to ${printExpr(condPattern.limit)}');
    }

    function extractWhileCondition(cond: TypedExpr): Null<{indexVar: String, limit: TypedExpr, isInclusive: Bool, type: Type}> {
        // Handle parenthesis wrapper
        var actualCond = switch(cond.expr) {
            case TParenthesis(e): e;
            case _: cond;
        };

        switch(actualCond.expr) {
            case TBinop(OpLt, {expr: TLocal(v)}, limitExpr):
                return {
                    indexVar: v.name,
                    limit: limitExpr,
                    isInclusive: false,
                    type: v.t
                };

            case TBinop(OpLte, {expr: TLocal(v)}, limitExpr):
                return {
                    indexVar: v.name,
                    limit: limitExpr,
                    isInclusive: true,
                    type: v.t
                };

            case _:
                return null;
        }
    }

    function findIncrement(body: TypedExpr, varName: String): Null<{step: Int}> {
        // Look for i++ or i += n patterns
        var increments = findAll(body, FunctionCall);

        for (expr in increments) {
            switch(expr.expr) {
                case TUnop(OpIncrement, _, {expr: TLocal(v)}) if (v.name == varName):
                    return {step: 1};

                case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, {expr: TConst(TInt(n))}) if (v.name == varName):
                    return {step: n};

                case _:
                    // Keep looking
            }
        }

        return null;
    }

    public function calculateConfidence(): Float {
        if (detectedRange != null) {
            // High confidence for simple range patterns
            return 0.9;
        }
        return 0.0;
    }


    function makeConstInt(n: Int): TypedExpr {
        return {
            expr: TConst(TInt(n)),
            pos: Context.currentPos(),
            t: Context.typeof(macro $v{n})
        };
    }

    function printExpr(expr: TypedExpr): String {
        // Simplified expression printer for debug
        return switch(expr.expr) {
            case TConst(TInt(n)): Std.string(n);
            case TLocal(v): v.name;
            case _: "expr";
        };
    }
}

#end