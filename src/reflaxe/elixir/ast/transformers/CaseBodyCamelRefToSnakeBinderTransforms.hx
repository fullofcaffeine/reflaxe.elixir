package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * CaseBodyCamelRefToSnakeBinderTransforms
 *
 * WHAT
 * - In case clauses, rewrite body references to camelCase variables to the
 *   corresponding snake_case pattern binders when present. If the binder was
 *   emitted with a leading underscore (ignored), drop the underscore so the
 *   binder is considered used.
 *
 * WHY
 * - Some desugarings prefer snake_case binders in patterns, while user code
 *   (or previous phases) may reference camelCase names in clause bodies. This
 *   causes unbound variable errors at Elixir compile-time. Aligning the body
 *   to the existing binder (or un-ignoring it) is semantics-preserving and
 *   eliminates invalid code without app-specific heuristics.
 *
 * HOW
 * - For each ECase clause, collect pattern variable names (both plain and
 *   underscore-prefixed). When the body contains a free camelCase variable V
 *   whose snake_case S is bound in the pattern (as S or _S), rewrite body
 *   occurrences of V -> S. If the binder exists as _S, rewrite the pattern
 *   binder to S as well. This is strictly shape-based.
 */
class CaseBodyCamelRefToSnakeBinderTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var newClauses = [for (cl in clauses) rewriteClause(cl)];
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

 static function rewriteClause(cl: ECaseClause): ECaseClause {
    // Collect binders: base snake names, and which ones are underscored in the pattern.
    var binderBases = new Map<String, Bool>();
    var underscoredBases = new Map<String, Bool>();
    collectBinders(cl.pattern, binderBases, underscoredBases);
    // Track which underscored binders we actually used in the body.
    var usedUnderscoredBases = new Map<String, Bool>();
    // Transform body: camelCase -> snakeCase if snake binder exists
    function toSnake(s:String):String {
      return reflaxe.elixir.ast.NameUtils.toSnakeCase(s);
    }
    var rewrittenBody = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v):
          var isCamel = (v != null && v.length > 0 && v.charAt(0) == v.charAt(0).toLowerCase() && v.indexOf("_") == -1 && ~/.*[A-Z].*/.match(v));
          if (isCamel) {
            var s = toSnake(v);
            if (binderBases.exists(s)) {
              // If the pattern binder is underscored, and we rewrite the body to use it,
              // we must un-underscore the binder to make it a real binding.
              if (underscoredBases.exists(s)) usedUnderscoredBases.set(s, true);
              return makeASTWithMeta(EVar(s), x.metadata, x.pos);
            }
          }
          x;
        default:
          x;
      }
    });
    // Only un-underscore pattern binders that are actually used by the rewritten body.
    var newPattern = rewriteUnderscoredBindersUsedInBody(cl.pattern, usedUnderscoredBases);
    return { pattern: newPattern, guard: cl.guard, body: rewrittenBody };
  }

  static function collectBinders(p:EPattern, bases:Map<String,Bool>, underscoredBases:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n):
        if (n != null && n.length > 0) {
          var isUnderscored = StringTools.startsWith(n, "_");
          var base = isUnderscored ? n.substr(1) : n;
          if (base != null && base.length > 0) {
            bases.set(base, true);
            if (isUnderscored) underscoredBases.set(base, true);
          }
        }
      case PTuple(ps) | PList(ps): for (q in ps) collectBinders(q, bases, underscoredBases);
      case PCons(h,t): collectBinders(h, bases, underscoredBases); collectBinders(t, bases, underscoredBases);
      case PMap(kvs): for (kv in kvs) collectBinders(kv.value, bases, underscoredBases);
      case PStruct(_,fs): for (f in fs) collectBinders(f.value, bases, underscoredBases);
      case PPin(inner): collectBinders(inner, bases, underscoredBases);
      default:
    }
  }

  static function rewriteUnderscoredBindersUsedInBody(p:EPattern, usedBases:Map<String,Bool>):EPattern {
    return switch (p) {
      case PVar(n) if (n != null && StringTools.startsWith(n, "_")):
        var base = n.substr(1);
        usedBases.exists(base) ? PVar(base) : p;
      case PTuple(ps): PTuple([for (q in ps) rewriteUnderscoredBindersUsedInBody(q, usedBases)]);
      case PList(ps): PList([for (q in ps) rewriteUnderscoredBindersUsedInBody(q, usedBases)]);
      case PCons(h,t): PCons(rewriteUnderscoredBindersUsedInBody(h, usedBases), rewriteUnderscoredBindersUsedInBody(t, usedBases));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: rewriteUnderscoredBindersUsedInBody(kv.value, usedBases) }]);
      case PStruct(name,fs): PStruct(name, [for (f in fs) { key: f.key, value: rewriteUnderscoredBindersUsedInBody(f.value, usedBases) }]);
      case PPin(inner): PPin(rewriteUnderscoredBindersUsedInBody(inner, usedBases));
      default:
        p;
    }
  }
}

#end
