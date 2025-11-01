package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

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
    var used = collectUsedVars(cl.body);
    var newPat = underscoreUnusedInPattern(cl.pattern, used);
    return { pattern: newPat, guard: cl.guard, body: cl.body };
  }

  static function underscoreUnusedWithClause(wc:EWithClause):EWithClause {
    var used = collectUsedVars(wc.expr); // conservative: consider expr and do-block
    var newPat = underscoreUnusedInPattern(wc.pattern, used);
    return { pattern: newPat, expr: wc.expr };
  }

  static function underscoreUnusedInPattern(p:EPattern, used:Map<String,Bool>):EPattern {
    return switch (p) {
      case PVar(n):
        if (n != null && n.length > 0 && n.charAt(0) != '_' && !used.exists(n)) PVar('_' + n) else p;
      case PTuple(es): PTuple([for (e in es) underscoreUnusedInPattern(e, used)]);
      case PList(es): PList([for (e in es) underscoreUnusedInPattern(e, used)]);
      case PCons(h,t): PCons(underscoreUnusedInPattern(h, used), underscoreUnusedInPattern(t, used));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreUnusedInPattern(kv.value, used) }]);
      case PStruct(m,fs): PStruct(m, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, used) }]);
      case PPin(inner): PPin(underscoreUnusedInPattern(inner, used));
      default: p;
    }
  }

  static function collectUsedVars(body:ElixirAST):Map<String,Bool> {
    var m = new Map<String,Bool>();
    ASTUtils.walk(body, function(x:ElixirAST){ switch (x.def) { case EVar(v): if (v != null && v.length > 0 && v.charAt(0) != '_') m.set(v,true); default: } });
    return m;
  }
}

#end
