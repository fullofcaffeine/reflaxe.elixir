package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * Represents a detected array building pattern
 */
enum ArrayBuildingPattern {
    SimpleMap(arrayVar: String, elementExpr: TypedExpr);
    FilterMap(arrayVar: String, condition: TypedExpr, elementExpr: TypedExpr);
    NotArrayBuilding;
}

/**
 * ArrayBuildingAnalyzer: Detects loops that build arrays and transforms them to comprehensions
 *
 * WHY: Haxe's imperative array building patterns should become Elixir comprehensions
 * - Detects patterns like: result = []; for(...) { result.push(x); }
 * - Transforms to: result = for ... <- ..., do: x
 * - Makes generated code more idiomatic and functional
 *
 * WHAT: Analyzes loop bodies for array building patterns
 * - Identifies array initialization before loops
 * - Detects push/append operations in loop body
 * - Determines if loop can be converted to comprehension
 *
 * HOW: Pattern analysis and AST inspection
 * - Check for array variable initialization
 * - Analyze loop body for push operations
 * - Generate comprehension transformation instructions
 */
class ArrayBuildingAnalyzer {

    /**
     * Analyze a for loop to detect array building patterns
     *
     * @param v Loop variable
     * @param iterator Iterator expression
     * @param body Loop body
     * @return Detected pattern or NotArrayBuilding
     */
    public static function analyzeForLoop(v: TVar, iterator: TypedExpr, body: TypedExpr): ArrayBuildingPattern {
        #if debug_loop_builder
        trace("[ArrayBuildingAnalyzer] Analyzing for loop with var: " + v.name);
        #end

        // Look for array.push() calls in the body
        var pushInfo = findArrayPushInBody(body);
        if (pushInfo == null) {
            #if debug_loop_builder
            trace("[ArrayBuildingAnalyzer] No array push found in loop body");
            #end
            return NotArrayBuilding;
        }

        // Check if there's a condition wrapping the push
        var conditionInfo = findConditionAroundPush(body, pushInfo.pushExpr);

        if (conditionInfo != null) {
            #if debug_loop_builder
            trace("[ArrayBuildingAnalyzer] Found filter condition around push");
            #end
            return FilterMap(pushInfo.arrayVar, conditionInfo.condition, pushInfo.element);
        } else {
            #if debug_loop_builder
            trace("[ArrayBuildingAnalyzer] Simple map pattern detected");
            #end
            return SimpleMap(pushInfo.arrayVar, pushInfo.element);
        }
    }

    /**
     * Find array.push() calls in the loop body
     */
    static function findArrayPushInBody(expr: TypedExpr): Null<{arrayVar: String, element: TypedExpr, pushExpr: TypedExpr}> {
        var result = null;

        function search(e: TypedExpr) {
            switch (e.expr) {
                case TCall(methodExpr, [element]):
                    // Check if this is array.push(element)
                    switch (methodExpr.expr) {
                        case TField(objExpr, FInstance(_, _, cf)) if (cf.get().name == "push"):
                            // Found a push call
                            switch (objExpr.expr) {
                                case TLocal(v):
                                    result = {
                                        arrayVar: v.name,
                                        element: element,
                                        pushExpr: e
                                    };
                                case _:
                            }
                        case _:
                    }

                case TBlock(exprs):
                    for (blockExpr in exprs) {
                        search(blockExpr);
                        if (result != null) break;
                    }

                case TIf(_, thenExpr, elseExpr):
                    search(thenExpr);
                    if (result == null && elseExpr != null) {
                        search(elseExpr);
                    }

                case _:
                    // Continue searching in sub-expressions manually
            }
        }

        search(expr);
        return result;
    }

    /**
     * Check if the push operation is wrapped in a condition
     */
    static function findConditionAroundPush(body: TypedExpr, pushExpr: TypedExpr): Null<{condition: TypedExpr}> {
        var result = null;

        function search(e: TypedExpr): Bool {
            switch (e.expr) {
                case TIf(condition, thenExpr, _):
                    // Check if the push is inside this if
                    if (containsExpr(thenExpr, pushExpr)) {
                        result = {condition: condition};
                        return true;
                    }

                case TBlock(exprs):
                    for (blockExpr in exprs) {
                        if (search(blockExpr)) return true;
                    }

                case _:
                    // Check if this is the push expression itself
                    if (e == pushExpr) {
                        return true;
                    }

                    // Continue searching - we'll check sub-expressions manually if needed
                    return false;
            }
            return false;
        }

        search(body);
        return result;
    }

    /**
     * Check if an expression contains another expression
     */
    static function containsExpr(haystack: TypedExpr, needle: TypedExpr): Bool {
        if (haystack == needle) return true;

        // Manually check common expression structures
        return switch(haystack.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    if (containsExpr(e, needle)) return true;
                }
                false;
            case TIf(cond, thenExpr, elseExpr):
                containsExpr(cond, needle) ||
                containsExpr(thenExpr, needle) ||
                (elseExpr != null && containsExpr(elseExpr, needle));
            case TCall(e, params):
                if (containsExpr(e, needle)) return true;
                for (p in params) {
                    if (containsExpr(p, needle)) return true;
                }
                false;
            case _:
                false;
        };
    }

    /**
     * Generate transformation instructions for array building patterns
     *
     * @param pattern The detected pattern
     * @param v Loop variable
     * @param iterator Iterator expression
     * @return LoopBuilder.LoopTransform instruction
     */
    public static function generateTransform(
        pattern: ArrayBuildingPattern,
        v: TVar,
        iterator: TypedExpr
    ): LoopBuilder.LoopTransform {

        switch (pattern) {
            case SimpleMap(arrayVar, elementExpr):
                #if debug_loop_builder
                trace("[ArrayBuildingAnalyzer] Generating comprehension for simple map");
                #end
                // Transform to: arrayVar = for v <- iterator, do: elementExpr
                return LoopBuilder.LoopTransform.Comprehension(
                    arrayVar,
                    v,
                    iterator,
                    null, // no filter
                    elementExpr
                );

            case FilterMap(arrayVar, condition, elementExpr):
                #if debug_loop_builder
                trace("[ArrayBuildingAnalyzer] Generating comprehension with filter");
                #end
                // Transform to: arrayVar = for v <- iterator, condition, do: elementExpr
                return LoopBuilder.LoopTransform.Comprehension(
                    arrayVar,
                    v,
                    iterator,
                    condition,
                    elementExpr
                );

            case NotArrayBuilding:
                #if debug_loop_builder
                trace("[ArrayBuildingAnalyzer] No array building pattern, using standard for");
                #end
                // Fall back to standard for loop
                return LoopBuilder.LoopTransform.StandardFor(v, iterator, null);
        }
    }
}

#end