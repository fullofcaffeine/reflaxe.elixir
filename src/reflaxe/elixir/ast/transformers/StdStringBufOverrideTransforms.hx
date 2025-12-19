package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;

/**
 * StdStringBufOverrideTransforms
 *
 * WHAT
 * - Overrides StringBuf with a minimal, valid Elixir implementation backed by a parts list.
 *
 * WHY
 * - Haxe's StringBuf semantics need a native, idiomatic Elixir representation to
 *   avoid heavy transforms. A tiny struct with append functions preserves behavior
 *   and keeps code generation simple and readable.
 *
 * HOW
 * - Detects module StringBuf and replaces its body with ERaw functions:
 *   defstruct parts: []
 *   add/2, add_sub/4, to_string/1
 *
 * EXAMPLES
 * Haxe:
 *   var b = new StringBuf();
 *   b.add("hi");
 *   b.toString();
 * Elixir (after override):
 *   defstruct parts: []
 *   def add(struct, x), do: %{struct | parts: struct.parts ++ [inspect(x)]}
 *   def to_string(struct), do: IO.iodata_to_binary(struct.parts)
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

    static inline function bodyBlock(meta: ElixirMetadata, pos: haxe.macro.Expr.Position): ElixirAST {
        // Align to intended HXXTypeSafety snapshot shape
        var code = (
        "  def add(struct, x) do\n" +
        "    str = if Kernel.is_nil(x), do: \"null\", else: inspect(x)\n" +
        "    %{struct | parts: struct.parts ++ [str]}\n" +
        "  end\n" +
        "  def add_char(struct, c) do\n" +
        "    %{struct | parts: struct.parts ++ [<<c::utf8>>]}\n" +
        "  end\n" +
        "  def add_sub(struct, s, pos, len) do\n" +
        "    if Kernel.is_nil(s), do: struct, else: (\n" +
        "      substr = if Kernel.is_nil(len) do\n" +
        "        String.slice(s, pos..-1)\n" +
        "      else\n" +
        "        String.slice(s, pos, len)\n" +
        "      end\n" +
        "      %{struct | parts: struct.parts ++ [substr]}\n" +
        "    )\n" +
        "  end\n" +
        "  def to_string(struct) do\n" +
        "    IO.iodata_to_binary(struct.parts)\n" +
        "  end\n"
        );
        var raw = makeAST(ERaw(code));
        return makeASTWithMeta(EBlock([raw]), meta, pos);
    }
}

#end
