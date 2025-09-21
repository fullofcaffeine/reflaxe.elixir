package reflaxe.elixir.preprocessors;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import reflaxe.preprocessors.BasePreprocessor;
import reflaxe.data.ClassFuncData;
import reflaxe.BaseCompiler;

using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.NullHelper;

/**
 * PreserveSwitchReturnsImpl - Transparent Switch Expression Preservation for Idiomatic Elixir
 *
 * ## Problem: Paradigm Mismatch
 *
 * Haxe's typer assumes an imperative execution model where switch expressions in return
 * position can be simplified to just the final value. For example:
 * ```haxe
 * return switch(result) {
 *     case Ok(value): value;
 *     case Error(_): defaultValue;
 * }
 * ```
 *
 * Gets simplified to just `return value` in the TypedExpr, losing ALL pattern matching
 * structure. This is fine for imperative targets (JS, C++) that pre-extract variables,
 * but breaks expression-based languages like Elixir.
 *
 * ## Why This Breaks Elixir
 *
 * Elixir needs the complete case expression structure because:
 * 1. Pattern variables are bound IN the pattern, not pre-declared
 * 2. The case expression IS the return value (not separate control flow)
 * 3. Variables from patterns only exist in their branch scope
 *
 * Without preservation, we'd generate invalid Elixir:
 * ```elixir
 * def unwrap_or(result, default_value) do
 *   value  # ERROR: undefined variable!
 * end
 * ```
 *
 * ## The Solution: Structure Preservation
 *
 * This preprocessor transparently transforms switch-in-return expressions BEFORE
 * Haxe's typer can simplify them away:
 *
 * **Haxe Input:**
 * ```haxe
 * return switch(result) {
 *     case Ok(value): value;
 *     case Error(msg): throw msg;
 * }
 * ```
 *
 * **Internal Transformation:**
 * ```haxe
 * var __elixir_switch_result = switch(result) {
 *     case Ok(value): value;
 *     case Error(msg): throw msg;
 * }
 * return __elixir_switch_result;
 * ```
 *
 * **Idiomatic Elixir Output:**
 * ```elixir
 * def process(result) do
 *   case result do
 *     {:ok, value} -> value
 *     {:error, msg} -> raise msg
 *   end
 * end
 * ```
 *
 * Notice how the Elixir output is perfectly idiomatic - the temporary variable
 * is optimized away during code generation, leaving clean pattern matching!
 *
 * ## How It Works
 *
 * 1. **Detection**: Scans TypedExpr for TReturn(TSwitch(...)) patterns
 * 2. **Transformation**: Wraps switch in temporary variable assignment
 * 3. **Preservation**: Prevents Haxe's typer from simplifying the structure
 * 4. **Transparent**: Runs automatically - no user code changes needed
 * 5. **Clean Output**: Temporary variables are eliminated in final Elixir
 *
 * ## Benefits
 *
 * - **Idiomatic Code**: Generates clean Elixir case expressions
 * - **No Manual Workarounds**: Users don't need to know about the limitation
 * - **Universal Solution**: Works for all switch-in-return patterns
 * - **Future-Proof**: When Haxe adds expression preservation flags, we can remove this
 *
 * ## Examples of Idiomatic Generation
 *
 * ### Option Type Handling
 * ```haxe
 * // Haxe
 * public static function getOrElse<T>(opt: Option<T>, default: T): T {
 *     return switch(opt) {
 *         case Some(v): v;
 *         case None: default;
 *     };
 * }
 * ```
 *
 * ```elixir
 * # Generated Elixir (idiomatic!)
 * def get_or_else(opt, default) do
 *   case opt do
 *     {:some, v} -> v
 *     :none -> default
 *   end
 * end
 * ```
 *
 * ### Result Type with Multiple Patterns
 * ```haxe
 * // Haxe
 * return switch(parseResult) {
 *     case Success(data): processData(data);
 *     case Warning(data, msg): { log(msg); processData(data); }
 *     case Failure(error): handleError(error);
 * };
 * ```
 *
 * ```elixir
 * # Generated Elixir (clean pattern matching!)
 * case parse_result do
 *   {:success, data} -> process_data(data)
 *   {:warning, data, msg} ->
 *     log(msg)
 *     process_data(data)
 *   {:failure, error} -> handle_error(error)
 * end
 * ```
 *
 * ## Integration
 *
 * Added as the FIRST preprocessor in CompilerInit.hx to run before any other
 * transformations that might interfere with pattern detection.
 *
 * @see IMPERATIVE_VS_EXPRESSION_PARADIGM_MISMATCH.md for architectural details
 * @see SWITCH_RETURN_COMPREHENSIVE_REPORT.md for research and alternatives
 */
class PreserveSwitchReturnsImpl extends BasePreprocessor {
    static var preservationCounter = 0;

    /**
     * Process function data according to BasePreprocessor interface
     * Transforms the function body to preserve switch-in-return patterns
     */
    public function process(data: ClassFuncData, compiler: BaseCompiler): Void {
        #if debug_preprocessors
        trace('[PreserveSwitchReturns] Processing function');
        #end
        // Transform the function body if it exists
        if (data.expr != null) {
            #if debug_preprocessors
            trace('[PreserveSwitchReturns] Function body exists, transforming...');
            #end
            var transformed = transformExpression(data.expr);
            if (transformed != data.expr) {
                #if debug_preprocessors
                trace('[PreserveSwitchReturns] Function was transformed!');
                #end
                data.setExpr(transformed);
            }
        }
    }

    public function new() {}

    /**
     * Recursively transform expressions to preserve switch-in-return patterns
     * Works on TypedExpr (what the compiler receives)
     */
    function transformExpression(expr: TypedExpr): TypedExpr {
        if (expr == null) return null;

        return switch(expr.expr) {
            // FOUND IT! Direct return of switch expression
            case TReturn(e) if (e != null):
                #if debug_preprocessors
                trace('[PreserveSwitchReturns] Found TReturn with expr type: ' + e.expr);
                #end
                // Check if the return expression is a switch (may be wrapped in metadata)
                var innerExpr = e;

                // Unwrap TMeta if present (:ast metadata is added by Haxe)
                switch(e.expr) {
                    case TMeta(_, actualExpr):
                        #if debug_preprocessors
                        trace('[PreserveSwitchReturns] Unwrapping TMeta to find actual switch');
                        #end
                        innerExpr = actualExpr;
                    case _:
                }

                switch(innerExpr.expr) {
                    case TSwitch(scrutinee, cases, defaultCase):
                        #if debug_preprocessors
                        trace('[PreserveSwitchReturns] Found switch in return position!');
                        trace('[PreserveSwitchReturns] Creating preservation wrapper...');
                        #end

                        // Create a unique variable name
                        var varName = "__elixir_switch_result_" + (++preservationCounter);

                        // Create a typed variable to hold the switch result
                        var tvar: TVar = {
                            id: -preservationCounter, // Unique negative ID
                            name: varName,
                            t: innerExpr.t, // Use the switch expression's type
                            capture: false,
                            isStatic: false,
                            extra: null,
                            meta: null
                        };

                        // Create variable declaration with switch as initializer
                        var varDecl: TypedExpr = {
                            expr: TVar(tvar, innerExpr), // The original switch expression (unwrapped)
                            pos: innerExpr.pos,
                            t: innerExpr.t
                        };

                        // Create reference to the variable
                        var varRef: TypedExpr = {
                            expr: TLocal(tvar),
                            pos: expr.pos,
                            t: innerExpr.t
                        };

                        // Create return of the variable
                        var returnVar: TypedExpr = {
                            expr: TReturn(varRef),
                            pos: expr.pos,
                            t: expr.t
                        };

                        // Create a block with both statements
                        var block: TypedExpr = {
                            expr: TBlock([varDecl, returnVar]),
                            pos: expr.pos,
                            t: expr.t
                        };

                        #if debug_preprocessors
                        trace('[PreserveSwitchReturns] Transformed to: var $varName = switch(...); return $varName;');
                        #end

                        return block;

                    case _:
                        // Not a switch, but recursively process the return value
                        var transformedReturn = transformExpression(e);
                        if (transformedReturn != e) {
                            return {
                                expr: TReturn(transformedReturn),
                                pos: expr.pos,
                                t: expr.t
                            };
                        }
                        return expr;
                }

            // Block - process all sub-expressions
            case TBlock(exprs):
                var transformed = exprs.map(transformExpression);
                var changed = false;
                for (i in 0...exprs.length) {
                    if (transformed[i] != exprs[i]) {
                        changed = true;
                        break;
                    }
                }
                if (changed) {
                    return {
                        expr: TBlock(transformed),
                        pos: expr.pos,
                        t: expr.t
                    };
                }
                return expr;

            // If statement - process all branches
            case TIf(cond, then, els):
                var transformedCond = transformExpression(cond);
                var transformedThen = transformExpression(then);
                var transformedEls = els != null ? transformExpression(els) : null;

                if (transformedCond != cond || transformedThen != then || transformedEls != els) {
                    return {
                        expr: TIf(transformedCond, transformedThen, transformedEls),
                        pos: expr.pos,
                        t: expr.t
                    };
                }
                return expr;

            // While loop - process condition and body
            case TWhile(cond, body, normalWhile):
                var transformedCond = transformExpression(cond);
                var transformedBody = transformExpression(body);

                if (transformedCond != cond || transformedBody != body) {
                    return {
                        expr: TWhile(transformedCond, transformedBody, normalWhile),
                        pos: expr.pos,
                        t: expr.t
                    };
                }
                return expr;

            // For loop - process iterator and body
            case TFor(v, iter, body):
                var transformedIter = transformExpression(iter);
                var transformedBody = transformExpression(body);

                if (transformedIter != iter || transformedBody != body) {
                    return {
                        expr: TFor(v, transformedIter, transformedBody),
                        pos: expr.pos,
                        t: expr.t
                    };
                }
                return expr;

            // Try-catch - process try block and catch blocks
            case TTry(e, catches):
                var transformedTry = transformExpression(e);
                var transformedCatches = catches.map(c -> {
                    var transformedExpr = transformExpression(c.expr);
                    if (transformedExpr != c.expr) {
                        {v: c.v, expr: transformedExpr};
                    } else {
                        c;
                    }
                });

                var changed = transformedTry != e;
                if (!changed) {
                    for (i in 0...catches.length) {
                        if (transformedCatches[i] != catches[i]) {
                            changed = true;
                            break;
                        }
                    }
                }

                if (changed) {
                    return {
                        expr: TTry(transformedTry, transformedCatches),
                        pos: expr.pos,
                        t: expr.t
                    };
                }
                return expr;

            // Function - process body
            case TFunction(tf):
                if (tf.expr != null) {
                    var transformedBody = transformExpression(tf.expr);
                    if (transformedBody != tf.expr) {
                        var newTf: TFunc = {
                            args: tf.args,
                            expr: transformedBody,
                            t: tf.t
                        };
                        return {
                            expr: TFunction(newTf),
                            pos: expr.pos,
                            t: expr.t
                        };
                    }
                }
                return expr;

            // Default - for other expression types, return unchanged
            case _:
                // For other expression types that don't contain nested structures
                // we need to process, just return unchanged
                return expr;
        }
    }
}

#end