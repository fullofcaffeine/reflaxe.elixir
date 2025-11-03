package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WebDropUnusedLocalAssignmentTransforms
 *
 * WHAT
 * - Scoped wrapper that applies DropUnusedLocalAssignmentTransforms only within
 *   Phoenix Web modules (names containing "Web.") to avoid affecting core app
 *   modules like Application or Repo.
 */
class WebDropUnusedLocalAssignmentTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isWeb(name)):
          var cleaned = DropUnusedLocalAssignmentTransforms.pass(makeAST(EModule(name, attrs, body)));
          cleaned;
        case EDefmodule(name2, doBlock) if (isWeb(name2)):
          var cleaned2 = DropUnusedLocalAssignmentTransforms.pass(makeAST(EDefmodule(name2, doBlock)));
          cleaned2;
        default: n;
      }
    });
  }

  static inline function isWeb(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0;
  }
}

#end

