package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * CasePatternUnderscorePromotionTransforms
 *
 * WHAT
 * - Promotes underscored case/with pattern binders (e.g. `_reason`) to their
 *   non-underscored form (e.g. `reason`) when the body references the trimmed
 *   name. This fixes undefined variable errors introduced when upstream passes
 *   (unused variable underscore) mark a binder as `_name` while the body still
 *   references `name`.
 *
 * WHY
 * - Elixir warns when `_var` is used and fails when the trimmed name is
 *   referenced but not bound. Aligning the pattern binder to the body reference
 *   is a safe, shape-based fix that keeps semantics identical while eliminating
 *   undefined variable errors.
 *
 * HOW
 * - For each case/with clause, collect non-underscored variable names used in
 *   the clause body and guard.
 * - Traverse the pattern; when encountering `PVar("_name")` and `name` is used
 *   in the body/guard, rewrite the pattern binder to `PVar("name")`.
 * - No renames occur if the trimmed name is not referenced, preserving existing
 *   underscore hygiene.
 */
class CasePatternUnderscorePromotionTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var outClauses:Array<ECaseClause> = [];
          for (cl in clauses) outClauses.push(promoteClause(cl));
          makeASTWithMeta(ECase(expr, outClauses), n.metadata, n.pos);
        case EWith(clauses2, doBlock, elseBlock):
          var outWith:Array<EWithClause> = [];
          for (wc in clauses2) outWith.push(promoteWithClause(wc));
          makeASTWithMeta(EWith(outWith, doBlock, elseBlock), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function promoteClause(cl:ECaseClause):ECaseClause {
    var used = collectUsedVars(cl.body, cl.guard);
    var newPat = promotePattern(cl.pattern, used);
    return { pattern: newPat, guard: cl.guard, body: cl.body };
  }

  static function promoteWithClause(wc:EWithClause):EWithClause {
    var used = collectUsedVars(wc.expr, null);
    var newPat = promotePattern(wc.pattern, used);
    return { pattern: newPat, expr: wc.expr };
  }

  static function promotePattern(p:EPattern, used:Map<String,Bool>):EPattern {
    return switch (p) {
      case PVar(n):
        if (n != null && n.length > 1 && n.charAt(0) == '_') {
          var trimmed = n.substr(1);
          if (used.exists(trimmed)) PVar(trimmed) else p;
        } else p;
      case PTuple(es): PTuple([for (e in es) promotePattern(e, used)]);
      case PList(es): PList([for (e in es) promotePattern(e, used)]);
      case PCons(h,t): PCons(promotePattern(h, used), promotePattern(t, used));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: promotePattern(kv.value, used) }]);
      case PStruct(m,fs): PStruct(m, [for (f in fs) { key: f.key, value: promotePattern(f.value, used) }]);
      case PPin(inner): PPin(promotePattern(inner, used));
      default: p;
    }
  }

  static function collectUsedVars(body:ElixirAST, guard:Null<ElixirAST>):Map<String,Bool> {
    var s = new Map<String,Bool>();
    // Ingest builder metadata if present
    try {
      var meta:Dynamic = body != null ? body.metadata : null;
      if (meta != null && untyped meta.usedLocalsFromTyped != null) {
        var arr:Array<String> = untyped meta.usedLocalsFromTyped;
        for (n in arr) if (n != null && n.length > 0) s.set(n, true);
      }
    } catch (e:Dynamic) {}
    function markTextInterps(str:String):Void {
      if (str == null) return;
      var re = new EReg("\\#\\{([^}]*)\\}", "g");
      var pos = 0;
      while (re.matchSub(str, pos)) {
        var inner = re.matched(1);
        var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
        var tpos = 0;
        while (tok.matchSub(inner, tpos)) {
          var id = tok.matched(0);
          if (id != null && id.length > 0 && id.charAt(0) != '_') s.set(id, true);
          tpos = tok.matchedPos().pos + tok.matchedPos().len;
        }
        pos = re.matchedPos().pos + re.matchedPos().len;
      }
    }
    function collect(n:ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): if (v != null && v.length > 0 && v.charAt(0) != '_') s.set(v, true);
        case EString(sv): markTextInterps(sv);
        case ERaw(code): markTextInterps(code);
        case EBinary(_, l, r): collect(l); collect(r);
        case EMatch(_, rhs): collect(rhs);
        case EBlock(ss): for (x in ss) collect(x);
        case EDo(ss2): for (x in ss2) collect(x);
        case EIf(c,t,e): collect(c); collect(t); if (e != null) collect(e);
        case ECase(expr, cls): collect(expr); for (c in cls) { if (c.guard != null) collect(c.guard); collect(c.body); }
        case EWith(wcs, doB, elseB): for (w in wcs) { collect(w.expr); } if (doB != null) collect(doB); if (elseB != null) collect(elseB);
        case ECall(t,_,as): if (t != null) collect(t); if (as != null) for (a in as) collect(a);
        case ERemoteCall(t2,_,as2): collect(t2); if (as2 != null) for (a2 in as2) collect(a2);
        case EField(obj,_): collect(obj);
        case EAccess(obj2,key): collect(obj2); collect(key);
        default:
      }
    }
    collect(body);
    if (guard != null) {
      // Include guard metadata and interpolation scan
      try {
        var gmeta:Dynamic = guard.metadata;
        if (gmeta != null && untyped gmeta.usedLocalsFromTyped != null) {
          var garr:Array<String> = untyped gmeta.usedLocalsFromTyped;
          for (n in garr) if (n != null && n.length > 0) s.set(n, true);
        }
      } catch (e:Dynamic) {}
      collect(guard);
    }
    return s;
  }
}

#end
