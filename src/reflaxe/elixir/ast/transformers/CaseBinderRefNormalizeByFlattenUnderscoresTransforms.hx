package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseBinderRefNormalizeByFlattenUnderscoresTransforms
 *
 * WHAT
 * - In case clauses with tuple payload binders (e.g., {:ok, ok_value}), unify
 *   references that differ only by underscores (e.g., okvalue) to the actual
 *   binder name. This repairs accidental underscore-flattening from earlier
 *   renames without relying on app-specific names.
 *
 * WHY
 * - Ensures consistent variable names within a clause body; avoids undefined
 *   variable errors caused by mismatched variants (okvalue vs ok_value). The rule
 *   is shape-based and name-agnostic (purely structural).
 *
 * HOW
 * - For each ECase clause, extract the binder from {:tag, binder}. Compute its
 *   flattened form by removing underscores. In the body, rewrite EVar(v) to the
 *   binder when remove_underscores(v) == remove_underscores(binder) and v != binder.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseBinderRefNormalizeByFlattenUnderscoresTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var cls = [];
          for (cl in clauses) cls.push(normalizeClause(cl));
          makeASTWithMeta(ECase(expr, cls), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function binderOf(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    }
  }

  static inline function flat(s:String): String {
    return s == null ? null : StringTools.replace(s, "_", "");
  }

  static function normalizeClause(cl:{pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST}): {pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST} {
    var binder = binderOf(cl.pattern);
    if (binder == null) return cl;
    var binderFlat = flat(binder);
    var newBody = ElixirASTTransformer.transformNode(cl.body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EVar(v) if (v != binder && flat(v) == binderFlat): makeASTWithMeta(EVar(binder), n.metadata, n.pos);
        default: n;
      }
    });
    return { pattern: cl.pattern, guard: cl.guard, body: newBody };
  }
}

#end

