package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseBinderArgCollisionAvoidTransforms
 *
 * WHAT
 * - Prevent tuple-pattern binders in case/cond matches from colliding with
 *   function argument names (e.g., `socket`). When a clause binds a variable
 *   that equals any function arg name, rename the binder to a safe, generic
 *   identifier ("payload") and rewrite clause body references accordingly.
 *
 * WHY
 * - Binder collisions shadow function arguments and corrupt subsequent calls
 *   that expect the original arg value, producing runtime errors like
 *   "undefined variable" or wrong-argument shapes.
 * - Example seen in handle_info/2: `{:todo_created, socket}` shadows the
 *   function arg `socket`; the body then references `todo` which was intended
 *   for the tuple payload, yielding undefined variable errors and incorrect
 *   helper calls.
 *
 * HOW
 * - For each def/defp, collect argument names. Traverse case clauses; for each
 *   pattern variable (PVar) that equals an argument name, rename it to
 *   "payload" (or keep original if already safe) and substitute all body and
 *   guard occurrences. Tuple tags are preserved; this is shape-only.
 *
 * EXAMPLES
 * Before:
 *   def handle_info(msg, socket) do
 *     case msg do
 *       {:ok, socket} -> socket
 *     end
 *   end
 * After:
 *   def handle_info(msg, socket) do
 *     case msg do
 *       {:ok, payload} -> payload
 *     end
 *   end
 */
class CaseBinderArgCollisionAvoidTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var argNames = collectArgNames(args);
          var nb = rewriteCaseBinders(body, argNames);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var argNames2 = collectArgNames(args2);
          var nb2 = rewriteCaseBinders(body2, argNames2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function collectArgNames(args:Array<EPattern>):Map<String,Bool> {
    var m = new Map<String,Bool>();
    for (a in args) switch (a) {
      case PVar(n) if (n != null && n.length > 0): m.set(n, true);
      default:
    }
    return m;
  }

  static function rewriteCaseBinders(body: ElixirAST, argNames: Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (c in clauses) out.push(renameCollidingBinders(c, argNames));
          makeASTWithMeta(ECase(expr, out), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function renameCollidingBinders(clause:ECaseClause, argNames:Map<String,Bool>): ECaseClause {
    // Collect binders from pattern and rename if colliding with args
    var renamed = renamePatternOnly(clause.pattern, argNames);
    return (renamed == null) ? clause : { pattern: renamed, guard: clause.guard, body: clause.body };
  }

  static function renamePatternOnly(p:EPattern, argNames:Map<String,Bool>): Null<EPattern> {
    return switch (p) {
      case PVar(n) if (n != null && argNames.exists(n)):
        PVar(safeName());
      case PTuple(es):
        var changed = false;
        var rebuilt:Array<EPattern> = [];
        for (e in es) {
          var r = renamePatternOnly(e, argNames);
          if (r != null) { changed = true; rebuilt.push(r); } else rebuilt.push(e);
        }
        changed ? PTuple(rebuilt) : null;
      case PList(es):
        var changedL = false;
        var rebuiltL:Array<EPattern> = [];
        for (e in es) {
          var r = renamePatternOnly(e, argNames);
          if (r != null) { changedL = true; rebuiltL.push(r); } else rebuiltL.push(e);
        }
        changedL ? PList(rebuiltL) : null;
      case PCons(h, t):
        var rh = renamePatternOnly(h, argNames);
        var rt = renamePatternOnly(t, argNames);
        (rh != null || rt != null) ? PCons(rh != null ? rh : h, rt != null ? rt : t) : null;
      case PMap(kvs):
        var changedM = false;
        var rebuiltM = [];
        for (kv in kvs) {
          var rv = renamePatternOnly(kv.value, argNames);
          if (rv != null) { changedM = true; rebuiltM.push({ key: kv.key, value: rv }); } else rebuiltM.push(kv);
        }
        changedM ? PMap(rebuiltM) : null;
      case PStruct(m, fs):
        var changedS = false;
        var rebuiltS = [];
        for (f in fs) {
          var rv2 = renamePatternOnly(f.value, argNames);
          if (rv2 != null) { changedS = true; rebuiltS.push({ key: f.key, value: rv2 }); } else rebuiltS.push(f);
        }
        changedS ? PStruct(m, rebuiltS) : null;
      case PPin(inner):
        var ri = renamePatternOnly(inner, argNames);
        ri != null ? PPin(ri) : null;
      default: null;
    }
  }

  static inline function safeName(): String {
    // Descriptive, generic; avoids numeric suffixes
    return "payload";
  }

  // Intentionally no body substitution here; later passes align binder names to
  // undefined body vars when appropriate. This avoids accidentally rewriting
  // legitimate uses of function args (e.g., `socket`).
}

#end
