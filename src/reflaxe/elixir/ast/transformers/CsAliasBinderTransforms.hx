package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CsAliasBinderTransforms
 *
 * WHAT
 * - Promotes a temp alias assignment (thisN = thisM) that holds the initial
 *   Ecto.Changeset producer into a canonical `cs = thisM` binding, so that
 *   subsequent `Ecto.Changeset.validate_* (cs, ...)` calls have a declared `cs`.
 *
 * WHY
 * - Some earlier hygiene passes can leave the initial cast/change result only in
 *   compiler-generated temps (thisN/thisM). Later passes expect a canonical `cs`
 *   binder and may reference `cs` in validations before it is declared, leading
 *   to undefined-variable errors.
 *
 * HOW
 * - For EDef/EDefp bodies, when a function references `cs` but `cs` is never
 *   declared, find the first alias assignment of the form `thisX = thisY` and
 *   rewrite it to `cs = thisY`. This is limited to compiler-generated temps and
 *   avoids app-specific heuristics.
 */
class CsAliasBinderTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body):
                    makeASTWithMeta(EDef(name, params, guards, rewrite(body)), n.metadata, n.pos);
                case EDefp(name, params, guards, body):
                    makeASTWithMeta(EDefp(name, params, guards, rewrite(body)), n.metadata, n.pos);
                case EBlock(_):
                    promoteInBlock(n);
                default:
                    n;
            }
        });
    }

    static function rewrite(body: ElixirAST): ElixirAST {
        if (!bodyUsesCs(body) || declares(body, "cs")) return body;
        return promoteInBlock(body);
    }

    static function promoteInBlock(block: ElixirAST): ElixirAST {
        return switch (block.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                var promoted = false;
                for (s in stmts) {
                    if (!promoted && bodyUsesCs(block) && !declares(block, "cs")) {
                        switch (s.def) {
                            case EBinary(Match, lhs, rhs):
                                switch [lhs.def, rhs.def] {
                                    case [EVar(a), EVar(b)] if (isThisTemp(a) && isThisTemp(b)):
                                        out.push(makeAST(EBinary(Match, makeAST(EVar("cs")), makeAST(EVar(b)))));
                                        promoted = true;
                                    default:
                                        out.push(s);
                                }
                            case EMatch(pat, rhs2):
                                switch [pat, rhs2.def] {
                                    case [PVar(a), EVar(b)] if (isThisTemp(a) && isThisTemp(b)):
                                        out.push(makeAST(EBinary(Match, makeAST(EVar("cs")), makeAST(EVar(b)))));
                                        promoted = true;
                                    default:
                                        out.push(s);
                                }
                            default:
                                out.push(s);
                        }
                    } else {
                        out.push(s);
                    }
                }
                makeAST(EBlock(out));
            default:
                block;
        }
    }

    static function isThisTemp(v:String):Bool {
        return StringTools.startsWith(v, "this") && ~/^this\d+$/.match(v);
    }

    static function bodyUsesCs(b: ElixirAST): Bool {
        var found = false;
        function walk(n: ElixirAST):Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(v) if (v == "cs"): found = true;
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(e,cs): walk(e); for (c in cs) walk(c.body);
                case EBinary(_,l,r): walk(l); walk(r);
                case EMatch(_,r): walk(r);
                case EFn(cls): for (cl in cls) walk(cl.body);
                case ECall(t,_,as): if (t!=null) walk(t); if (as!=null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2!=null) for (a in as2) walk(a);
                default:
            }
        }
        walk(b);
        return found;
    }

    static function declares(b: ElixirAST, name:String):Bool {
        var found = false;
        function walk(n: ElixirAST):Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(p,_): if (patternDeclares(p,name)) { found = true; return; }
                case EBinary(Match,l,_): if (lhsDeclares(l,name)) { found = true; return; }
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e!=null) walk(e);
                case ECase(e,cs): walk(e); for (c in cs) walk(c.body);
                default:
            }
        }
        walk(b);
        return found;
    }

    static function patternDeclares(p:EPattern, name:String):Bool {
        return switch (p) {
            case PVar(n) if (n == name): true;
            case PTuple(es): for (e in es) if (patternDeclares(e,name)) return true; false;
            case PList(es): for (e in es) if (patternDeclares(e,name)) return true; false;
            case PCons(h,t): patternDeclares(h,name) || patternDeclares(t,name);
            case PMap(kvs): for (kv in kvs) if (patternDeclares(kv.value,name)) return true; false;
            case PStruct(_,fs): for (f in fs) if (patternDeclares(f.value,name)) return true; false;
            case PPin(inner): patternDeclares(inner,name);
            default: false;
        }
    }

    static function lhsDeclares(lhs: ElixirAST, name:String):Bool {
        return switch (lhs.def) {
            case EVar(v) if (v == name): true;
            case EBinary(Match,l2,r2): lhsDeclares(l2,name) || lhsDeclares(r2,name);
            default: false;
        }
    }
}

#end
