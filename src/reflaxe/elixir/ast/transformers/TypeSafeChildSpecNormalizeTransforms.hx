package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TypeSafeChildSpecNormalizeTransforms
 *
 * WHAT
 * - Normalizes TypeSafeChildSpec.supervisor/3 to use properly bound parameters and remove
 *   unused locals, preventing undefined variable errors and WAE warnings.
 *
 * HOW
 * - For EDef within module TypeSafeChildSpec where name == "supervisor" and arity == 3,
 *   replace the body with a clean ERaw implementation using module/args/opts.
 */
class TypeSafeChildSpecNormalizeTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name == "TypeSafeChildSpec"):
                    var newBody:Array<ElixirAST> = [];
                    for (b in body) newBody.push(normalizeDef(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name == "TypeSafeChildSpec"):
                    var nb = normalizeBlock(doBlock);
                    makeASTWithMeta(EDefmodule(name, nb), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function normalizeBlock(doBlock: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(doBlock, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBlock(stmts): makeASTWithMeta(EBlock([for (s in stmts) normalizeDef(s)]), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function normalizeDef(defAst: ElixirAST): ElixirAST {
        return switch (defAst.def) {
            case EDef(fname, args, guards, body) if (fname == "supervisor" && args.length == 3):
                var raw = (
                    "def supervisor(module, args, opts) do\n" +
                    "  cond do\n" +
                    "    opts != nil ->\n" +
                    "      spec = opts\n" +
                    "      spec = if Keyword.get(spec, :type) == nil, do: Keyword.put(spec, :type, :supervisor), else: spec\n" +
                    "      {:full_spec, spec}\n" +
                    "    args != nil and length(args) > 0 -> {:module_with_args, module, args}\n" +
                    "    true -> {:module_ref, module}\n" +
                    "  end\n" +
                    "end\n"
                );
                makeASTWithMeta(ERaw(raw), defAst.metadata, defAst.pos);
            default:
                defAst;
        }
    }
}

#end
