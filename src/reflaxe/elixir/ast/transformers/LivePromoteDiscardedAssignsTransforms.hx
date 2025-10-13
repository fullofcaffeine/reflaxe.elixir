package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LivePromoteDiscardedAssignsTransforms
 *
 * WHAT
 * - In LiveView modules, promote discarded assignments `_ = expr` to named binders when
 *   the discarded value is immediately used by name later in the same function body:
 *   - `_ = load_todos(...)` → `updated_todos = load_todos(...)` when `updated_todos` used later
 *   - `_ = socket.assigns` → `current_assigns = socket.assigns` when `current_assigns` used later
 *   - `_ = %{...}` → `complete_assigns = %{...}` when `complete_assigns` used later
 *
 * WHY
 * - Late hygiene and normalization may leave values discarded but then referenced by conventional
 *   names in subsequent lines. This shape-based repair binds the expected names without reliance on
 *   app-specific heuristics beyond Live context and exact later usage.
 */
class LivePromoteDiscardedAssignsTransforms {
    static inline var candidates = ["updated_todos", "current_assigns", "complete_assigns"];

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name != null && StringTools.endsWith(name, "Live")):
                    var newBody = [for (b in body) transformIn(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name != null && StringTools.endsWith(name, "Live")):
                    makeASTWithMeta(EDefmodule(name, transformIn(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function transformIn(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case EDef(fname, args, guards, body):
                    switch (body.def) {
                        case EBlock(stmts):
                            var out:Array<ElixirAST> = [];
                            for (i in 0...stmts.length) {
                                var s = stmts[i];
                                switch (s.def) {
                                    case EMatch(PWildcard, rhs):
                                        var name = firstUsedLater(stmts, i + 1, candidates);
                                        if (name != null) out.push(makeASTWithMeta(EMatch(PVar(name), rhs), s.metadata, s.pos)) else out.push(s);
                                    case EBinary(Match, left, rhs2):
                                        var isWild = switch (left.def) { case EVar(v) if (v == "_"): true; case EUnderscore: true; default: false; };
                                        if (isWild) {
                                            var name2 = firstUsedLater(stmts, i + 1, candidates);
                                            if (name2 != null) out.push(makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(name2)), rhs2), s.metadata, s.pos)) else out.push(s);
                                        } else out.push(s);
                                    default:
                                        out.push(s);
                                }
                            }
                            makeASTWithMeta(EDef(fname, args, guards, makeAST(ElixirASTDef.EBlock(out))), e.metadata, e.pos);
                        default:
                            e;
                    }
                default:
                    e;
            }
        });
    }

    static function firstUsedLater(stmts:Array<ElixirAST>, start:Int, names:Array<String>):Null<String> {
        for (nm in names) if (usedLater(stmts, start, nm)) return nm; return null;
    }
    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (stmtUsesVar(stmts[j], name)) return true; return false;
    }
    static function stmtUsesVar(n:ElixirAST, name:String):Bool {
        var found = false;
        function walk(x:ElixirAST):Void {
            if (x == null || found) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s2 in ss2) walk(s2);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt); for (a in args) walk(a);
                case ERemoteCall(tgt2, _, args2): walk(tgt2); for (a2 in args2) walk(a2);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base, fields): walk(base); for (f in fields) walk(f.value);
                case EField(obj, _): walk(obj);
                case EAccess(tgt3, key): walk(tgt3); walk(key);
                case ETuple(elems): for (e in elems) walk(e);
                default:
            }
        }
        walk(n);
        return found;
    }
}

#end

