package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignReturnInjectionTransforms
 *
 * WHAT
 * - Ensures functions that finish with an assignment expression return the
 *   assigned variable by appending it as the final expression. Example:
 *   `cs = case ... end` becomes `cs = case ... end; cs`.
 *
 * WHY
 * - Haxe lowering often ends functions with an assignment; Elixir requires
 *   the final expression to be the value to return. This also marks variables
 *   as used to avoid WAE.
 *
 * HOW
 * - For EDef/EDefp bodies: if body is EBinary(Match,EVar(n),_) wrap as
 *   EBlock([body, EVar(n)]). If body is EBlock and last statement is an
 *   assignment to a variable, append EVar(var) as the last statement.
 */
class AssignReturnInjectionTransforms {
    public static function injectPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newBody = ensureReturn(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    var newBody2 = ensureReturn(body);
                    makeASTWithMeta(EDefp(name, args, guards, newBody2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function ensureReturn(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBinary(Match, left, _):
                switch (left.def) {
                    case EVar(v): makeASTWithMeta(EBlock([body, makeAST(EVar(v))]), body.metadata, body.pos);
                    default: body;
                }
            case EBlock(stmts):
                if (stmts.length > 0) {
                    var last = stmts[stmts.length - 1];
                    switch (last.def) {
                        case EBinary(Match, l2, _):
                            switch (l2.def) {
                                case EVar(v2):
                                    var out = stmts.copy();
                                    out.push(makeAST(EVar(v2)));
                                    makeASTWithMeta(EBlock(out), body.metadata, body.pos);
                                default: body;
                            }
                        default: body;
                    }
                } else body;
            default:
                body;
        }
    }
}

#end

