package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoLocalRequireInlineTransforms
 *
 * WHAT
 * - Inserts `require Ecto.Query` inline in function bodies immediately before
 *   the first usage of `Ecto.Query.from/2` or `Ecto.Query.where/2` when the
 *   module/function lacks a prior require for Ecto.Query.
 *
 * WHY
 * - Ensures macro availability even when global/module-level require injection
 *   is bypassed by earlier/later passes. Keeps code valid and idiomatic.
 *
 * HOW
 * - For each EDef/EDefp body:
 *   - Scan statements to see if a require exists locally.
 *   - When encountering the first ERemoteCall with module EVar("Ecto.Query") and
 *     func in {"from","where","order_by","preload"} and no prior require found,
 *     insert `require Ecto.Query` just before that statement.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EctoLocalRequireInlineTransforms {
    static inline function isEctoQueryCall(n: ElixirAST): Bool {
        return switch (n.def) {
            case ERemoteCall(mod, func, _):
                var ok = (func == "from" || func == "where" || func == "order_by" || func == "preload" || func == "join" || func == "fragment");
                if (!ok) return false;
                switch (mod.def) {
                    case EVar(m) if (m == "Ecto.Query"): true;
                    default: false;
                }
            default: false;
        };
    }
    static function containsEctoQueryCall(n: ElixirAST): Bool {
        var found = false;
        ElixirASTTransformer.transformNode(n, function(x:ElixirAST):ElixirAST {
            if (found) return x;
            if (isEctoQueryCall(x)) { found = true; return x; }
            return x;
        });
        return found;
    }

    static function processStmts(stmts:Array<ElixirAST>, ctx:ElixirAST):Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        var hasRequire = false;
        for (s in stmts) {
            switch (s.def) {
                case ERequire(mod, _) if (mod == "Ecto.Query"): hasRequire = true; out.push(s);
                default:
                    if (!hasRequire && containsEctoQueryCall(s)) {
                        out.push(makeASTWithMeta(ERequire("Ecto.Query", null), ctx.metadata, ctx.pos));
                        hasRequire = true;
                        out.push(s);
                    } else {
                        out.push(s);
                    }
            }
        }
        return out;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    switch (body.def) {
                        case EBlock(ss): makeASTWithMeta(EDef(name, args, guards, makeAST( EBlock(processStmts(ss, n)) )), n.metadata, n.pos);
                        case EDo(ss2): makeASTWithMeta(EDef(name, args, guards, makeAST( EDo(processStmts(ss2, n)) )), n.metadata, n.pos);
                        default: n;
                    }
                case EDefp(name, args, guards, body):
                    switch (body.def) {
                        case EBlock(ss): makeASTWithMeta(EDefp(name, args, guards, makeAST( EBlock(processStmts(ss, n)) )), n.metadata, n.pos);
                        case EDo(ss2): makeASTWithMeta(EDefp(name, args, guards, makeAST( EDo(processStmts(ss2, n)) )), n.metadata, n.pos);
                        default: n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
