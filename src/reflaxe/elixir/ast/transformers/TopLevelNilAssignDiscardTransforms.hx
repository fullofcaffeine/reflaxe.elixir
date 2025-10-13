package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TopLevelNilAssignDiscardTransforms
 *
 * WHAT
 * - Discard top-level assignments to nil in function bodies when the variable
 *   is not used later: `var = nil` → `_ = nil` to eliminate unused-variable warnings.
 */
class TopLevelNilAssignDiscardTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
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
                        case EBinary(Match, left, right) if (isNil(right) && isVar(left)):
                            var name = getVar(left);
                            if (!nameUsedLater(stmts, i+1, name)) out.push(makeASTWithMeta(EMatch(PWildcard, right), s.metadata, s.pos)) else out.push(s);
                        case EMatch(pat, right) if (isNil(right) && isPVar(pat)):
                            var name2 = getPVar(pat);
                            if (!nameUsedLater(stmts, i+1, name2)) out.push(makeASTWithMeta(EMatch(PWildcard, right), s.metadata, s.pos)) else out.push(s);
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static inline function isNil(e: ElixirAST):Bool {
        return switch (e.def) { case ENil: true; default: false; };
    }
    static inline function isVar(e: ElixirAST):Bool {
        return switch (e.def) { case EVar(_): true; default: false; };
    }
    static inline function isPVar(p: EPattern):Bool {
        return switch (p) { case PVar(_): true; default: false; };
    }
    static inline function getVar(e: ElixirAST):String {
        return switch (e.def) { case EVar(n): n; default: null; };
    }
    static inline function getPVar(p: EPattern):String {
        return switch (p) { case PVar(n): n; default: null; };
    }
    static function nameUsedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (statementUsesName(stmts[j], name)) return true;
        return false;
    }
    static function statementUsesName(s:ElixirAST, name:String):Bool {
        var used = false;
        function visit(n:ElixirAST):Void {
            if (used || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(v) if (v == name): used = true;
                case EBlock(ss): for (x in ss) visit(x);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case ECase(expr, cs): visit(expr); for (c in cs) visit(c.body);
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(t,_,as): if (t != null) visit(t); if (as != null) for (a in as) visit(a);
                case ERemoteCall(t2,_,as2): visit(t2); if (as2 != null) for (a2 in as2) visit(a2);
                case ERaw(code): if (code != null && code.indexOf('#{' + name) != -1) used = true;
                case EString(s): if (s != null && s.indexOf('#{' + name) != -1) used = true;
                default:
            }
        }
        visit(s);
        return used;
    }
}

#end

