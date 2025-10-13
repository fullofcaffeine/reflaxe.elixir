package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnTempChainSimplifyTransforms
 *
 * WHAT
 * - Inside single-clause anonymous functions (EFn), collapse temp chains:
 *   `var = nil; var = expr; var` → `expr`. Also tolerates intervening statements
 *   as long as the last two references are `var = expr` then trailing `var`.
 *
 * WHY
 * - Lowerings and pattern rewrites often introduce sentinel assigns and trailing
 *   temps in reduce bodies, leading to warnings and noise. Collapsing yields
 *   idiomatic, concise Elixir expressions and helps achieve WAE=0.
 *
 * HOW
 * - For single-clause EFn: if the last expression is `EVar(name)`, scan backwards
 *   to find the most recent assignment to that name (EMatch or EBinary Match) and
 *   replace the tail with the RHS, dropping intervening `name = nil` sentinels.
 *
 * EXAMPLES
 * Before: fn -> this1 = nil; this1 = build(); this1 end
 * After:  fn -> build() end
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

    /**
     * simplify
     *
     * WHAT
     * - Implements the chain collapse within an EFn body.
     *
     * WHY INLINE DROPS
     * - We drop only the shape `name = nil` for the identified `name`. This is a
     *   precise sentinel cleanup that preserves other side effects and ordering.
     */
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
                                switch (left.def) { case EVar(nm) if (nm == name): assignIdx = idx; rhs = r; default: }
                            case EMatch(pat, r2):
                                switch (pat) { case PVar(nm2) if (nm2 == name): assignIdx = idx; rhs = r2; default: }
                            default:
                        }
                        if (assignIdx != -1) break;
                    }
                    if (assignIdx != -1 && rhs != null) {
                        var out:Array<ElixirAST> = [];
                        for (j in 0...assignIdx) out.push(stmts[j]);
                        // Drop any prior 'name = nil' sentinels
                        for (j in assignIdx + 1...stmts.length - 1) {
                            var d = stmts[j].def;
                            var dropped = false;
                            switch (d) {
                                case EBinary(Match, left2, rnil):
                                    var isNil = switch (rnil.def) { case ENil: true; default: false; };
                                    if (isNil) switch (left2.def) { case EVar(nm3) if (nm3 == name): dropped = true; default: }
                                case EMatch(pat2, rnil2):
                                    var isNil2 = switch (rnil2.def) { case ENil: true; default: false; };
                                    if (isNil2) switch (pat2) { case PVar(nm4) if (nm4 == name): dropped = true; default: }
                                default:
                            }
                            if (!dropped) out.push(stmts[j]);
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
