package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoQueryIIFEInlineTransforms
 *
 * WHAT
 * - Inlines immediately-invoked anonymous functions (IIFEs) used to construct
 *   the query argument of Ecto.Query.where/2 into their final expression,
 *   removing scaffolding like `(fn -> query3 = from(...); this1 = query3; this1 end).()`
 *
 * WHY
 * - Upstream extraction passes can introduce inner-lambda wrappers around
 *   `from/2` to preserve sequencing. For Ecto DSL, this is non-idiomatic and
 *   harms readability. The queryable should be `from(t in Schema, ...)` directly.
 *
 * HOW
 * - Detect `ERemoteCall(Ecto.Query, "where", [q, binding, cond])` where `q`
 *   is an IIFE: `ECall((EFn ...), [])` (possibly wrapped in EParen).
 * - Inspect the function body. If it returns a variable `v`, locate the most
 *   recent assignment to `v` within the body. If that assignment's RHS is a
 *   `ERemoteCall(_, "from", _)`, use that RHS to replace `q`.
 * - Conservative: Only rewrite when a clear `from/2` RHS is found. Otherwise
 *   leave the node untouched.
 *
 * EXAMPLES
 * Elixir (before):
 *   Ecto.Query.where((fn -> query3 = Ecto.Query.from(t in App.Todo, []); this1 = nil; this1 = query3; this1 end).(), [t], ...)
 * Elixir (after):
 *   Ecto.Query.where(Ecto.Query.from(t in App.Todo, []), [t], ...)
 */
class EctoQueryIIFEInlineTransforms {
    static function unwrapParen(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): unwrapParen(inner);
            default: e;
        }
    }

    static function lastExprOf(body: ElixirAST): Null<ElixirAST> {
        return switch (body.def) {
            case EBlock(exprs) if (exprs.length > 0): exprs[exprs.length - 1];
            default: body;
        }
    }

    static function findAssignment(name: String, body: ElixirAST): Null<ElixirAST> {
        // Scan block statements from end to start to find the last assignment to name
        return switch (body.def) {
            case EBlock(exprs):
                var i = exprs.length - 1;
                while (i >= 0) {
                    switch (exprs[i].def) {
                        case EMatch(PVar(v), rhs) if (v == name):
                            return rhs;
                        default:
                    }
                    i--;
                }
                null;
            default:
                null;
        }
    }

    static function inlineIIFE(iface: ElixirAST): Null<ElixirAST> {
        // Expect ECall(targetFn, "", []) where targetFn is EFn (possibly parenthesized)
        return switch (iface.def) {
            case ECall(fnTarget, func, args) if (func == "" && (args == null || args.length == 0)):
                var t = unwrapParen(fnTarget);
                switch (t.def) {
                    case EFn(clauses) if (clauses.length > 0):
                        var body = clauses[0].body;
                        var last = lastExprOf(body);
                        switch (last.def) {
                            case EVar(retName):
                                // Follow assignments retName := ... until we find from/2
                                var rhs = findAssignment(retName, body);
                                var guard = 0;
                                while (rhs != null && guard++ < 5) {
                                    switch (rhs.def) {
                                        case ERemoteCall(mod, fn, args) if (fn == "from"):
                                            return rhs; // Found the from/2 call to inline
                                        case EVar(nextName):
                                            rhs = findAssignment(nextName, body);
                                        default:
                                            // Not a supported pattern
                                            return null;
                                    }
                                }
                                null;
                            default:
                                null;
                        }
                    default:
                        null;
                }
            default:
                null;
        }
    }

    static function inlineBlock(qarg: ElixirAST): Null<ElixirAST> {
        // When the query arg is an EBlock, the printer will emit an IIFE. Try to collapse it.
        return switch (qarg.def) {
            case EBlock(_):
                var last = lastExprOf(qarg);
                switch (last.def) {
                    case EVar(retName):
                        var rhs = findAssignment(retName, qarg);
                        var guard = 0;
                        while (rhs != null && guard++ < 5) {
                            switch (rhs.def) {
                                case ERemoteCall(mod, fn, args) if (fn == "from"):
                                    return rhs;
                                case EVar(nextName):
                                    rhs = findAssignment(nextName, qarg);
                                default:
                                    return null;
                            }
                        }
                        null;
                    default:
                        null;
                }
            default:
                null;
        }
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, func, args) if (func == "where" && args != null && args.length >= 1):
                    // Ensure module is Ecto.Query
                    var modStr = switch (mod.def) {
                        case EVar(m): m;
                        default: reflaxe.elixir.ast.ElixirASTPrinter.printAST(mod);
                    };
                    if (modStr != "Ecto.Query") return n;
                    var qArg = args[0];
                    var simplified = inlineIIFE(qArg);
                    if (simplified == null) simplified = inlineBlock(qArg);
                    if (simplified != null) {
                        var newArgs = args.copy();
                        newArgs[0] = simplified;
                        makeASTWithMeta(ERemoteCall(mod, func, newArgs), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }
}

#end
