package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

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
 * - Uses VarUseAnalyzer for comprehensive usage detection across all AST node
 *   types including EMap, EFn, string interpolation, ERaw, etc.
 *
 * HOW
 * - For each case clause, check if pattern-bound variables are used in body
 * - Uses VarUseAnalyzer.stmtUsesVar for accurate detection (handles closures,
 *   maps, interpolations, etc.)
 * - If a variable is NOT used, prefix with underscore
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
    var newPat = underscoreUnusedInPattern(c.pattern, c.body);
    return { pattern: newPat, guard: c.guard, body: c.body };
  }

  static function underscoreUnusedInPattern(p: EPattern, body: ElixirAST): EPattern {
    return switch (p) {
      case PVar(n):
        // Use VarUseAnalyzer for comprehensive usage detection
        var isUsed = VarUseAnalyzer.stmtUsesVar(body, n);
        #if debug_case_clause_binder
        // DISABLED: trace('[CaseClauseUnusedBinder] Checking var "$n" in body, isUsed=$isUsed');
        #end
        isUsed ? p : PVar('_' + n);
      case PTuple(es): PTuple([for (e in es) underscoreUnusedInPattern(e, body)]);
      case PList(es): PList([for (e in es) underscoreUnusedInPattern(e, body)]);
      case PCons(h,t): PCons(underscoreUnusedInPattern(h, body), underscoreUnusedInPattern(t, body));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreUnusedInPattern(kv.value, body) }]);
      case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, body) }]);
      case PPin(inner): PPin(underscoreUnusedInPattern(inner, body));
      default: p;
    }
  }
}

#end
