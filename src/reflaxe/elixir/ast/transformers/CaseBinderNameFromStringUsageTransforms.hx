package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseBinderNameFromStringUsageTransforms
 *
 * WHAT
 * - For case clauses with a single payload binder `{:tag, binder}` whose name is generic
 *   ("value" or begins with an underscore), attempt to rename the binder based on identifiers
 *   referenced inside string interpolations in the clause body (e.g., #{todo.title}).
 *
 * WHY
 * - In some flows, meaningful usage survives only inside interpolated strings by the time late
 *   passes run. Earlier collectors may miss these, leaving generic binders (value/_value) and
 *   undefined body variables (todo/id/message). Renaming the binder to the clearly intended name
 *   restores consistency without app-specific heuristics.
 *
 * HOW
 * - For each ECase clause:
 *   1) If pattern matches {:atom, PVar(binder)} and binder is "value" or starts with '_',
 *      scan clause body strings for interpolation blocks and collect identifier tokens.
 *   2) Select a preferred candidate from [todo, id, message, params, reason] when present.
 *   3) If found, rewrite the payload binder to that name and update body EVar references.
 */
class CaseBinderNameFromStringUsageTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out = [];
          for (cl in clauses) {
            var binder = extractPayloadBinder(cl.pattern);
            if (binder != null && isGeneric(binder)) {
              var names = collectStringInterpolationIds(cl.body);
              var pick = prefer(names);
              if (pick != null && pick != binder) {
                var newPat = rewritePayloadBinder(cl.pattern, pick);
                if (newPat != null) {
                  var newBody = replaceVar(cl.body, binder, pick);
                  out.push({ pattern: newPat, guard: cl.guard, body: newBody });
                  continue;
                }
              }
            }
            out.push(cl);
          }
          makeASTWithMeta(ECase(target, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isGeneric(n:String):Bool {
    if (n == null || n.length == 0) return false;
    return n == "value" || n.charAt(0) == '_';
  }

  static function extractPayloadBinder(p:EPattern):Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    }
  }

  static function rewritePayloadBinder(p:EPattern, newName:String):Null<EPattern> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(_): PTuple([es[0], PVar(newName)]); default: null; }
      default: null;
    }
  }

  static function replaceVar(body: ElixirAST, from:String, to:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x:ElixirAST):ElixirAST {
      return switch (x.def) { case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos); default: x; };
    });
  }

  static function collectStringInterpolationIds(body: ElixirAST): Array<String> {
    var set = new Map<String,Bool>();
    ElixirASTTransformer.transformNode(body, function(x:ElixirAST):ElixirAST {
      switch (x.def) {
        case EString(s) if (s != null && s.indexOf("#{") != -1):
          var block = new EReg("\\#\\{([^}]*)\\}", "g");
          var pos = 0;
          while (block.matchSub(s, pos)) {
            var inner = block.matched(1);
            var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
            var tpos = 0;
            while (tok.matchSub(inner, tpos)) {
              var id = tok.matched(0);
              if (id != null && id.length > 0) set.set(id.toLowerCase(), true);
              tpos = tok.matchedPos().pos + tok.matchedPos().len;
            }
            pos = block.matchedPos().pos + block.matchedPos().len;
          }
        default:
      }
      return x;
    });
    return [for (k in set.keys()) k];
  }

  static function prefer(names:Array<String>): Null<String> {
    if (names == null || names.length == 0) return null;
    var order = ["todo", "id", "message", "params", "reason"];
    for (p in order) for (n in names) if (n == p) return n;
    return null;
  }
}

#end

