package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseLengthToListPatternTransforms
 *
 * WHAT
 * - Rewrites `case length(list) do ... end` into `case list do ... end` with
 *   list patterns for common arities. This removes unbound guard aliases like
 *   `arr` and enables idiomatic list matching.
 *
 * WHY
 * - Guards produced around `length(list)` often reference an alias (e.g., `arr`)
 *   that is not actually bound in the pattern, leading to invalid code inside
 *   guards and interpolations. Matching on the list directly solves this.
 *
 * HOW
 * - Detect ECase where the target is a `length(list)` call (remote or local).
 * - Build a new ECase on `list` and map integer patterns 0 and 1 to list
 *   patterns `[]` and `[head | tail]` respectively. For other patterns, keep
 *   them but change `_` to a wildcard.
 * - Conservatively rewrite guard bodies by replacing a free `arr` variable with
 *   the actual list variable to avoid undefined variable errors. This is
 *   shape‑based and scoped to the rewritten case only.
 */
class CaseLengthToListPatternTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    var listExpr: Null<ElixirAST> = extractListFromLength(target);
                    if (listExpr == null) n else {
                        var listVarName = tryExtractVarName(listExpr);
                        var newClauses = [];
                        for (cl in clauses) {
                            var newPat = switch (cl.pattern) {
                                case PLiteral({def: EInteger(0)}): PList([]);
                                case PLiteral({def: EInteger(1)}):
                                    // one-or-more; keep simple cons pattern
                                    PCons(PVar("head"), PVar("tail"));
                                case PVar(name) if (name == "_" || name == "_any"):
                                    PVar("_");
                                default:
                                    // Keep existing pattern
                                    cl.pattern;
                            };
                            var newGuard = cl.guard;
                            if (newGuard != null) newGuard = substituteArrAlias(newGuard, listVarName);
                            newClauses.push({ pattern: newPat, guard: newGuard, body: cl.body });
                        }
                        makeASTWithMeta(ECase(listExpr, newClauses), n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    static function extractListFromLength(e: ElixirAST): Null<ElixirAST> {
        return switch (e.def) {
            case ERemoteCall({def: EVar(mod)}, "length", [list]) if (mod == "Kernel" || mod == "Enum"): list;
            case ECall(null, "length", [list2]): list2;
            default: null;
        }
    }

    static function tryExtractVarName(e: ElixirAST): String {
        return switch (e.def) {
            case EVar(v): v;
            default: "";
        }
    }

    static function substituteArrAlias(guard: ElixirAST, listVar: String): ElixirAST {
        if (listVar == null || listVar == "") return guard;
        return ElixirASTTransformer.transformNode(guard, function(m: ElixirAST): ElixirAST {
            return switch (m.def) {
                case EVar(v) if (v == "arr"): makeAST(EVar(listVar));
                default: m;
            }
        });
    }
}

#end
