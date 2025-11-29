package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseBinderUnderscoreAlignTransforms
 *
 * WHAT
 * - Realigns case-pattern binders that were underscored by hygiene passes but are
 *   still referenced without the underscore in the clause body (e.g., `_value` binder
 *   with `value` usages).
 *
 * WHY
 * - Some late underscore passes prefix apparently-unused binders, but subsequent
 *   transformations may reintroduce references to the original name. This leaves the
 *   clause with `_value` in the pattern and `value` in the body, causing undefined
 *   variable errors at compile time instead of the intended warning cleanup.
 *
 * HOW
 * - For each `case` clause, collect pattern binders and body usages.
 * - If a binder starts with `_` and the body references the unprefixed name while no
 *   other binder already uses that unprefixed name, rename the pattern binder back to
 *   the unprefixed version to keep pattern and body in sync.
 *
 * EXAMPLES
 * Haxe:
 *   switch result {
 *     case Ok(value): conn.json({user: value});
 *   }
 *
 * Elixir (before, after aggressive underscore pass):
 *   case result do
 *     {:ok, _value} -> json(conn, %{user: value})
 *   end  # undefined variable `value`
 *
 * Elixir (after this pass):
 *   case result do
 *     {:ok, value} -> json(conn, %{user: value})
 *   end
 */
class CaseBinderUnderscoreAlignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var newClauses = [];
          for (cl in clauses) {
            var binders = collectPatternBinders(cl.pattern);
            var used = collectUsedVars(cl.body);
            var renames:Array<{from:String, to:String}> = [];

            for (b in binders) {
              if (b != null && b.length > 1 && b.charAt(0) == "_") {
                var bare = b.substr(1);
                if (used.indexOf(bare) != -1 && binders.indexOf(bare) == -1) {
                  renames.push({from: b, to: bare});
                }
              }
            }

            var newPat = renames.length > 0 ? renameBinders(cl.pattern, renames) : cl.pattern;
            newClauses.push({pattern: newPat, guard: cl.guard, body: cl.body});
          }
          makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function collectPatternBinders(p: EPattern): Array<String> {
    var out:Array<String> = [];
    function walk(pt:EPattern) {
      switch (pt) {
        case PVar(n): if (n != null) out.push(n);
        case PTuple(es): for (e in es) walk(e);
        case PList(es): for (e in es) walk(e);
        case PCons(h, t): walk(h); walk(t);
        case PMap(kvs): for (kv in kvs) walk(kv.value);
        case PStruct(_, fs): for (f in fs) walk(f.value);
        case PPin(inner): walk(inner);
        default:
      }
    }
    walk(p);
    return out;
  }

  static function collectUsedVars(body: ElixirAST): Array<String> {
    var names = new Map<String, Bool>();

    // Include builder-provided metadata when present
    try {
      var meta:Dynamic = body.metadata;
      if (meta != null && untyped meta.usedLocalsFromTyped != null) {
        var arr:Array<String> = untyped meta.usedLocalsFromTyped;
        for (n in arr) if (n != null && n.length > 0) names.set(n, true);
      }
    } catch (_:Dynamic) {}

    ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
      switch (n.def) {
        case EVar(v): names.set(v, true);
        default:
      }
      return n;
    });
    return [for (k in names.keys()) k];
  }

  static function renameBinders(p:EPattern, renames:Array<{from:String, to:String}>):EPattern {
    function renameVar(name:String):String {
      for (r in renames) if (r.from == name) return r.to;
      return name;
    }
    return switch (p) {
      case PVar(n): PVar(renameVar(n));
      case PTuple(es): PTuple([for (e in es) renameBinders(e, renames)]);
      case PList(es): PList([for (e in es) renameBinders(e, renames)]);
      case PCons(h,t): PCons(renameBinders(h, renames), renameBinders(t, renames));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: renameBinders(kv.value, renames) }]);
      case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: renameBinders(f.value, renames) }]);
      case PPin(inner): PPin(renameBinders(inner, renames));
      default: p;
    }
  }
}

#end
