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
                    if (name == "ArrayIterator") arrayIteratorDef(n) else if (name == "PosException") posExceptionDef(n) else if (name == "StringTools") stringToolsDef(n) else n;
                case EModule(name, attrs, _):
                    if (name == "ArrayIterator") {
                        var blk = arrayIteratorBlock(n.metadata, n.pos);
                        makeASTWithMeta(EModule(name, attrs, [blk]), n.metadata, n.pos);
                    } else if (name == "PosException") {
                        var blk2 = posExceptionBlock(n.metadata, n.pos);
                        makeASTWithMeta(EModule(name, attrs, [blk2]), n.metadata, n.pos);
                    } else if (name == "StringTools") {
                        var blk3 = stringToolsBlock(n.metadata, n.pos);
                        makeASTWithMeta(EModule(name, attrs, [blk3]), n.metadata, n.pos);
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
            "  def to_string(struct), do: \"#{Kernel.to_string(struct.message)} in #{struct.posInfos.className}.#{struct.posInfos.methodName} at #{struct.posInfos.fileName}:#{struct.posInfos.lineNumber}\"\n"
        ));
        return makeASTWithMeta(EBlock([raw]), meta, pos);
    }

    static inline function stringToolsDef(orig: ElixirAST): ElixirAST {
        return makeASTWithMeta(EDefmodule("StringTools", stringToolsBlock(orig.metadata, orig.pos)), orig.metadata, orig.pos);
    }
    static inline function stringToolsBlock(meta: ElixirMetadata, pos: haxe.macro.Expr.Position): ElixirAST {
        var raw = makeAST(ERaw(
            "  def is_space(s, pos), do: (:binary.at(s, pos) > 8 and :binary.at(s, pos) < 14) or :binary.at(s, pos) == 32\n" +
            "  def ltrim(s), do: String.trim_leading(s)\n" +
            "  def rtrim(s), do: String.trim_trailing(s)\n"
        ));
        return makeASTWithMeta(EBlock([raw]), meta, pos);
    }

    // Reflect and Type overrides were transitional. They now live in std/*.cross.hx
    // and are gated via target-conditional classpath injection.
}

#end
