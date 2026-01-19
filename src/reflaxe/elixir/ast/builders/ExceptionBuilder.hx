package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.ERescueClause;
import reflaxe.elixir.ast.ElixirAST.ECaseClause;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.builders.ModuleBuilder;
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

    static inline var HAXE_THROW_MODULE = "Reflaxe.Elixir.HaxeThrow";
    static inline var HAXE_THROW_VALUE_FIELD = "value";
    
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
            #end
            return null;
        }
        
        // Haxe `try/catch` must not intercept loop-control `throw(:break|:continue)` which we use internally.
        // Those are Elixir `throw/1` payloads and are intentionally handled by `catch` clauses in LoopBuilder.
        // Therefore, we compile Haxe exceptions as Elixir exceptions (raise/rescue), not `throw`.

        var exceptionVarName = "haxe_exception";
        var exceptionVar = makeAST(EVar(exceptionVarName));

        // Normalize the rescued exception into a "thrown value":
        // - If it's our wrapper exception, unwrap the original value.
        // - Otherwise, treat the exception struct itself as the thrown value.
        var unwrapValueVarName = "haxe_unwrapped_value";
        var unwrapCase = makeAST(ECase(exceptionVar, [
            {
                pattern: PStruct(HAXE_THROW_MODULE, [{key: HAXE_THROW_VALUE_FIELD, value: PVar(unwrapValueVarName)}]),
                body: makeAST(EVar(unwrapValueVarName))
            },
            {
                pattern: PWildcard,
                body: exceptionVar
            }
        ]));

        // Dispatch uses `{thrown_value, exception}` so we can bind either the original thrown
        // value (default) or the exception struct (for `catch(e:haxe.Exception)`).
        var dispatchScrutinee = makeAST(ETuple([unwrapCase, exceptionVar]));

        var hasCatchAll = false;
        var hasHaxeExceptionCatch = false;
        var caseClauses: Array<ECaseClause> = [];

        for (c in catches) {
            var catchVarName = VariableAnalyzer.toElixirVarName(c.v.name);
            var isHaxeExceptionCatch = isHaxeExceptionCatchType(c.v.t);
            if (isCatchAll(c.v)) hasCatchAll = true;
            if (isHaxeExceptionCatch) hasHaxeExceptionCatch = true;

            var catchBody = if (context.compiler != null) {
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(c.expr, context);
            } else {
                makeAST(ENil);
            };

            if (catchBody == null) catchBody = makeAST(ENil);

            var pattern:EPattern;
            var guard:Null<ElixirAST> = null;

            if (isHaxeExceptionCatch) {
                // Bind the exception struct itself as the catch variable.
                pattern = PTuple([PWildcard, catchVarName == "_" ? PWildcard : PVar(catchVarName)]);
            } else {
                // Bind the original thrown value as the catch variable.
                var thrownBinderName = catchVarName == "_" ? "haxe_catch_value" : catchVarName;
                pattern = PTuple([PVar(thrownBinderName), PWildcard]);
                if (!isCatchAll(c.v)) {
                    guard = buildCatchTypeGuard(makeAST(EVar(thrownBinderName)), c.v.t);
                    if (guard == null) guard = makeAST(EBoolean(false));
                }
            }

            caseClauses.push({
                pattern: pattern,
                guard: guard,
                body: catchBody
            });
        }

        if (!hasCatchAll && !hasHaxeExceptionCatch) {
            // Preserve original exception and stacktrace when no Haxe catch matches.
            // This keeps semantics consistent with Haxe: unmatched exceptions propagate.
            caseClauses.push({
                pattern: PWildcard,
                body: makeAST(ECall(null, "reraise", [exceptionVar, makeAST(EVar("__STACKTRACE__"))]))
            });
        }

        var rescueBody = makeAST(ECase(dispatchScrutinee, caseClauses));

        var rescueClauses: Array<ERescueClause> = [{
            pattern: PVar(exceptionVarName),
            body: rescueBody
        }];

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
            #end
            return null;
        }
        
        // Compile Haxe `throw` as Elixir `raise` so it is caught by `rescue` and does not
        // interfere with internal loop-control `throw(:break|:continue)` which uses `catch`.
        //
        // We wrap non-exception values in a stable exception module so Haxe can `throw` any term
        // (strings, ints, maps, etc.) while still using Elixir's exception mechanism.
        // Ensure the thrown expression is evaluated exactly once: we only pass it as `value: ...`.
        // The wrapper exception can derive a message on demand (or default to an empty message).
        var attrs = makeAST(EKeywordList([
            {key: HAXE_THROW_VALUE_FIELD, value: throwExpr}
        ]));
        return ERaise(makeAST(EVar(HAXE_THROW_MODULE)), attrs);
    }

    static function buildCatchTypeGuard(valueExpr: ElixirAST, t: Null<Type>): Null<ElixirAST> {
        if (t == null) return null;
        return switch (t) {
            case TDynamic(_):
                null;
            case TLazy(f):
                buildCatchTypeGuard(valueExpr, f());
            case TMono(_):
                null;
            case TAbstract(absRef, _):
                var abs = absRef.get();
                var pack = abs.pack;
                var name = abs.name;
                // Common core abstracts.
                if (pack.length == 0) {
                    switch (name) {
                        case "Int": makeAST(ECall(null, "is_integer", [valueExpr]));
                        case "Float": makeAST(ECall(null, "is_float", [valueExpr]));
                        case "Bool": makeAST(ECall(null, "is_boolean", [valueExpr]));
                        default: null;
                    }
                } else {
                    null;
                }
            case TInst(clsRef, _):
                var cls = clsRef.get();
                if (cls.name == "String") {
                    makeAST(ECall(null, "is_binary", [valueExpr]));
                } else if (cls.name == "Array") {
                    makeAST(ECall(null, "is_list", [valueExpr]));
                } else if (cls.name == "Map") {
                    makeAST(ECall(null, "is_map", [valueExpr]));
                } else {
                    // User-defined classes compile to structs; use is_struct/2 for precise matching.
                    var moduleName = ModuleBuilder.extractModuleName(cls);
                    makeAST(ECall(null, "is_struct", [valueExpr, makeAST(EVar(moduleName))]));
                }
            case TEnum(enumRef, _):
                // Enums compile to tagged tuples like {:some, v} / {:none}.
                // We approximate `catch(e:MyEnum)` as `is_tuple(e) and elem(e, 0) in [:tag1, ...]`.
                var enm = enumRef.get();
                var tags: Array<ElixirAST> = [];
                for (c in enm.constructs) {
                    tags.push(makeAST(EAtom(c.name)));
                }
                // Avoid generating nonsense for empty enums.
                if (tags.length == 0) {
                    null;
                } else {
                    var isTuple = makeAST(ECall(null, "is_tuple", [valueExpr]));
                    var tag0 = makeAST(ECall(null, "elem", [valueExpr, makeAST(EInteger(0))]));
                    var inTags = makeAST(EBinary(In, tag0, makeAST(EList(tags))));
                    makeAST(EBinary(And, isTuple, inTags));
                }
            default:
                null;
        }
    }

    static function isHaxeExceptionCatchType(t: Null<Type>): Bool {
        if (t == null) return false;
        return switch (t) {
            case TLazy(f):
                isHaxeExceptionCatchType(f());
            case TInst(clsRef, _):
                var cls = clsRef.get();
                cls.pack.length == 1 && cls.pack[0] == "haxe" && cls.name == "Exception";
            default:
                false;
        };
    }

    // NOTE: buildTry tracks presence inline.
    
    /**
     * Build break control flow exception
     * 
     * WHY: Loops need break capability in Elixir
     * WHAT: Generates a throw payload for loop control
     * HOW:
     * - When inside a reduce_while-lowered loop, we throw a tagged tuple carrying the
     *   loop's current state so the reducer can convert it to {:halt, state}.
     * - Outside of a known loop context, we fall back to throw(:break) (legacy).
     * 
     * @return ElixirASTDef for break exception
     */
    public static function buildBreak(context: CompilationContext): ElixirASTDef {
        #if debug_ast_builder
        #end
        
        if (context == null || context.loopControlStateStack == null || context.loopControlStateStack.length == 0) {
            // Legacy fallback: throw :break atom (may be caught by reducer wrappers).
            return EThrow(makeAST(EAtom("break")));
        }

        var top = context.loopControlStateStack[context.loopControlStateStack.length - 1];
        var stateExpr: ElixirAST = if (top == null) {
            // Stateless loops use `acc` as their reduce_while state.
            makeAST(EVar("acc"));
        } else {
            makeAST(ETuple([for (name in top) makeAST(EVar(name))]));
        };

        return EThrow(makeAST(ETuple([makeAST(EAtom("break")), stateExpr])));
    }
    
    /**
     * Build continue control flow exception
     * 
     * WHY: Loops need continue capability in Elixir
     * WHAT: Generates a throw payload for loop control
     * HOW:
     * - When inside a reduce_while-lowered loop, we throw a tagged tuple carrying the
     *   loop's current state so the reducer can convert it to {:cont, state}.
     * - Outside of a known loop context, we fall back to throw(:continue) (legacy).
     * 
     * @return ElixirASTDef for continue exception
     */
    public static function buildContinue(context: CompilationContext): ElixirASTDef {
        #if debug_ast_builder
        #end
        
        if (context == null || context.loopControlStateStack == null || context.loopControlStateStack.length == 0) {
            // Legacy fallback: throw :continue atom (may be caught by reducer wrappers).
            return EThrow(makeAST(EAtom("continue")));
        }

        var top = context.loopControlStateStack[context.loopControlStateStack.length - 1];
        var stateExpr: ElixirAST = if (top == null) {
            makeAST(EVar("acc"));
        } else {
            makeAST(ETuple([for (name in top) makeAST(EVar(name))]));
        };

        return EThrow(makeAST(ETuple([makeAST(EAtom("continue")), stateExpr])));
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
