package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer.OptimizedUsageIndex;

/**
 * CaseClauseUnusedBinderUnderscoreFinalTransforms
 *
 * WHAT
 * - Absolute-final pass: in case/cond clauses, underscore simple binders
 *   that are not referenced in the clause body (e.g., {:ok, value} -> ...
 *   where `value` is never read).
 *
 * WHY
 * - Elixir warns about unused variables in pattern matches. Adding underscore
 *   prefix (_value) silences these warnings for intentionally unused binders.
 *
 * HOW
 * - For each case clause, build a single conservative usage index over the
 *   clause guard + body (O(N) once), then underscore any pattern binders that
 *   are not present in that usage index (O(1) per binder).
 *
 * EXAMPLES
 * Before:
 *   case result do
 *     {:ok, value} -> :ok
 *   end
 * After:
 *   case result do
 *     {:ok, _value} -> :ok
 *   end
 */
class CaseClauseUnusedBinderUnderscoreFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrut, clauses):
          var cls = [];
          for (c in clauses) cls.push(rewriteClause(c));
          makeASTWithMeta(ECase(scrut, cls), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteClause(c: ECaseClause): ECaseClause {
    var usageNodes:Array<ElixirAST> = [c.body];
    if (c.guard != null) usageNodes.unshift(c.guard);
    var usage = OptimizedVarUseAnalyzer.build(usageNodes);
    var newPat = underscoreUnusedInPattern(c.pattern, usage);
    return { pattern: newPat, guard: c.guard, body: c.body };
  }

  static function underscoreUnusedInPattern(p: EPattern, usage: OptimizedUsageIndex): EPattern {
    return switch (p) {
      case PVar(n):
        if (n == null || n.length == 0 || n.charAt(0) == "_") p else {
          var isUsed = OptimizedVarUseAnalyzer.usedLater(usage, 0, n);
          isUsed ? p : PVar('_' + n);
        }
      case PAlias(aliasName, inner):
        var newAlias = (aliasName != null && aliasName.length > 0 && aliasName.charAt(0) != '_' && !OptimizedVarUseAnalyzer.usedLater(usage, 0, aliasName))
          ? '_' + aliasName
          : aliasName;
        PAlias(newAlias, underscoreUnusedInPattern(inner, usage));
      case PTuple(es): PTuple([for (e in es) underscoreUnusedInPattern(e, usage)]);
      case PList(es): PList([for (e in es) underscoreUnusedInPattern(e, usage)]);
      case PCons(h,t): PCons(underscoreUnusedInPattern(h, usage), underscoreUnusedInPattern(t, usage));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreUnusedInPattern(kv.value, usage) }]);
      case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, usage) }]);
      case PBinary(segs): PBinary([for (s in segs) { pattern: underscoreUnusedInPattern(s.pattern, usage), size: s.size, type: s.type, modifiers: s.modifiers }]);
      case PPin(inner): PPin(underscoreUnusedInPattern(inner, usage));
      default: p;
    }
  }
}

#end
