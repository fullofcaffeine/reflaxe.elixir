package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * DropUnusedLocalAssignmentTransforms
 *
 * WHAT
 * - Removes local assignments whose bound variable is not referenced in any
 *   subsequent statement within the same block or do-end body. Preserves RHS
 *   evaluation to keep side effects.
 *
 * WHY
 * - Prevents compiler from emitting throwaway locals like `data`, `json`,
 *   `changeset`, `g`, etc., which trigger warnings under WAE and add noise.
 *   This pass keeps semantics identical while eliminating unused binders.
 *
 * HOW
 * - For each EBlock/EDo, scan statements in order. If a statement is a match
 *   or `=` bind to a variable `v` and `v` is not used in any later statement
 *   in the same sequence, replace the statement with just its RHS expression.
 *   Applies recursively inside anonymous function bodies as well.
 */
class DropUnusedLocalAssignmentTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        // Only rewrite at function boundaries.
        //
        // WHY
        // - Blocks inside `case`/`if`/`cond` branches can intentionally rebind outer locals.
        // - Doing per-block dead-store elimination would not see uses after the branch expression,
        //   and can delete semantically-required rebinds (breaking correctness).
        //
        // HOW
        // - Apply this pass only to the top-level statement sequences of:
        //   - `def` / `defp` bodies
        //   - `fn` clause bodies (anonymous functions have their own scope)
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          makeASTWithMeta(EDefp(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
        case EFn(clauses):
          var updatedClauses = clauses == null ? clauses : [for (c in clauses) {
            args: c.args,
            guard: c.guard,
            body: rewriteBody(c.body)
          }];
          makeASTWithMeta(EFn(updatedClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteBody(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), body.metadata, body.pos);
      default: body;
    };
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var usage = OptimizedVarUseAnalyzer.build(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var replaced:Null<ElixirAST> = null;
      switch (s.def) {
        case EBinary(Match, left, rhs):
          switch (left.def) {
            case EVar(name):
              if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, name)) {
                // If binder is underscored and its base name is used later, promote binder
                if (name.length > 1 && name.charAt(0) == "_") {
                  var base = stripAllLeadingUnderscores(name);
                  if (base != "_" && OptimizedVarUseAnalyzer.usedLater(usage, i + 1, base)) {
                    // Keep assignment but rename binder to base
                    replaced = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(base), left.metadata, left.pos), rhs), s.metadata, s.pos);
                  } else {
                    replaced = rhs;
                  }
                } else {
                  replaced = rhs;
                }
              }
            default:
          }
        case EMatch(PVar(name), rhs):
          if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, name)) {
            if (name.length > 1 && name.charAt(0) == "_") {
              var baseName = stripAllLeadingUnderscores(name);
              if (baseName != "_" && OptimizedVarUseAnalyzer.usedLater(usage, i + 1, baseName)) {
                // Keep match but rename binder to base
                replaced = makeASTWithMeta(EMatch(PVar(baseName), rhs), s.metadata, s.pos);
              } else {
                replaced = rhs;
              }
            } else {
              replaced = rhs;
            }
          }
        default:
      }
      out.push(replaced != null ? replaced : s);
    }
    return out;
  }

  static function stripAllLeadingUnderscores(name: String): String {
    if (name == null) return name;
    var i = 0;
    while (i < name.length && name.charAt(i) == "_") i++;
    var base = name.substr(i);
    return base.length == 0 ? "_" : base;
  }
}

#end
