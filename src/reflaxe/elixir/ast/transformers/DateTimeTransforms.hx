package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DateTimeMethodRewrite
 *
 * WHAT
 * - Rewrites method-style calls on DateTime structs (e.g., `now.to_iso8601()`)
 *   to proper module calls `DateTime.to_iso8601(now)`.
 *
 * WHY
 * - Elixir does not support value.method() calls. Some builder paths may emit
 *   method-style calls on DateTime values (from `DateTime.utc_now()`), which
 *   trigger warnings like "expected a module when invoking to_iso8601/0".
 *   This pass restores the idiomatic module form.
 *
 * HOW
 * - Within function bodies, track variables bound from `DateTime.utc_now()`.
 * - When encountering `ECall(target, "to_iso8601", [])` and `target` is one of the
 *   tracked variables, rewrite to `ERemoteCall(DateTime, "to_iso8601", [target])`.
 * - Conservative and shape-based: does not guess types; only rewrites when the
 *   variable was bound from a clear DateTime constructor call.
 *
 * EXAMPLES
 *   now = DateTime.utc_now()
 *   now.to_iso8601()          ->  DateTime.to_iso8601(now)
 */
class DateTimeTransforms {
    public static function dateTimeMethodRewritePass(ast: ElixirAST): ElixirAST {
        function processBody(body: ElixirAST): ElixirAST {
            var dtVars = new Map<String, Bool>();

            // First sweep: collect variables bound from DateTime.utc_now()
            ElixirASTTransformer.transformNode(body, function(n) {
                switch (n.def) {
                    case EMatch(PVar(name), {def: ERemoteCall({def: EVar(mod)}, func, _ )}) if (mod == "DateTime" && func == "utc_now"):
                        dtVars.set(name, true);
                    default:
                }
                return n;
            });

            // Second sweep: rewrite method-style to_iso8601 calls on collected variables
            return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ECall(target, "to_iso8601", args) if (target != null && args != null && args.length == 0):
                        switch (target.def) {
                            case EVar(v) if (dtVars.exists(v)):
                                makeASTWithMeta(ERemoteCall(makeAST(EVar("DateTime")), "to_iso8601", [target]), n.metadata, n.pos);
                            default:
                                n;
                        }
                    default:
                        n;
                }
            });
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, processBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, processBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end

