package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnCallTargetParenTransforms
 *
 * WHAT
 * - Wrap anonymous function expressions used as function-variable call targets in parentheses:
 *   (fn -> ... end).()
 *
 * WHY
 * - Elixir requires parentheses when invoking an anonymous function literal immediately.
 *   Without them, "fn ... end.()" is invalid.
 *
 * HOW
 * - For ECall(target, "", args) where target is EFn, rewrite to ECall(EParen(target), "", args).

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EFnCallTargetParenTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECall(target, funcName, args) if (funcName == "" && target != null):
          switch (target.def) {
            case EFn(_):
              var wrapped = makeAST(EParen(target));
              makeASTWithMeta(ECall(wrapped, funcName, args), n.metadata, n.pos);
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

