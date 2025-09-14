package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * FunctionUsageCollector: Tracks which private functions are actually called
 *
 * WHY: Many private helper functions (especially operator overloads) are generated
 * but never used, causing compilation warnings in Elixir.
 *
 * WHAT: Collects all function calls during AST traversal to determine which
 * private functions are actually referenced in the code.
 *
 * HOW: Recursively traverses TypedExpr to find all TCall expressions and records
 * which functions are being called. This information is used to prefix unused
 * private functions with underscore.
 */
class FunctionUsageCollector {
    /**
     * Map from module name + function name to usage count
     * Key format: "ModuleName.functionName" or just "functionName" for local calls
     */
    public var functionUsage: Map<String, Int> = new Map();

    /**
     * Track all private functions defined in the current module
     * Key format: "functionName" -> arity
     */
    public var definedPrivateFunctions: Map<String, Int> = new Map();

    /**
     * Current module being processed
     */
    public var currentModule: String = "";

    public function new() {}

    /**
     * Register a private function definition
     */
    public function registerPrivateFunction(name: String, arity: Int): Void {
        definedPrivateFunctions.set(name, arity);
        #if debug_function_usage
        trace('[FunctionUsage] Registered private function: $name/$arity in module $currentModule');
        #end
    }

    /**
     * Check if a private function is used
     */
    public function isFunctionUsed(name: String): Bool {
        var key = name;
        var fullKey = '$currentModule.$name';

        return functionUsage.exists(key) || functionUsage.exists(fullKey);
    }

    /**
     * Collect all function calls in an expression
     */
    public function collectCalls(expr: TypedExpr): Void {
        if (expr == null) return;

        switch(expr.expr) {
            case TCall(e, args):
                // Handle the function being called
                switch(e.expr) {
                    case TField(target, FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf)):
                        recordFunctionCall(cf.get().name);
                        #if debug_function_usage
                        trace('[FunctionUsage] Found call to: ${cf.get().name}');
                        #end

                    case TField(_, FEnum(_, ef)):
                        // Enum constructors, not relevant for function usage

                    case TLocal(v):
                        // Local variable call (like function variable)
                        recordFunctionCall(v.name);

                    case TIdent(name):
                        // Direct identifier call
                        recordFunctionCall(name);

                    default:
                        // Recursively process the expression
                        collectCalls(e);
                }

                // Process all arguments
                for (arg in args) {
                    collectCalls(arg);
                }

            case TFunction(f):
                // Process function body
                if (f.expr != null) {
                    collectCalls(f.expr);
                }

            case TBlock(exprs):
                for (e in exprs) {
                    collectCalls(e);
                }

            case TIf(cond, eif, eelse):
                collectCalls(cond);
                collectCalls(eif);
                if (eelse != null) collectCalls(eelse);

            case TSwitch(e, cases, edef):
                collectCalls(e);
                for (c in cases) {
                    collectCalls(c.expr);
                }
                if (edef != null) collectCalls(edef);

            case TWhile(cond, e, _):
                collectCalls(cond);
                collectCalls(e);

            case TFor(_, e1, e2):
                collectCalls(e1);
                collectCalls(e2);

            case TTry(e, catches):
                collectCalls(e);
                for (c in catches) {
                    collectCalls(c.expr);
                }

            case TReturn(e):
                if (e != null) collectCalls(e);

            case TBinop(_, e1, e2):
                // Binary operations might be function calls for operator overloads
                collectCalls(e1);
                collectCalls(e2);

            case TUnop(_, _, e):
                collectCalls(e);

            case TArrayDecl(el):
                for (e in el) {
                    collectCalls(e);
                }

            case TObjectDecl(fields):
                for (f in fields) {
                    collectCalls(f.expr);
                }

            case TNew(_, _, args):
                for (arg in args) {
                    collectCalls(arg);
                }

            case TVar(_, init):
                if (init != null) collectCalls(init);

            case TField(e, _):
                collectCalls(e);

            case TArray(e1, e2):
                collectCalls(e1);
                collectCalls(e2);

            case TParenthesis(e):
                collectCalls(e);

            case TCast(e, _):
                collectCalls(e);

            case TMeta(_, e):
                collectCalls(e);

            default:
                // Terminal cases or unhandled - no recursion needed
        }
    }

    /**
     * Record a function call
     */
    private function recordFunctionCall(name: String): Void {
        var count = functionUsage.get(name);
        if (count == null) count = 0;
        functionUsage.set(name, count + 1);

        #if debug_function_usage
        trace('[FunctionUsage] Recorded call to: $name (total: ${count + 1})');
        #end
    }

    /**
     * Get list of unused private functions
     */
    public function getUnusedPrivateFunctions(): Array<String> {
        var unused = [];
        for (name in definedPrivateFunctions.keys()) {
            if (!isFunctionUsed(name)) {
                unused.push(name);
            }
        }
        return unused;
    }

    /**
     * Get list of unused private functions with their arities
     * Returns array of {name: String, arity: Int} objects
     */
    public function getUnusedPrivateFunctionsWithArity(): Array<{name: String, arity: Int}> {
        var unused = [];
        for (name => arity in definedPrivateFunctions) {
            if (!isFunctionUsed(name)) {
                unused.push({name: name, arity: arity});
            }
        }
        return unused;
    }

    /**
     * Debug: Print usage statistics
     */
    public function printStats(): Void {
        #if debug_function_usage
        trace('[FunctionUsage] === Function Usage Statistics ===');
        trace('[FunctionUsage] Module: $currentModule');
        trace('[FunctionUsage] Defined private functions:');
        for (name => arity in definedPrivateFunctions) {
            var used = isFunctionUsed(name);
            trace('[FunctionUsage]   $name/$arity: ${used ? "USED" : "UNUSED"}');
        }
        trace('[FunctionUsage] All function calls:');
        for (name => count in functionUsage) {
            trace('[FunctionUsage]   $name: $count calls');
        }
        trace('[FunctionUsage] === End Statistics ===');
        #end
    }
}

#end