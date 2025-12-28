package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * LocalUnderscoreBinderPromotionWhenUsedTransforms
 *
 * WHAT
 * - Inside blocks/do bodies, when a local binder is introduced with a leading
 *   underscore (e.g., `_tmp`) and that underscored name is read later, promote
 *   the binder and all reads to the base name (e.g., `tmp`) provided no base
 *   binder exists in the same block.
 *
 * WHY
 * - Prevents Elixir warnings about using underscored variables while keeping
 *   the code idiomatic and readable.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
  class LocalUnderscoreBinderPromotionWhenUsedTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(promote(stmts)), n.metadata, n.pos);
        case EDo(doStatements): makeASTWithMeta(EDo(promote(doStatements)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function promote(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var defined:Map<String,Bool> = new Map();
    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);

    // First scan: collect definitions
    for (s in stmts) {
      switch (s.def) {
        case EBinary(Match, left, _):
          switch (left.def) { case EVar(n): defined.set(n, true); default: }
        case EMatch(pat, _):
          switch (pat) { case PVar(patternVarName): defined.set(patternVarName, true); default: }
        default:
      }
    }
    // Determine promotable names: underscored that are referenced later and base not defined
    var toPromote:Map<String,String> = new Map(); // _name -> name
    for (i in 0...stmts.length) {
      switch (stmts[i].def) {
        case EBinary(Match, left, _):
          switch (left.def) {
            case EVar(n) if (n.length > 1 && n.charAt(0) == "_"):
              var base = n.substr(1);
              if (!defined.exists(base) && OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, n)) toPromote.set(n, base);
            default:
          }
        case EMatch(pat, _):
          switch (pat) {
            case PVar(underscoredName) if (underscoredName.length > 1 && underscoredName.charAt(0) == "_"):
              var baseName = underscoredName.substr(1);
              if (!defined.exists(baseName) && OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, underscoredName)) toPromote.set(underscoredName, baseName);
            default:
          }
        default:
      }
    }
    if (toPromote.keys().hasNext() == false) return stmts;
    // Second pass: apply renames inside the block
    var out:Array<ElixirAST> = [];
    for (s in stmts) {
      var rewritten = ElixirASTTransformer.transformNode(s, function(x: ElixirAST): ElixirAST {
        return switch (x.def) {
          case EVar(v) if (toPromote.exists(v)):
            makeASTWithMeta(EVar(toPromote.get(v)), x.metadata, x.pos);
          case EBinary(Match, left, rhs):
            switch (left.def) {
              case EVar(binderName) if (toPromote.exists(binderName)):
                makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(toPromote.get(binderName)), left.metadata, left.pos), rhs), x.metadata, x.pos);
              default: x;
            }
          case EMatch(PVar(binderName), rhsExpr) if (toPromote.exists(binderName)):
            makeASTWithMeta(EMatch(PVar(toPromote.get(binderName)), rhsExpr), x.metadata, x.pos);
          default: x;
        }
      });
      out.push(rewritten);
    }
    return out;
  }
}

#end
