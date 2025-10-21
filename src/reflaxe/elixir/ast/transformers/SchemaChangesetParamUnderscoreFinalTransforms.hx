package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * SchemaChangesetParamUnderscoreFinalTransforms
 *
 * WHAT
 * - In Ecto schema modules (modules that `use Ecto.Schema`), underscore the
 *   `params` argument in `changeset/2` when it is not used in the function body.
 *
 * WHY
 * - Avoids compiler warnings "variable \"params\" is unused" without altering
 *   runtime behavior. Some paths may delegate changeset building elsewhere.
 *
 * HOW
 * - Detect modules that appear to be Ecto schemas by scanning for `use Ecto.Schema`.
 * - Within such modules, find `def changeset/2` and rename `params` → `_params`
 *   when `params` is not used in the body (closure-aware check).
 */
class SchemaChangesetParamUnderscoreFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var isSchema = moduleUsesEctoSchema(body);
                    if (!isSchema) return n;
                    var newBody = [for (b in body) underscoreInDefs(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name2, doBlock):
                    var stmts = switch (doBlock.def) { case EBlock(ss): ss; default: [doBlock]; };
                    var isSchema2 = moduleUsesEctoSchema(stmts);
                    if (!isSchema2) return n;
                    makeASTWithMeta(EDefmodule(name2, underscoreInDefs(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function moduleUsesEctoSchema(stmts: Array<ElixirAST>): Bool {
        var found = false;
        if (stmts == null) return false;
        for (s in stmts) {
            switch (s.def) {
                case EUse(module, _opts):
                    if (module == "Ecto.Schema") { found = true; }
                default:
            }
            if (found) break;
        }
        return found;
    }

    static function underscoreInDefs(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "changeset"):
                    var newArgs = underscoreParamsIfUnused(args, body);
                    makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2) if (name2 == "changeset"):
                    var newArgs2 = underscoreParamsIfUnused(args2, body2);
                    makeASTWithMeta(EDefp(name2, newArgs2, guards2, body2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreParamsIfUnused(args: Array<EPattern>, body: ElixirAST): Array<EPattern> {
        if (args == null) return args;
        var out: Array<EPattern> = [];
        for (i in 0...args.length) {
            var a = args[i];
            switch (a) {
                case PVar(nm) if (nm == "params" && !VariableUsageCollector.usedInFunctionScope(body, nm)):
                    out.push(PVar("_params"));
                default:
                    out.push(a);
            }
        }
        return out;
    }
}

#end
