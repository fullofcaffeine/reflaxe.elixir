package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnusedLocalAssignUnderscoreFinalTransforms
 *
 * WHAT
 * - In function bodies, find simple local assignments like `g = expr` where
 *   the binder name is not referenced later in the surrounding block and
 *   rename the binder to `_g` to silence compiler warnings.
 *
 * WHY
 * - The compiler intentionally materializes temporary binders (e.g., for
 *   side-effecting expressions) but Elixir warns when those binders are
 *   unused. Renaming to an underscored binder communicates intent without
 *   altering semantics.
 *
 * HOW
 * - Walk blocks; for any top-level `EMatch(PVar(name), rhs)` or
 *   `EBinary(Match, EVar(name), rhs)`, check if `name` is used in any
 *   subsequent sibling statement. If not, rename pattern to `_name`.
 * - Conservative: does not attempt cross-block dataflow; only same-level
 *   block siblings are considered.
 */
class UnusedLocalAssignUnderscoreFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        inline function canRename(name:String):Bool {
                            if (name == null) return false;
                            // Never rename core binders
                            if (name == "socket" || name == "params" || name == "assigns") return false;
                            // Rename common compiler temps and raw/updated intermediates
                            return name == "g" || StringTools.startsWith(name, "raw_") || StringTools.startsWith(name, "updated_") || StringTools.startsWith(name, "this");
                        }
                        var renamed = switch (s.def) {
                            case EMatch(PVar(varName), rhs) if (canRename(varName) && !usedLater(stmts, i+1, varName)):
                                makeASTWithMeta(EMatch(PVar('_' + varName), rhs), s.metadata, s.pos);
                            case EBinary(Match, {def: EVar(v)}, rhs) if (canRename(v) && !usedLater(stmts, i+1, v)):
                                makeASTWithMeta(EBinary(Match, {def: EVar('_' + v), metadata: s.metadata, pos: s.pos}, rhs), s.metadata, s.pos);
                            default:
                                s;
                        }
                        out.push(renamed);
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
        var found = false;
        for (j in start...stmts.length) if (!found) {
            walk(stmts[j], name, function(){ found = true; });
        }
        return found;
    }

    static function walk(n: ElixirAST, name:String, hit:()->Void): Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case EVar(v) if (v == name): hit();
            case EBinary(_, l, r): walk(l, name, hit); walk(r, name, hit);
            case EMatch(_, rhs): walk(rhs, name, hit);
            case EBlock(ss): for (s in ss) walk(s, name, hit);
            case EDo(ss2): for (s in ss2) walk(s, name, hit);
            case EIf(c,t,e): walk(c, name, hit); walk(t, name, hit); if (e != null) walk(e, name, hit);
            case ECase(expr, cs):
                walk(expr, name, hit);
                for (c in cs) { if (c.guard != null) walk(c.guard, name, hit); walk(c.body, name, hit); }
            case ECall(t,_,as): if (t != null) walk(t, name, hit); if (as != null) for (a in as) walk(a, name, hit);
            case ERemoteCall(t2,_,as2): walk(t2, name, hit); if (as2 != null) for (a2 in as2) walk(a2, name, hit);
            case EField(obj,_): walk(obj, name, hit);
            case EAccess(obj2,key): walk(obj2, name, hit); walk(key, name, hit);
            default:
        }
    }
}

#end
