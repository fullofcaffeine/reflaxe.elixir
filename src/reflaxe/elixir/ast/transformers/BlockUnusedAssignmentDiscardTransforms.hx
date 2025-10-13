package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BlockUnusedAssignmentDiscardTransforms
 *
 * WHAT
 * - In function bodies (EDef → EBlock), rewrite `var = expr` to `_ = expr` when `var` is not
 *   referenced later in the same block.
 */
class BlockUnusedAssignmentDiscardTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var nb = rewriteBody(body);
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    switch (s.def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) {
                                case EVar(nm):
                                    if (!usedLater(stmts, i + 1, nm)) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs), s.metadata, s.pos));
                                    } else out.push(s);
                                default: out.push(s);
                            }
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (stmtUsesVar(stmts[j], name)) return true; return false;
    }

    static function stmtUsesVar(n:ElixirAST, name:String):Bool {
        var found = false;
        function walk(x:ElixirAST, inPattern:Bool):Void {
            if (x == null || found) return;
            switch (x.def) {
                case EVar(v) if (!inPattern && v == name): found = true;
                case EBinary(Match, left, rhs): walk(rhs, false);
                case EMatch(pat, rhs2): walk(rhs2, false);
                case EBlock(ss): for (s in ss) walk(s, false);
                case EIf(c,t,e): walk(c, false); walk(t, false); if (e != null) walk(e, false);
                case EBinary(_, l, r): walk(l, false); walk(r, false);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt, false); for (a in args) walk(a, false);
                case ERemoteCall(tgt2, _, args2): walk(tgt2, false); for (a2 in args2) walk(a2, false);
                case ECase(expr, cs): walk(expr, false); for (c in cs) walk(c.body, false);
                default:
            }
        }
        walk(n, false);
        return found;
    }
}

#end

