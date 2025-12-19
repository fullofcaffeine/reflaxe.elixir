package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TrailingTempReturnSimplifyTransforms
 *
 * WHAT
 * - Replace trailing `var` expression at end of a block when preceded by a last assignment
 *   `var = expr` with just `expr`, dropping the temp variable.
 *
 * WHY
 * - Removes temp names like `this1` returned via `var` at end of anonymous functions or blocks.
 */
class TrailingTempReturnSimplifyTransforms {
    static inline function isTemp(name:String):Bool {
        if (name == null) return false;
        if (name.indexOf("this") == 0) return true;
        if (name.indexOf("_this") == 0) return true;
        if (name == "g" || name.indexOf("g") == 0 && name.length > 1) return true;
        return false;
    }
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts): makeASTWithMeta(EBlock(simplify(stmts)), n.metadata, n.pos);
                case EDo(stmts2): makeASTWithMeta(EDo(simplify(stmts2)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        var nb = switch (b.def) {
                            case EBlock(ss): makeASTWithMeta(EBlock(simplify(ss)), b.metadata, b.pos);
                            case EDo(ss2): makeASTWithMeta(EDo(simplify(ss2)), b.metadata, b.pos);
                            default: b;
                        };
                        newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function simplify(stmts:Array<ElixirAST>): Array<ElixirAST> {
        if (stmts.length >= 2) {
            var last = stmts[stmts.length - 1];
            switch (last.def) {
                case EVar(name):
                    if (!isTemp(name)) return stmts;
                    // find last assignment to name not used later
                    for (i in 0...stmts.length - 1) {
                        var idx = (stmts.length - 2) - i;
                        switch (stmts[idx].def) {
                            case EBinary(Match, left, rhs):
                                switch (left.def) { case EVar(nm) if (nm == name):
                                    if (!usedBetween(stmts, idx + 1, stmts.length - 1, name)) {
                                        // replace trailing var with rhs and drop assignment
                                        var out:Array<ElixirAST> = [];
                                        for (j in 0...idx) out.push(stmts[j]);
                                        // keep any statements between idx+1 and last-1
                                        for (j in idx + 1...stmts.length - 1) out.push(stmts[j]);
                                        out.push(rhs);
                                        return out;
                                    }
                                default: }
                            case EMatch(pat, rhs2):
                                switch (pat) { case PVar(nm2) if (nm2 == name):
                                    if (!usedBetween(stmts, idx + 1, stmts.length - 1, name)) {
                                        var out2:Array<ElixirAST> = [];
                                        for (j in 0...idx) out2.push(stmts[j]);
                                        for (j in idx + 1...stmts.length - 1) out2.push(stmts[j]);
                                        out2.push(rhs2);
                                        return out2;
                                    }
                                default: }
                            default:
                        }
                    }
                default:
            }
        }
        return stmts;
    }

    static function usedBetween(stmts:Array<ElixirAST>, start:Int, endExcl:Int, name:String):Bool {
        for (i in start...endExcl) if (stmtUsesVar(stmts[i], name)) return true; return false;
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
                case EDo(ss2): for (s in ss2) walk(s, false);
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
