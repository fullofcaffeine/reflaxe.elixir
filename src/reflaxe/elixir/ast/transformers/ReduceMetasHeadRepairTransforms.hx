package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceMetasHeadRepairTransforms
 *
 * WHAT
 * - Repairs a specific bad lowering inside `Enum.reduce/3` reducer bodies where the
 *   head meta of a Presence-like entry (`entry.metas[0]`) is accidentally replaced by
 *   the reducer binder variable (e.g. `meta = key`).
 *
 * WHY
 * - This shape crashes at runtime when later code treats `meta` as a map/struct
 *   (`meta.name`, `meta.online_at`, etc.), and it prevents Presence-driven UIs from
 *   initializing (connected mount dies, the disconnected assigns remain visible).
 *
 * HOW
 * - For `Enum.reduce(list, init, fn binder, acc -> ... end)`:
 *   - Find `if` branches that check `entry.metas` and then contain an assignment
 *     `metaVar = binderVar` where `metaVar` is subsequently used as a struct/map.
 *   - Rewrite that assignment to `metaVar = Enum.at(entry.metas, 0)`.
 * - The rewrite is conservative:
 *   - Requires exactly one `entry`-like variable referenced via `.metas` in the `if` condition.
 *   - Requires `metaVar` to be used with field access somewhere later in the same branch.
 *
 * EXAMPLES
 * Haxe:
 *   for (key in keys) {
 *     var entry = users.get(key);
 *     if (entry != null && entry.metas.length > 0) {
 *       var meta = entry.metas[0];
 *       views.push(meta.name);
 *     }
 *   }
 *
 * Elixir (buggy):
 *   meta = key
 *   %{name: meta.name, ...}
 *
 * Elixir (fixed):
 *   meta = Enum.at(entry.metas, 0)
 *   %{name: meta.name, ...}
 */
class ReduceMetasHeadRepairTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall({def: EVar("Enum")}, "reduce", args) if (args != null && args.length == 3):
                    var fnNode = args[2];
                    switch (fnNode.def) {
                        case EFn(clauses) if (clauses != null && clauses.length == 1):
                            var clause = clauses[0];
                            var binderName: Null<String> = switch (clause.args != null && clause.args.length > 0 ? clause.args[0] : null) {
                                case PVar(nm): nm;
                                default: null;
                            };
                            if (binderName == null) return n;
                            var newBody = repairInBody(clause.body, binderName);
                            if (newBody == clause.body) {
                                n;
                            } else {
                                var newFn = makeAST(EFn([{ args: clause.args, guard: clause.guard, body: newBody }]));
                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "reduce", [args[0], args[1], newFn]), n.metadata, n.pos);
                            }
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static function repairInBody(body: ElixirAST, binderName: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenBranch, elseBranch):
                    var entryVar = singleMetasOwnerVar(cond);
                    if (entryVar == null) return n;
                    var repairedThen = repairThenBranch(entryVar, binderName, thenBranch);
                    if (repairedThen == thenBranch) {
                        n;
                    } else {
                        makeASTWithMeta(EIf(cond, repairedThen, elseBranch), n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    static function repairThenBranch(entryVar: String, binderName: String, thenBranch: ElixirAST): ElixirAST {
        var stmts: Array<ElixirAST> = switch (thenBranch.def) {
            case EBlock(ss): ss;
            case EDo(ss2): ss2;
            default: [thenBranch];
        };

        var changed = false;
        var out: Array<ElixirAST> = [];

        for (i in 0...stmts.length) {
            var stmt = stmts[i];
            var metaVar: Null<String> = null;
            var isBinderAliasAssign = false;

            switch (stmt.def) {
                case EBinary(Match, left, rhs):
                    metaVar = switch (left.def) { case EVar(nm): nm; default: null; };
                    isBinderAliasAssign = metaVar != null && (switch (rhs.def) { case EVar(rn) if (rn == binderName): true; default: false; });
                case EMatch(pat, rhs2):
                    metaVar = switch (pat) { case PVar(nm2): nm2; default: null; };
                    isBinderAliasAssign = metaVar != null && (switch (rhs2.def) { case EVar(rn2) if (rn2 == binderName): true; default: false; });
                default:
            }

            if (!isBinderAliasAssign || metaVar == null || metaVar == binderName) {
                out.push(stmt);
                continue;
            }

            if (!usedAsFieldAccess(metaVar, stmts, i + 1)) {
                out.push(stmt);
                continue;
            }

            // Replace `metaVar = binderName` with `metaVar = Enum.at(entryVar.metas, 0)`.
            var metasExpr = makeAST(EField(makeAST(EVar(entryVar)), "metas"));
            var enumAt = makeAST(ERemoteCall(makeAST(EVar("Enum")), "at", [metasExpr, makeAST(EInteger(0))]));
            var repaired = makeASTWithMeta(EBinary(Match, makeAST(EVar(metaVar)), enumAt), stmt.metadata, stmt.pos);
            out.push(repaired);
            changed = true;
        }

        if (!changed) return thenBranch;

        return switch (thenBranch.def) {
            case EBlock(_): makeASTWithMeta(EBlock(out), thenBranch.metadata, thenBranch.pos);
            case EDo(_): makeASTWithMeta(EDo(out), thenBranch.metadata, thenBranch.pos);
            default:
                // If the original then-branch wasn't a block, we can only repair if we still have 1 statement.
                (out.length == 1) ? out[0] : makeASTWithMeta(EBlock(out), thenBranch.metadata, thenBranch.pos);
        };
    }

    static function usedAsFieldAccess(varName: String, stmts: Array<ElixirAST>, startIndex: Int): Bool {
        var used = false;
        for (i in startIndex...stmts.length) {
            if (used) break;
            ElixirASTTransformer.transformNode(stmts[i], function(n: ElixirAST): ElixirAST {
                if (used) return n;
                switch (n.def) {
                    case EField({def: EVar(v)}, _) if (v == varName):
                        used = true;
                        n;
                    case EAccess({def: EVar(v2)}, _):
                        if (v2 == varName) used = true;
                        n;
                    case EFn(_):
                        // Nested closures are their own scope; ignore their internals.
                        n;
                    default:
                        n;
                }
                return n;
            });
        }
        return used;
    }

    static function singleMetasOwnerVar(expr: ElixirAST): Null<String> {
        var owners = new Map<String, Bool>();
        ElixirASTTransformer.transformNode(expr, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EField({def: EVar(v)}, field) if (field == "metas"):
                    owners.set(v, true);
                    n;
                case EAccess({def: EVar(v2)}, {def: EAtom(a)}) if (a == "metas"):
                    owners.set(v2, true);
                    n;
                case EFn(_):
                    n;
                default:
                    n;
            }
            return n;
        });

        var keys = [for (k in owners.keys()) k];
        return keys.length == 1 ? keys[0] : null;
    }
}

#end

