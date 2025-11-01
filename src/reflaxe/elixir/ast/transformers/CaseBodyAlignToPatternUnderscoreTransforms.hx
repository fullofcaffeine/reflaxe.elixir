package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseBodyAlignToPatternUnderscoreTransforms
 *
 * WHAT
 * - When a case/with clause pattern binds an underscored variable (e.g., `_reason`)
 *   but the clause body references the trimmed name (`reason`), rewrite body
 *   references to the underscored binder to avoid undefined variable errors.
 *
 * WHY
 * - Some hygiene passes underscore pattern binders conservatively. If subsequent
 *   rewrites or source shapes reference the non-underscored name in the body, Elixir
 *   compilation fails with undefined variable. Aligning body references to the existing
 *   pattern binder is a safe, semantics-preserving fix.
 *
 * HOW
 * - For each clause, collect a map of { trimmedName -> underscoredName } from the pattern.
 * - Recursively rewrite EVar occurrences in the body/guard using this map.
 */
class CaseBodyAlignToPatternUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(alignClause(cl));
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        case EWith(clauses2, doBlock, elseBlock):
          var outWith:Array<EWithClause> = [];
          for (wc in clauses2) outWith.push(alignWithClause(wc));
          makeASTWithMeta(EWith(outWith, doBlock, elseBlock), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function alignClause(cl:ECaseClause):ECaseClause {
    var m = binderMap(cl.pattern);
    var newGuard = (cl.guard == null ? null : rewriteVars(cl.guard, m));
    var newBody = rewriteVars(cl.body, m);
    return { pattern: cl.pattern, guard: newGuard, body: newBody };
  }

  static function alignWithClause(wc:EWithClause):EWithClause {
    var m = binderMap(wc.pattern);
    var newExpr = rewriteVars(wc.expr, m);
    return { pattern: wc.pattern, expr: newExpr };
  }

  static function binderMap(p:EPattern):Map<String,String> {
    var m = new Map<String,String>();
    function walkPat(pp:EPattern) {
      switch (pp) {
        case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
          var trimmed = n.substr(1);
          m.set(trimmed, n);
        case PTuple(es): for (e in es) walkPat(e);
        case PList(es): for (e in es) walkPat(e);
        case PCons(h,t): walkPat(h); walkPat(t);
        case PMap(kvs): for (kv in kvs) walkPat(kv.value);
        case PStruct(_, fs): for (f in fs) walkPat(f.value);
        case PPin(inner): walkPat(inner);
        default:
      }
    }
    walkPat(p);
    return m;
  }

  static function rewriteVars(node:ElixirAST, m:Map<String,String>):ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EVar(v) if (v != null && m.exists(v)):
          makeASTWithMeta(EVar(m.get(v)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end

