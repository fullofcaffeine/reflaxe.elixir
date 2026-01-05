package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer.OptimizedUsageIndex;

/**
 * CasePatternUnusedUnderscoreTransforms
 *
 * WHAT
 * - In case/with patterns, underscore bound variables that are not referenced in
 *   the corresponding clause body. Example: `{:user_online, payload} -> {:noreply, socket}`
 *   becomes `{:user_online, _payload} -> {:noreply, socket}`.
 *
 * WHY
 * - Eliminates compiler warnings about unused pattern variables without changing behavior.
 *   Purely shape-based and target-agnostic.
 *
 * HOW
 * - Builds a suffix usage index for each clause body/expression once, then checks
 *   binder usage in O(1) per pattern variable.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CasePatternUnusedUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(underscoreUnusedInClause(cl));
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        case EWith(clauses2, doBlock, elseBlock):
          var outWith:Array<EWithClause> = [];
          for (wc in clauses2) outWith.push(underscoreUnusedWithClause(wc));
          makeASTWithMeta(EWith(outWith, doBlock, elseBlock), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function underscoreUnusedInClause(cl:ECaseClause):ECaseClause {
    var usage = OptimizedVarUseAnalyzer.build([cl.body]);
    var newPat = underscoreUnusedInPattern(cl.pattern, usage);
    return { pattern: newPat, guard: cl.guard, body: cl.body };
  }

  static function underscoreUnusedWithClause(wc:EWithClause):EWithClause {
    var usage = OptimizedVarUseAnalyzer.build([wc.expr]);
    var newPat = underscoreUnusedInPattern(wc.pattern, usage);
    return { pattern: newPat, expr: wc.expr };
  }

  static function underscoreUnusedInPattern(p:EPattern, usage:OptimizedUsageIndex):EPattern {
    return switch (p) {
      case PVar(n):
        var isUsed = OptimizedVarUseAnalyzer.usedLater(usage, 0, n);
        #if debug_case_pattern_underscore
        #end
        if (n != null && n.length > 0 && n.charAt(0) != '_' && !isUsed) PVar('_' + n) else p;
      case PTuple(es): PTuple([for (e in es) underscoreUnusedInPattern(e, usage)]);
      case PList(es): PList([for (e in es) underscoreUnusedInPattern(e, usage)]);
      case PCons(h,t): PCons(underscoreUnusedInPattern(h, usage), underscoreUnusedInPattern(t, usage));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreUnusedInPattern(kv.value, usage) }]);
      case PStruct(m,fs): PStruct(m, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, usage) }]);
      case PPin(inner): PPin(underscoreUnusedInPattern(inner, usage));
      default: p;
    }
  }
}

#end
