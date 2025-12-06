package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * Represents early exit patterns detected in loops
 */
enum EarlyExitPattern {
    BreakPattern(condition: Null<TypedExpr>);
    ReturnPattern(condition: Null<TypedExpr>, value: TypedExpr);
    ContinuePattern(condition: Null<TypedExpr>);
    NoEarlyExit;
}

/**
 * EarlyExitAnalyzer: Detects loops with early exit patterns for reduce_while
 *
 * WHY: Elixir doesn't have break/continue - must use reduce_while for early termination
 * - Detects break statements in loop bodies
 * - Detects return statements for early loop termination
 * - Determines if loop needs reduce_while pattern
 *
 * WHAT: Analyzes loop bodies for early exit patterns
 * - Identifies break/return/continue statements
 * - Checks conditions for early exit
 * - Determines accumulator needs
 *
 * HOW: AST traversal and pattern detection
 * - Traverse loop body looking for exit patterns
 * - Analyze conditions guarding exits
 * - Generate reduce_while transformation instructions
 */
class EarlyExitAnalyzer {

    /**
     * Analyze a loop body for early exit patterns
     *
     * @param body Loop body expression
     * @return Detected early exit pattern
     */
    public static function analyzeLoopBody(body: TypedExpr): EarlyExitPattern {
        #if debug_loop_builder
        // DISABLED: trace("[EarlyExitAnalyzer] Analyzing loop body for early exits");
        #end

        // Look for break/return patterns
        var exitInfo = findEarlyExitInBody(body);
        if (exitInfo != null) {
            #if debug_loop_builder
            // DISABLED: trace("[EarlyExitAnalyzer] Found early exit pattern: " + exitInfo);
            #end
            return exitInfo;
        }

        #if debug_loop_builder
        // DISABLED: trace("[EarlyExitAnalyzer] No early exit patterns found");
        #end
        return NoEarlyExit;
    }

    /**
     * Find early exit patterns in the loop body
     */
    static function findEarlyExitInBody(expr: TypedExpr): Null<EarlyExitPattern> {
        var result: Null<EarlyExitPattern> = null;

        function search(e: TypedExpr) {
            switch (e.expr) {
                case TBreak:
                    // Found a break statement
                    result = BreakPattern(null);

                case TReturn(valueExpr):
                    // Found a return statement
                    result = ReturnPattern(null, valueExpr != null ? valueExpr : makeNullExpr(e.pos));

                case TContinue:
                    // Found a continue statement
                    result = ContinuePattern(null);

                case TIf(condition, thenExpr, elseExpr):
                    // Check if branches contain exits
                    var thenExit = findEarlyExitInBody(thenExpr);
                    if (thenExit != null) {
                        // Exit is conditional on the if condition
                        result = addConditionToPattern(thenExit, condition);
                        return;
                    }
                    if (elseExpr != null) {
                        var elseExit = findEarlyExitInBody(elseExpr);
                        if (elseExit != null) {
                            // Exit is conditional on negation of if condition
                            result = addConditionToPattern(elseExit, negateCondition(condition));
                            return;
                        }
                    }

                case TBlock(exprs):
                    for (blockExpr in exprs) {
                        search(blockExpr);
                        if (result != null) return;
                    }

                case TSwitch(_, cases, _):
                    for (c in cases) {
                        if (c.expr != null) {
                            search(c.expr);
                            if (result != null) return;
                        }
                    }

                case _:
                    // Continue searching in sub-expressions manually
            }
        }

        search(expr);
        return result;
    }

    /**
     * Add a condition to an early exit pattern
     */
    static function addConditionToPattern(pattern: EarlyExitPattern, condition: TypedExpr): EarlyExitPattern {
        return switch(pattern) {
            case BreakPattern(_): BreakPattern(condition);
            case ReturnPattern(_, value): ReturnPattern(condition, value);
            case ContinuePattern(_): ContinuePattern(condition);
            case NoEarlyExit: NoEarlyExit;
        };
    }

    /**
     * Negate a condition expression
     */
    static function negateCondition(condition: TypedExpr): TypedExpr {
        return {
            expr: TUnop(OpNot, false, condition),
            pos: condition.pos,
            t: condition.t
        };
    }

    /**
     * Create a null expression
     */
    static function makeNullExpr(pos: Position): TypedExpr {
        return {
            expr: TConst(TNull),
            pos: pos,
            t: TAbstract(getBasicType("Null"), [])
        };
    }

    /**
     * Get a basic type (simplified, would need proper type access)
     */
    static function getBasicType(name: String): AbstractType {
        // This is a simplification - in real implementation would get from Context
        return cast {
            name: name,
            pack: [],
            module: name,
            pos: null,
            isPrivate: false,
            params: [],
            meta: null,
            doc: null
        };
    }

    /**
     * Generate transformation for early exit patterns
     *
     * @param pattern The detected pattern
     * @param v Loop variable
     * @param iterator Iterator expression
     * @return LoopBuilder.LoopTransform instruction
     */
    public static function generateTransform(
        pattern: EarlyExitPattern,
        v: TVar,
        iterator: TypedExpr,
        body: TypedExpr
    ): LoopBuilder.LoopTransform {

        switch (pattern) {
            case BreakPattern(condition) | ReturnPattern(condition, _) | ContinuePattern(condition):
                #if debug_loop_builder
                // DISABLED: trace("[EarlyExitAnalyzer] Generating reduce_while for early exit pattern");
                #end
                // For now, return StandardFor as we need more complex transformation
                // TODO: Implement ReduceWhile variant in LoopTransform
                return LoopBuilder.LoopTransform.StandardFor(v, iterator, body);

            case NoEarlyExit:
                #if debug_loop_builder
                // DISABLED: trace("[EarlyExitAnalyzer] No early exit, using standard for");
                #end
                return LoopBuilder.LoopTransform.StandardFor(v, iterator, body);
        }
    }
}

#end