package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventLocalUnusedUnderscoreTransforms
 *
 * WHAT
 * - In `handle_event/3` functions, underscore local binders like
 *   `name = Map.get(params, ...)` when `name` is not referenced later
 *   in the same function body.
 *
 * WHY
 * - Shape-based cleanup to silence warnings such as
 *   "variable \"sort_by\" is unused" without altering behavior.
 *   The extractor statement remains, but the binder is renamed to `_name`.
 *
 * HOW
 * - Detect EDef/EDefp with name `handle_event` and 3 args.
 * - For EBlock body, scan statements; when a statement is an assignment to
 *   a PVar binder and that binder is not referenced in subsequent statements,
 *   rewrite the binder to `_binder`.
 */
class HandleEventLocalUnusedUnderscoreTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
                    var nb = underscoreUnusedLocals(body);
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2) if (name2 == "handle_event" && args2 != null && args2.length == 3):
                    var nb2 = underscoreUnusedLocals(body2);
                    makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreUnusedLocals(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    var s1 = switch (s.def) {
                        case EMatch(PVar(binder), rhs):
                            if (!usedLater(stmts, i+1, binder)) makeASTWithMeta(EMatch(PVar('_' + binder), rhs), s.metadata, s.pos) else s;
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(binder2) if (!usedLater(stmts, i+1, binder2)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + binder2)), right), s.metadata, s.pos);
                                default: s;
                            }
                        case ECase(expr, clauses):
                            var newClauses = [];
                            for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnusedLocals(cl.body) });
                            makeASTWithMeta(ECase(expr, newClauses), s.metadata, s.pos);
                        default:
                            s;
                    };
                    out.push(s1);
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmts2):
                var out2:Array<ElixirAST> = [];
                for (i in 0...stmts2.length) {
                    var s = stmts2[i];
                    var s1 = switch (s.def) {
                        case EMatch(PVar(binder), rhs):
                            if (!usedLater(stmts2, i+1, binder)) makeASTWithMeta(EMatch(PVar('_' + binder), rhs), s.metadata, s.pos) else s;
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(binder2) if (!usedLater(stmts2, i+1, binder2)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + binder2)), right), s.metadata, s.pos);
                                default: s;
                            }
                        case ECase(expr, clauses):
                            var newClauses = [];
                            for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnusedLocals(cl.body) });
                            makeASTWithMeta(ECase(expr, newClauses), s.metadata, s.pos);
                        default:
                            s;
                    };
                    out2.push(s1);
                }
                makeASTWithMeta(EDo(out2), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
        var found = false;
        for (j in start...stmts.length) if (!found) {
            reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
                switch (x.def) { case EVar(v) if (v == name): found = true; default: }
            });
        }
        return found;
    }
}

#end
