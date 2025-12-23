package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * LocalAssignDiscardIfUnusedLiveViewFinalTransforms
 *
 * WHAT
 * - In LiveView modules, replace `var = expr` / `var <- expr` with `_ = expr`
 *   when `var` is never referenced later in the same block. Semantics are
 *   preserved; warnings vanish.
 */
class LocalAssignDiscardIfUnusedLiveViewFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      if (n == null || n.metadata == null || Reflect.field(n.metadata, "isLiveView") != true) return n;
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, rewrite(body)), n.metadata, n.pos);
        case EDefp(privateName, privateArgs, privateGuards, privateBody):
          makeASTWithMeta(EDefp(privateName, privateArgs, privateGuards, rewrite(privateBody)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewriteBlock(stmts)), x.metadata, x.pos);
        case EDo(statements): makeASTWithMeta(EDo(rewriteBlock(statements)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function rewriteBlock(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var usage = OptimizedVarUseAnalyzer.buildExact(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var statement = stmts[i];
      var rewrittenStatement = statement;
      switch (statement.def) {
        case EBinary(Match, {def: EVar(binderName)}, rhsExpression):
          if (binderName != null && binderName.length > 0 && binderName.charAt(0) == '_' && !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, binderName)) {
            rewrittenStatement = makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhsExpression), statement.metadata, statement.pos);
          }
        case EMatch(PVar(binderName), rhsExpression):
          if (binderName != null && binderName.length > 0 && binderName.charAt(0) == '_' && !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, binderName)) {
            rewrittenStatement = makeASTWithMeta(EMatch(PVar("_"), rhsExpression), statement.metadata, statement.pos);
          }
        default:
      }
      out.push(rewrittenStatement);
    }
    return out;
  }
}

#end
