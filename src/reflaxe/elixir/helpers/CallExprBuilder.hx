package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.TypedExpr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirExpr;
import reflaxe.elixir.ast.context.BuildContext;

using reflaxe.elixir.ast.ElixirASTHelpers;

/**
 * CallExprBuilder: Specialized builder for function call expressions
 *
 * WHY: Function calls are complex in Haxe→Elixir compilation due to:
 * - Static vs instance method calls requiring different patterns
 * - Abstract type method routing to implementation modules
 * - Operator overloading and special function handling
 * - Module function vs anonymous function calls
 *
 * WHAT: Provides centralized call expression building with:
 * - Proper method dispatch (static/instance/abstract)
 * - Operator overload detection and transformation
 * - Special function handling (trace, throw, etc.)
 * - Anonymous function invocation patterns
 *
 * HOW: Analyzes the call target to determine dispatch pattern:
 * - TField → Module function or method call
 * - TLocal → Anonymous function invocation
 * - TConst → Constructor or enum creation
 * - Applies appropriate transformation for target platform
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles call expressions
 * - Testability: Can test call patterns in isolation
 * - Maintainability: All call logic in one place
 * - Extensibility: Easy to add new call patterns
 */
class CallExprBuilder {
    var context: BuildContext;
    var buildExpr: TypedExpr -> ElixirAST;

    /**
     * Create a new CallExprBuilder
     * @param context The build context for variable resolution
     * @param buildExpr Function to recursively build expressions
     */
    public function new(context: BuildContext, buildExpr: TypedExpr -> ElixirAST) {
        this.context = context;
        this.buildExpr = buildExpr;
    }

    /**
     * Build a call expression
     *
     * WHY: Central entry point for all call expression building
     * WHAT: Analyzes call target and dispatches to appropriate builder
     * HOW: Pattern matches on expression type to determine call pattern
     *
     * @param target The expression being called
     * @param args The call arguments
     * @return ElixirAST representing the call
     */
    public function buildCall(target: TypedExpr, args: Array<TypedExpr>): ElixirAST {
        #if debug_call_expr
        trace('[CallExprBuilder] Building call with target type: ${target.expr}');
        #end

        return switch(target.expr) {
            case TField(e, fa):
                buildFieldCall(e, fa, args);

            case TLocal(v):
                buildLocalCall(v, args);

            case TConst(c):
                buildConstCall(c, args);

            case TIdent(s):
                buildIdentCall(s, args);

            default:
                // Generic function call pattern
                buildGenericCall(target, args);
        };
    }

    /**
     * Build a field access call (method or static function)
     */
    function buildFieldCall(expr: TypedExpr, fieldAccess: FieldAccess, args: Array<TypedExpr>): ElixirAST {
        #if debug_call_expr
        trace('[CallExprBuilder] Field call detected');
        #end

        // Build the target expression
        var targetAST = buildExpr(expr);

        // Get field name and determine call pattern
        var fieldName = getFieldName(fieldAccess);

        // Build argument list
        var argList = args.map(buildExpr);

        // Check if this is a static call
        var isStatic = isStaticCall(fieldAccess);

        if (isStatic) {
            // Static module function call
            return ECall(targetAST, fieldName, argList).ast();
        } else {
            // Instance method call - add self as first argument
            var allArgs = [targetAST].concat(argList);
            return ECall(EVar(getModuleName(expr)), fieldName, allArgs).ast();
        }
    }

    /**
     * Build a local variable call (anonymous function)
     */
    function buildLocalCall(v: TVar, args: Array<TypedExpr>): ElixirAST {
        #if debug_call_expr
        trace('[CallExprBuilder] Anonymous function call: ${v.name}');
        #end

        // Resolve variable name from context
        var varName = context.resolveVariable(v.id, v.name);

        // Build arguments
        var argList = args.map(buildExpr);

        // Anonymous function invocation pattern
        return ECall(EVar(varName), null, argList).ast();
    }

    /**
     * Build a constant call (constructor)
     */
    function buildConstCall(c: TConstant, args: Array<TypedExpr>): ElixirAST {
        return switch(c) {
            case TNull:
                ENil.ast();
            default:
                // Other constants can't be called
                throw 'Cannot call constant: $c';
        };
    }

    /**
     * Build an identifier call
     */
    function buildIdentCall(s: String, args: Array<TypedExpr>): ElixirAST {
        #if debug_call_expr
        trace('[CallExprBuilder] Identifier call: $s');
        #end

        // Special function handling
        if (isSpecialFunction(s)) {
            return buildSpecialCall(s, args);
        }

        // Regular identifier call
        var argList = args.map(buildExpr);
        return ECall(EVar(s), null, argList).ast();
    }

    /**
     * Build a generic call expression
     */
    function buildGenericCall(target: TypedExpr, args: Array<TypedExpr>): ElixirAST {
        var targetAST = buildExpr(target);
        var argList = args.map(buildExpr);
        return ECall(targetAST, null, argList).ast();
    }

    /**
     * Check if a function is special and needs custom handling
     */
    function isSpecialFunction(name: String): Bool {
        return switch(name) {
            case "trace", "throw", "__elixir__": true;
            default: false;
        };
    }

    /**
     * Build special function calls
     */
    function buildSpecialCall(name: String, args: Array<TypedExpr>): ElixirAST {
        return switch(name) {
            case "trace":
                // Transform to Log.trace
                var argList = args.map(buildExpr);
                ECall(EVar("Log"), "trace", argList).ast();

            case "throw":
                // Transform to raise
                var argList = args.map(buildExpr);
                ECall(EVar("raise"), null, argList).ast();

            case "__elixir__":
                // Special Elixir code injection
                // This should be handled elsewhere
                throw '__elixir__ should be handled by compiler';

            default:
                throw 'Unknown special function: $name';
        };
    }

    /**
     * Get field name from field access
     */
    function getFieldName(fa: FieldAccess): String {
        return switch(fa) {
            case FInstance(_, _, cf) | FStatic(_, cf):
                cf.get().name;
            case FAnon(cf):
                cf.get().name;
            case FClosure(_, cf):
                cf.get().name;
            case FDynamic(s):
                s;
            case FEnum(_, ef):
                ef.name;
        };
    }

    /**
     * Check if field access is static
     */
    function isStaticCall(fa: FieldAccess): Bool {
        return switch(fa) {
            case FStatic(_, _): true;
            default: false;
        };
    }

    /**
     * Get module name from expression type
     */
    function getModuleName(expr: TypedExpr): String {
        return switch(expr.t) {
            case TInst(t, _):
                t.get().name + "_Impl_";
            case TAbstract(t, _):
                t.get().name + "_Impl_";
            default:
                throw 'Cannot determine module name for type: ${expr.t}';
        };
    }
}