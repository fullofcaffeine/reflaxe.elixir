package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StdStringBufOverrideTransforms
 *
 * WHAT
 * - Overrides StringBuf with a minimal, valid Elixir implementation backed by a parts list.
 *
 * HOW
 * - Detects module StringBuf and replaces its body with ERaw functions:
 *   defstruct parts: []
 *   add/2, add_sub/4, to_string/1
 */
class StdStringBufOverrideTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name == "StringBuf"):
                    var blk = bodyBlock(n.metadata, n.pos);
                    makeASTWithMeta(EModule(name, attrs, [blk]), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name == "StringBuf"):
                    makeASTWithMeta(EDefmodule(name, bodyBlock(n.metadata, n.pos)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function bodyBlock(meta: Dynamic, pos: haxe.macro.Expr.Position): ElixirAST {
        var raw = makeAST(ERaw(
            "  defstruct parts: []\n" +
            "  def add(struct, s), do: %{struct | parts: struct.parts ++ [s]}\n" +
            "  def add_sub(struct, s, pos, len) do\n" +
            "    substr = if len == nil, do: String.slice(s, pos..-1), else: String.slice(s, pos, len)\n" +
            "    %{struct | parts: struct.parts ++ [substr]}\n" +
            "  end\n" +
            "  def to_string(struct), do: Enum.join(struct.parts, \"\")\n"
        ));
        return makeASTWithMeta(EBlock([raw]), meta, pos);
    }
}

#end

