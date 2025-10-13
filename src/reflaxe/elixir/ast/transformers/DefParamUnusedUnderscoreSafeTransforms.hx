package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DefParamUnusedUnderscoreSafeTransforms
 *
 * WHAT
 * - For function definitions, underscore unused parameters safely (only when not referenced in the body).
 *   No renaming is performed when the name is used; when rename occurs, no body rewrite is needed because it is unused.
 */
class DefParamUnusedUnderscoreSafeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newArgs:Array<EPattern> = [];
                    for (a in args) newArgs.push(underscoreIfUnused(a, body));
                    makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreIfUnused(p:EPattern, body:ElixirAST):EPattern {
        return switch (p) {
            case PVar(nm) if (!bodyUsesVar(body, nm) && (nm.length > 0 && nm.charAt(0) != '_')): PVar('_' + nm);
            default: p;
        }
    }

    static function bodyUsesVar(b:ElixirAST, name:String):Bool {
        var found = false;
        ElixirASTTransformer.transformNode(b, function(x:ElixirAST):ElixirAST {
            switch (x.def) { case EVar(v) if (v == name): found = true; default: }
            return x;
        });
        return found;
    }
}

#end

