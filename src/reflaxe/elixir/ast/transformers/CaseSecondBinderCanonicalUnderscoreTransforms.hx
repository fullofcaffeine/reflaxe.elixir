package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseSecondBinderCanonicalUnderscoreTransforms
 *
 * WHAT
 * - Canonicalize the second binder in two-tuple case patterns to `_value` when
 *   that binder is not referenced in the clause body or guard. This yields
 *   consistent shapes like `{:tag, _value}` and pairs with downstream alias
 *   passes that introduce `best = _value` as needed.
 *
 * WHY
 * - Snapshot style prefers a stable `_value` name instead of `_task`, `_id`, etc.
 *   when the binder itself is unused and body uses a different alias.
 *
 * HOW
 * - For each ECase clause:
 *   - If pattern is PTuple([first, PVar(name)]) and name is not used in body/guard,
 *     rewrite the second element to PVar("_value").
 *   - Mark the clause body with `lockPayloadBinder=true` metadata to prevent
 *     later renamers from drifting `_value` back to name-based variants.
 */
class CaseSecondBinderCanonicalUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(canonicalize(cl));
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function canonicalize(cl:ECaseClause):ECaseClause {
    var binder:Null<String> = null;
    var newPat:EPattern = switch (cl.pattern) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(n) if (n != null && n.length > 0): binder = n; default: }
        cl.pattern;
      default: cl.pattern;
    };
    if (binder == null) return cl;
    var used = collectUsed(cl.body, cl.guard);
    // Canonicalize regardless of current usage; alias passes will restore body refs
    var pat2 = switch (cl.pattern) {
      case PTuple(es2) if (es2.length == 2): PTuple([es2[0], PVar("_value")]);
      default: cl.pattern;
    };
    // Add lock flag on body to prevent late passes from drifting binder name
    var body2 = cl.body;
    if (body2 != null) {
      if (body2.metadata == null) body2.metadata = {};
      body2.metadata.lockPayloadBinder = true;
      body2.metadata.canonicalPayloadValue = true;
    }
    return { pattern: pat2, guard: cl.guard, body: body2 };
  }

  static function collectUsed(body:ElixirAST, guard:Null<ElixirAST>):Map<String,Bool> {
    var s = new Map<String,Bool>();
    function scan(n:ElixirAST):Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): s.set(v, true);
        case EString(str): markInterpolations(str, s);
        case ERaw(code): markInterpolations(code, s);
        case EBlock(ss): for (x in ss) scan(x);
        case EDo(ss2): for (x in ss2) scan(x);
        case EBinary(_, l, r): scan(l); scan(r);
        case EMatch(_, rhs): scan(rhs);
        case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
        case ECase(e, cls): scan(e); for (c in cls) { if (c.guard != null) scan(c.guard); scan(c.body); }
        default:
      }
    }
    scan(body);
    if (guard != null) scan(guard);
    return s;
  }

  static function markInterpolations(s:String, used:Map<String,Bool>):Void {
    if (s == null) return;
    var re = new EReg("\\#\\{([^}]*)\\}", "g");
    var pos = 0;
    while (re.matchSub(s, pos)) {
      var inner = re.matched(1);
      var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
      var tpos = 0;
      while (tok.matchSub(inner, tpos)) {
        used.set(tok.matched(0), true);
        tpos = tok.matchedPos().pos + tok.matchedPos().len;
      }
      pos = re.matchedPos().pos + re.matchedPos().len;
    }
  }
}

#end
