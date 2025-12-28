package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignWhereSelfBinderUnderscoreTransforms
 *
 * WHAT
 * - Rewrites matches of the form `x = Ecto.Query.where(x, ...)` to
 *   `_x = Ecto.Query.where(x, ...)` anywhere in function bodies.
 *
 * WHY
 * - Avoids Elixir warnings about rebinding a variable with the same name
 *   as an outer variable inside match contexts (suggesting ^ pin). Using an
 *   underscored binder makes intent explicit and silences the warning while
 *   preserving expression value.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class AssignWhereSelfBinderUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EMatch(PVar(name), rhs) if (isWhereOnVar(rhs, name)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + name)), rhs), n.metadata, n.pos);
        case EBinary(Match, {def: EVar(name2)}, rhs2) if (isWhereOnVar(rhs2, name2)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + name2)), rhs2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function isWhereOnVar(expr: ElixirAST, name:String): Bool {
    return switch (expr.def) {
      case ERemoteCall({def: EVar("Ecto.Query")}, "where", args) if (args != null && args.length >= 1):
        switch (args[0].def) { case EVar(v) if (v == name): true; default: false; }
      case ECall({def: EVar("Ecto.Query")}, "where", args2) if (args2 != null && args2.length >= 1):
        switch (args2[0].def) { case EVar(v2) if (v2 == name): true; default: false; }
      default: false;
    }
  }
}

#end
