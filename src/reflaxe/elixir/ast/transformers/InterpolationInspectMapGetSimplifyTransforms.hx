package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InterpolationInspectMapGetSimplifyTransforms
 *
 * WHAT
 * - Rewrites `inspect(Map.get(obj, :field))` to `obj.field`.
 *
 * WHY
 * - In string interpolation contexts, `#{obj.field}` is idiomatic and matches
 *   snapshot expectations, while `#{inspect(Map.get(obj, :field))}` is verbose.
 * - Even outside interpolation, the simplified form is valid when `obj` is a struct
 *   or a map-like value, and improves readability.
 *
 * HOW
 * - Traverses the AST and replaces `ECall(nil, "inspect", [ERemoteCall(Map, "get", [obj, EAtom(field)])])`
 *   with `EField(obj, field)`.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class InterpolationInspectMapGetSimplifyTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECall(null, "inspect", [inner]) :
          switch (inner.def) {
            case ERemoteCall({def: EVar("Map")}, "get", args) if (args != null && args.length == 2):
              switch (args[1].def) {
                case EAtom(field):
                  // obj.field
                  makeASTWithMeta(EField(args[0], field), n.metadata, n.pos);
                default:
                  n;
              }
            default:
              n;
          }
        default:
          n;
      }
    });
  }
}

#end

