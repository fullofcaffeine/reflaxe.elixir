package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnTempChainSimplifyTransforms
 *
 * WHAT
 * - Inside single-clause EFn bodies, simplify temp chains of the form:
 *     var = nil; var = expr; var  → expr
 *   Also simplifies when there are other statements in between as long as the last
 *   two references are `var = expr` followed by trailing `var`.
 */
class EFnTempChainSimplifyTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses) if (clauses.length == 1):
                    var cl = clauses[0];
                    var b = cl.body;
                    var nb = switch (b.def) {
                        case EBlock(stmts): makeASTWithMeta(EBlock(simplify(stmts, b.metadata, b.pos)), b.metadata, b.pos);
                        default: b;
                    };
                    makeASTWithMeta(EFn([{ args: cl.args, guard: cl.guard, body: nb }]), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function simplify(stmts:Array<ElixirAST>, meta:Dynamic, pos:Dynamic): Array<ElixirAST> {
        if (stmts.length >= 2) {
            var last = stmts[stmts.length - 1];
            switch (last.def) {
                case EVar(name):
                    // Find last assignment to name
                    var assignIdx = -1;
                    var rhs:Null<ElixirAST> = null;
                    for (i in 0...stmts.length - 1) {
                        var idx = (stmts.length - 2) - i;
                        switch (stmts[idx].def) {
                            case EBinary(Match, left, r):
                                switch (left.def) { case EVar(nm) if (nm == name): assignIdx = idx; rhs = r; }
                            case EMatch(pat, r2):
                                switch (pat) { case PVar(nm2) if (nm2 == name): assignIdx = idx; rhs = r2; }
                            default:
                        }
                        if (assignIdx != -1) break;
                    }
                    if (assignIdx != -1 && rhs != null) {
                        var out:Array<ElixirAST> = [];
                        for (j in 0...assignIdx) out.push(stmts[j]);
                        // Drop any prior 'name = nil' sentinels
                        for (j in assignIdx + 1...stmts.length - 1) switch (stmts[j].def) {
                            case EBinary(Match, left2, ENil):
                                switch (left2.def) { case EVar(nm3) if (nm3 == name): /* drop */; default: out.push(stmts[j]); }
                            case EMatch(PVar(nm4), ENil) if (nm4 == name): /* drop */;
                            default: out.push(stmts[j]);
                        }
                        out.push(rhs);
                        return out;
                    }
                default:
            }
        }
        return stmts;
    }
}

#end

