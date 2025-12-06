package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoChangesetReturnFixTransforms
 *
 * WHAT
 * - For a function named `changeset/2`, append trailing `cs` when the body assigns to `cs` but does not
 *   return it explicitly.
 *
 * WHY
 * - Ecto convention is to return the final changeset; assignment-only without trailing `cs` causes warnings.
 */
class EctoChangesetReturnFixTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "changeset"):
                    var needsCs = detectsCsAssign(body) && !endsWithVar(body, "cs");
                    #if debug_hygiene
                    #end
                    if (needsCs) {
                        var nb = appendVar(body, "cs");
                        #if debug_hygiene
                        #end
                        makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }

    static function detectsCsAssign(b: ElixirAST):Bool {
        var seen = false;
        ElixirASTTransformer.transformNode(b, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
                case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "cs"): seen = true; default: }
                case EMatch(pat, _): switch (pat) { case PVar(nm2) if (nm2 == "cs"): seen = true; default: }
                default:
            }
            return x;
        });
        return seen;
    }

    static function endsWithVar(b: ElixirAST, name:String):Bool {
        return switch (b.def) {
            case EBlock(stmts):
                if (stmts.length == 0) false else switch (stmts[stmts.length - 1].def) { case EVar(n) if (n == name): true; default: false; }
            default: false;
        }
    }

    static function appendVar(b: ElixirAST, name:String): ElixirAST {
        return switch (b.def) {
            case EBlock(stmts): makeASTWithMeta(EBlock(stmts.concat([makeAST(EVar(name))])), b.metadata, b.pos);
            default: b;
        }
    }
}

#end
