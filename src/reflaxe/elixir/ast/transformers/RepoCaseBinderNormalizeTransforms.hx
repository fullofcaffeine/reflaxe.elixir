package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * RepoCaseBinderNormalizeTransforms
 *
 * WHAT
 * - Normalizes case-clause binder names in Repo operation success tuples to eliminate
 *   short names with numeric suffixes (e.g., g3, s2) and produce clear, idiomatic names.
 * - Specifically handles `case Repo.delete(struct) do {:ok, binder} -> ... end` by renaming
 *   binder to `deleted` (or `_deleted` when unused in the clause body).
 *
 * WHY
 * - Numeric-suffixed binders are compiler artifacts and violate naming rules. For Repo.delete,
 *   `deleted` communicates intent clearly and avoids warnings when unused.
 *
 * HOW
 * - For each case expression that is directly or indirectly on Repo.delete:
 *   - If a success clause uses a binder matching /^(?:_)?[gs]\d+$/ (e.g., g3, _s2), rename to
 *     `deleted` when used; otherwise `_deleted`.
 * - The transformation is shape- and API-based; no app-specific names.
 */
class RepoCaseBinderNormalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(expr, clauses) if (isRepoDelete(expr)):
                    var newClauses = renameSuccessBinder(clauses);
                    makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var cur = stmts[i];
                        switch (cur.def) {
                            case ECase(expr2, clauses2):
                                var isDeleteCase = false;
                                var matchVar: Null<String> = null;
                                switch (expr2.def) { case EVar(nm): matchVar = nm; default: }
                                if (!isRepoDelete(expr2) && matchVar != null) {
                                    var j = i - 1; var scans = 0;
                                    while (j >= 0 && scans < 3) {
                                        switch (stmts[j].def) {
                                            case EBinary(Match, left, rhs):
                                                switch (left.def) { case EVar(nm) if (nm == matchVar): if (isRepoDelete(rhs)) isDeleteCase = true; default: }
                                            case EMatch(pat, rhs2):
                                                switch (pat) { case PVar(nm2) if (nm2 == matchVar): if (isRepoDelete(rhs2)) isDeleteCase = true; default: }
                                            default:
                                        }
                                        if (isDeleteCase) break;
                                        j--; scans++;
                                    }
                                } else if (isRepoDelete(expr2)) {
                                    isDeleteCase = true;
                                }
                                if (isDeleteCase) {
                                    var renamed = renameSuccessBinder(clauses2);
                                    out.push(makeASTWithMeta(ECase(expr2, renamed), cur.metadata, cur.pos));
                                } else {
                                    out.push(cur);
                                }
                            default:
                                out.push(cur);
                        }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isRepoDelete(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall(mod, func, _args) if (func == 'delete'):
                switch (mod.def) { case EVar(m) if (m != null && (StringTools.endsWith(m, '.Repo') || m == 'Repo')): true; default: false; }
            default: false;
        }
    }

    static inline function isNumericArtifact(name: String): Bool {
        if (name == null) return false;
        var base = (name.length > 0 && name.charAt(0) == '_') ? name.substr(1) : name;
        return ~/^[gs]\d+$/.match(base);
    }

    static function renameSuccessBinder(clauses: Array<ECaseClause>): Array<ECaseClause> {
        var out:Array<ECaseClause> = [];
        for (cl in clauses) {
            var okBinder = isOkBinder(cl.pattern);
            if (okBinder != null && isNumericArtifact(okBinder)) {
                var used = collectUsedLowerVars(cl.body);
                var newName = (used.indexOf(okBinder) != -1) ? 'deleted' : '_deleted';
                var renamedPat = tryRenameSuccessBinder(cl.pattern, newName);
                var renamedBody = renameVarDeep(cl.body, okBinder, newName);
                if (renamedPat != null) {
                    out.push({ pattern: renamedPat, guard: cl.guard, body: renamedBody });
                    continue;
                }
            } else if (okBinder != null) {
                // Align body references of numeric artifacts (gN/sN) to the binder name
                var body2 = alignNumericArtifactsToBinder(cl.body, okBinder);
                out.push({ pattern: cl.pattern, guard: cl.guard, body: body2 });
                continue;
            }
            out.push(cl);
        }
        return out;
    }

    static function alignNumericArtifactsToBinder(body: ElixirAST, binder: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (isNumericArtifact(name)):
                    makeASTWithMeta(EVar(binder), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function renameVarDeep(body: ElixirAST, fromName: String, toName: String): ElixirAST {
        if (fromName == toName || fromName == null || toName == null) return body;
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (name == fromName):
                    makeASTWithMeta(EVar(toName), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function isOkBinder(p: EPattern): Null<String> {
        return switch (p) {
            case PTuple(els) if (els.length == 2):
                switch (els[0]) {
                    case PLiteral({def: EAtom(a)}) if (a == 'ok'):
                        switch (els[1]) { case PVar(nm): nm; default: null; }
                    default: null;
                }
            default: null;
        }
    }

    static function tryRenameSuccessBinder(p: EPattern, newName: String): Null<EPattern> {
        return switch (p) {
            case PTuple(els) if (els.length == 2):
                switch (els[1]) {
                    case PVar(_): PTuple([els[0], PVar(newName)]);
                    default: null;
                }
            default: null;
        }
    }

    static function collectUsedLowerVars(ast: ElixirAST): Array<String> {
        var names = new Map<String, Bool>();
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EVar(name):
                    if (name != null && name.length > 0 && name.charAt(0).toLowerCase() == name.charAt(0)) names.set(name, true);
                case EField(t, _): scan(t);
                case EAccess(t, k): scan(t); scan(k);
                case EBinary(_, l, r): scan(l); scan(r);
                case EBlock(es): for (e in es) scan(e);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                case ERemoteCall(t2,_,as2): scan(t2); if (as2 != null) for (a in as2) scan(a);
                case EList(items): for (i in items) scan(i);
                case ETuple(items): for (i in items) scan(i);
                case EMap(pairs): for (p in pairs) { scan(p.key); scan(p.value); }
                default:
            }
        }
        scan(ast);
        return [for (k in names.keys()) k];
    }
}

#end
