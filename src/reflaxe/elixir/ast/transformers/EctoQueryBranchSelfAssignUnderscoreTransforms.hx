package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoQueryBranchSelfAssignUnderscoreTransforms
 *
 * WHAT
 * - In branches (blocks), rewrites a trailing self-assign of the form
 *   `x = Ecto.Query.where(x, ...)` to `_x = Ecto.Query.where(x, ...)`.
 *
 * WHY
 * - This silences Elixir warnings that the variable `x` is unused inside the
 *   branch when a shadowed binding is introduced unnecessarily.
 * - The assignment expression returns the RHS, so renaming the binder to `_x`
 *   preserves semantics for the branch result while avoiding the warning.
 */
class EctoQueryBranchSelfAssignUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts) if (stmts.length > 0):
          var last = stmts[stmts.length - 1];
          var rewritten = rewriteIfSelfAssign(last);
          if (rewritten != null) {
            var prefix = stmts.copy(); prefix.pop();
            makeASTWithMeta(EBlock(prefix.concat([rewritten])), n.metadata, n.pos);
          } else n;
        case EDo(stmts2) if (stmts2.length > 0):
          var last2 = stmts2[stmts2.length - 1];
          var rewritten2 = rewriteIfSelfAssign(last2);
          if (rewritten2 != null) {
            var prefix2 = stmts2.copy(); prefix2.pop();
            makeASTWithMeta(EDo(prefix2.concat([rewritten2])), n.metadata, n.pos);
          } else n;
        case EIf(cond, thenExpr, elseExpr):
          var newThen = rewriteIfSelfAssign(thenExpr);
          var newElse = (elseExpr != null) ? rewriteIfSelfAssign(elseExpr) : null;
          makeASTWithMeta(EIf(cond, newThen != null ? newThen : thenExpr, newElse != null ? newElse : elseExpr), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteIfSelfAssign(stmt: ElixirAST): Null<ElixirAST> {
    if (stmt == null) return null;
    return switch (stmt.def) {
      case EMatch(PVar(name), rhs) if (isWhereOnVar(rhs, name)):
        makeAST(EBinary(Match, makeAST(EVar('_' + name)), rhs));
      case EBinary(Match, {def: EVar(name2)}, rhs2) if (isWhereOnVar(rhs2, name2)):
        makeAST(EBinary(Match, makeAST(EVar('_' + name2)), rhs2));
      default: null;
    }
  }

  static function isWhereOnVar(expr: ElixirAST, name:String): Bool {
    return switch (expr.def) {
      case ERemoteCall({def: EVar("Ecto.Query")}, "where", args) if (args != null && args.length >= 1):
        switch (args[0].def) { case EVar(v) if (v == name): true; default: false; }
      default: false;
    }
  }
}

#end
