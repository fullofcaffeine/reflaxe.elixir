package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

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
 * - Uses VarUseAnalyzer for comprehensive variable usage detection that handles:
 *   - EMap structures (e.g., %{:key => value})
 *   - EFn closures
 *   - String interpolation
 *   - ERaw nodes
 *   - All other AST node types
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
    var newPat = underscoreUnusedInPattern(cl.pattern, cl.body);
    return { pattern: newPat, guard: cl.guard, body: cl.body };
  }

  static function underscoreUnusedWithClause(wc:EWithClause):EWithClause {
    var newPat = underscoreUnusedInPattern(wc.pattern, wc.expr);
    return { pattern: newPat, expr: wc.expr };
  }

  static function underscoreUnusedInPattern(p:EPattern, body:ElixirAST):EPattern {
    return switch (p) {
      case PVar(n):
        // Use VarUseAnalyzer for comprehensive usage detection including
        // EMap, EFn closures, string interpolation, ERaw, etc.
        var isUsed = VarUseAnalyzer.stmtUsesVar(body, n);
        #if debug_case_pattern_underscore
        // DISABLED: trace('[CasePatternUnusedUnderscore] Checking var "$n" in body, isUsed=$isUsed');
        #end
        if (n != null && n.length > 0 && n.charAt(0) != '_' && !isUsed) PVar('_' + n) else p;
      case PTuple(es): PTuple([for (e in es) underscoreUnusedInPattern(e, body)]);
      case PList(es): PList([for (e in es) underscoreUnusedInPattern(e, body)]);
      case PCons(h,t): PCons(underscoreUnusedInPattern(h, body), underscoreUnusedInPattern(t, body));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreUnusedInPattern(kv.value, body) }]);
      case PStruct(m,fs): PStruct(m, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, body) }]);
      case PPin(inner): PPin(underscoreUnusedInPattern(inner, body));
      default: p;
    }
  }
}

#end
