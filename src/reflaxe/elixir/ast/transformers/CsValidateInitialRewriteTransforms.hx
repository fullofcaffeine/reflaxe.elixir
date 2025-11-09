package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CsValidateInitialRewriteTransforms
 *
 * WHAT
 * - Rewrites the first `cs = if ... do Ecto.Changeset.validate_*(cs, ...) else cs end`
 *   to use the most recent temp changeset alias (thisN) instead of `cs` when `cs`
 *   has not yet been declared. This avoids referencing `cs` before assignment.
 *
 * WHY
 * - Some pipelines build the initial changeset into compiler temps (thisN) and only
 *   later attempt to assign into `cs` via an `if` expression referencing `cs` on RHS.
 *
 * HOW
 * - Within function bodies, track the most-recent alias `thisA = thisB`. When the
 *   first assignment to `cs = if ...` is encountered and `cs` has not been declared
 *   yet, rewrite occurrences of `cs` inside that if-expression to the tracked temp.
 */
class CsValidateInitialRewriteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body):
                    makeAST(EDef(name, params, guards, rewriteInBody(body)));
                case EDefp(name, params, guards, body):
                    makeAST(EDefp(name, params, guards, rewriteInBody(body)));
                default: n;
            }
        });
    }

    static function rewriteInBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                var lastTemp:String = null;
                var csDeclared = false;
                for (s in stmts) {
                    // track declarations
                    switch (s.def) {
                        case EBinary(Match, lhs, rhs):
                            switch [lhs.def, rhs.def] {
                                case [EVar(a), EVar(b)]:
                                    if (a == "cs") csDeclared = true; else if (isTemp(a) && isTemp(b)) lastTemp = b;
                                default:
                            }
                        case EMatch(pat, rhs2):
                            switch [pat, rhs2.def] {
                                case [PVar(a), EVar(b)]:
                                    if (a == "cs") csDeclared = true; else if (isTemp(a) && isTemp(b)) lastTemp = b;
                                default:
                            }
                        default:
                    }
                    // rewrite first assignment to cs = if ... when cs not yet declared
                    if (!csDeclared && lastTemp != null) {
                        switch (s.def) {
                            case EBinary(Match, lhs2, rhsIf):
                                switch [lhs2.def, rhsIf.def] {
                                    case [EVar("cs"), EIf(c,t,e)]:
                                        out.push(makeAST(EBinary(Match, lhs2, rewriteCsInIf(rhsIf, lastTemp))));
                                        csDeclared = true; // after this, cs exists
                                        continue;
                                    default:
                                }
                            default:
                        }
                    }
                    out.push(s);
                }
                makeAST(EBlock(out));
            default:
                body;
        }
    }

    static function rewriteCsInIf(ifNode: ElixirAST, temp:String): ElixirAST {
        function sub(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case EVar(v) if (v == "cs"): makeAST(EVar(temp));
                case _:
                    ElixirASTTransformer.transformNode(n, sub);
            }
        }
        return sub(ifNode);
    }

    static function isTemp(name:String):Bool {
        return StringTools.startsWith(name, "this") && ~/^this\d+$/.match(name);
    }
}

#end

