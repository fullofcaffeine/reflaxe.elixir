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
    // Collect binders (snake and underscored variants)
    var binders = new Map<String, Bool>();
    collectBinders(cl.pattern, binders);
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
            if (binders.exists(s) || binders.exists('_' + s)) {
              return makeASTWithMeta(EVar(s), x.metadata, x.pos);
            }
          }
          x;
        default:
          x;
      }
    });
    // If binder exists as _snake, rewrite the pattern to plain snake
    var newPattern = cl.pattern;
    if (hasUnderscoredBinder(cl.pattern)) {
      newPattern = rewriteUnderscoredBinders(cl.pattern);
    }
    return { pattern: newPattern, guard: cl.guard, body: rewrittenBody };
  }

  static function collectBinders(p:EPattern, out:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n):
        if (n != null && n.length > 0) {
          var base = StringTools.startsWith(n, "_") ? n.substr(1) : n;
          if (base != null && base.length > 0) out.set(base, true);
        }
      case PTuple(ps) | PList(ps): for (q in ps) collectBinders(q, out);
      case PCons(h,t): collectBinders(h, out); collectBinders(t, out);
      case PMap(kvs): for (kv in kvs) collectBinders(kv.value, out);
      case PStruct(_,fs): for (f in fs) collectBinders(f.value, out);
      case PPin(inner): collectBinders(inner, out);
      default:
    }
  }

  static function hasUnderscoredBinder(p:EPattern):Bool {
    var found = false;
    switch (p) {
      case PVar(n): if (n != null && StringTools.startsWith(n, "_")) return true;
      case PTuple(ps) | PList(ps): for (q in ps) if (hasUnderscoredBinder(q)) return true;
      case PCons(h,t): if (hasUnderscoredBinder(h) || hasUnderscoredBinder(t)) return true;
      case PMap(kvs): for (kv in kvs) if (hasUnderscoredBinder(kv.value)) return true;
      case PStruct(_,fs): for (f in fs) if (hasUnderscoredBinder(f.value)) return true;
      case PPin(inner): return hasUnderscoredBinder(inner);
      default:
    }
    return found;
  }

  static function rewriteUnderscoredBinders(p:EPattern):EPattern {
    return switch (p) {
      case PVar(n) if (n != null && StringTools.startsWith(n, "_")):
        PVar(n.substr(1));
      case PTuple(ps): PTuple([for (q in ps) rewriteUnderscoredBinders(q)]);
      case PList(ps): PList([for (q in ps) rewriteUnderscoredBinders(q)]);
      case PCons(h,t): PCons(rewriteUnderscoredBinders(h), rewriteUnderscoredBinders(t));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: rewriteUnderscoredBinders(kv.value) }]);
      case PStruct(name,fs): PStruct(name, [for (f in fs) { key: f.key, value: rewriteUnderscoredBinders(f.value) }]);
      case PPin(inner): PPin(rewriteUnderscoredBinders(inner));
      default:
        p;
    }
  }
}

#end

