package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StdHaxeRuntimeOverrideTransforms
 *
 * WHAT
 * - Provides minimal, target-native overrides for select Haxe std runtime modules
 *   whose direct compilation leads to binder/usage mismatches (_struct vs struct).
 *   Current overrides: ArrayIterator, PosException.
 *
 * WHY
 * - Ensure warnings-as-errors compliance and eliminate undefined-variable errors
 *   in generated stdlib by emitting idiomatic, binder-consistent Elixir.
 *   This follows the stdlib philosophy of pragmatic native implementations.
 *
 * HOW
 * - Detect EDefmodule/EModule names and replace bodies with ERaw definitions
 *   that use consistent parameter names and minimal logic matching Haxe intent.
 *
 * EXAMPLES
 * Before (generated):
 *   def has_next(_struct) do struct.current < length(struct.array) end
 * After (override):
 *   def has_next(struct), do: struct.current < length(struct.array)
 */
class StdHaxeRuntimeOverrideTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDefmodule(name, _):
                    if (name == "ArrayIterator") arrayIteratorDef(n)
                    else if (name == "PosException") posExceptionDef(n)
                    else if (name == "EReg") eRegDef(n)
                    else n;
                case EModule(name, attrs, _):
                    if (name == "ArrayIterator") {
                        var blk = arrayIteratorBlock(n.metadata, n.pos);
                        makeASTWithMeta(EModule(name, attrs, [blk]), n.metadata, n.pos);
                    } else if (name == "PosException") {
                        var blk2 = posExceptionBlock(n.metadata, n.pos);
                        makeASTWithMeta(EModule(name, attrs, [blk2]), n.metadata, n.pos);
                    } else if (name == "EReg") {
                        var block = eRegBlock(n.metadata, n.pos);
                        makeASTWithMeta(EModule(name, attrs, [block]), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }

    static inline function arrayIteratorDef(orig: ElixirAST): ElixirAST {
        return makeASTWithMeta(EDefmodule("ArrayIterator", arrayIteratorBlock(orig.metadata, orig.pos)), orig.metadata, orig.pos);
    }
    static inline function arrayIteratorBlock(meta: ElixirMetadata, pos: haxe.macro.Expr.Position): ElixirAST {
        var raw = makeAST(ERaw(
            "  def has_next(struct), do: struct.current < length(struct.array)\n" +
            "  def next(struct), do: struct.array[struct.current + 1]\n"
        ));
        return makeASTWithMeta(EBlock([raw]), meta, pos);
    }

    static inline function posExceptionDef(orig: ElixirAST): ElixirAST {
        return makeASTWithMeta(EDefmodule("PosException", posExceptionBlock(orig.metadata, orig.pos)), orig.metadata, orig.pos);
    }
    static inline function posExceptionBlock(meta: ElixirMetadata, pos: haxe.macro.Expr.Position): ElixirAST {
        var raw = makeAST(ERaw(
            "  def new(message, previous, pos) do\n" +
            "    pos_infos =\n" +
            "      if Kernel.is_nil(pos) do\n" +
            "        %{:fileName => \"(unknown)\", :lineNumber => 0, :className => \"(unknown)\", :methodName => \"(unknown)\"}\n" +
            "      else\n" +
            "        pos\n" +
            "      end\n" +
            "    %{:message => message, :previous => previous, :posInfos => pos_infos}\n" +
            "  end\n" +
            "  def to_string(struct), do: \"#{Kernel.to_string(struct.message)} in #{struct.posInfos.className}.#{struct.posInfos.methodName} at #{struct.posInfos.fileName}:#{struct.posInfos.lineNumber}\"\n"
        ));
        return makeASTWithMeta(EBlock([raw]), meta, pos);
    }

    static inline function eRegDef(orig: ElixirAST): ElixirAST {
        return makeASTWithMeta(EDefmodule("EReg", eRegBlock(orig.metadata, orig.pos)), orig.metadata, orig.pos);
    }
    static inline function eRegBlock(meta: ElixirMetadata, pos: haxe.macro.Expr.Position): ElixirAST {
        var raw = makeAST(ERaw(
            "  defstruct regex: nil, global: false\n" +
            "  def new(pattern, options) do\n" +
            "    opts = if Kernel.is_nil(options), do: \"\", else: options\n" +
            "    global = String.contains?(opts, \"g\")\n" +
            "    compile_opts = String.replace(opts, \"g\", \"\")\n" +
            "    %__MODULE__{regex: Regex.compile!(pattern, compile_opts), global: global}\n" +
            "  end\n" +
            "  def match(struct, s), do: Regex.match?(struct.regex, s)\n" +
            "  def replace(struct, s, by), do: Regex.replace(struct.regex, s, by, global: struct.global)\n"
        ));
        return makeASTWithMeta(EBlock([raw]), meta, pos);
    }

    // Reflect and Type overrides were transitional. They now live in std/*.cross.hx
    // and are gated via target-conditional classpath injection.
}

#end
