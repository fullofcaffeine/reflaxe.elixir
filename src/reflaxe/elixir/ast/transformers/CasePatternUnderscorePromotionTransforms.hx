package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

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
    var renames = new Map<String, String>();
    var patternBinders = new Map<String, Bool>();
    collectPatternBinders(cl.pattern, patternBinders);
    var newPat = promotePattern(cl.pattern, used, renames, patternBinders);
    var newGuard = cl.guard == null ? null : renameVars(cl.guard, renames);
    var newBody = renameVars(cl.body, renames);
    return { pattern: newPat, guard: newGuard, body: newBody };
  }

  static function promoteWithClause(wc:EWithClause):EWithClause {
    var used = collectUsedVars(wc.expr, null);
    var renames = new Map<String, String>();
    var patternBinders = new Map<String, Bool>();
    collectPatternBinders(wc.pattern, patternBinders);
    var newPat = promotePattern(wc.pattern, used, renames, patternBinders);
    var newExpr = renameVars(wc.expr, renames);
    return { pattern: newPat, expr: newExpr };
  }

  static function promotePattern(p:EPattern, used:Map<String,Bool>, renames:Map<String,String>, patternBinders:Map<String,Bool>):EPattern {
    return switch (p) {
      case PVar(n):
        if (n != null && n.length > 1 && n.charAt(0) == '_') {
          var trimmed = n.substr(1);
          // Promote when either:
          // - the body references the trimmed name (undefined without promotion), OR
          // - the body references the underscored binder itself (warns; promote to stop warning).
          if ((used.exists(trimmed) || used.exists(n)) && !patternBinders.exists(trimmed)) {
            renames.set(n, trimmed);
            PVar(trimmed);
          } else p;
        } else p;
      case PTuple(es): PTuple([for (e in es) promotePattern(e, used, renames, patternBinders)]);
      case PList(es): PList([for (e in es) promotePattern(e, used, renames, patternBinders)]);
      case PCons(h,t): PCons(promotePattern(h, used, renames, patternBinders), promotePattern(t, used, renames, patternBinders));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: promotePattern(kv.value, used, renames, patternBinders) }]);
      case PStruct(m,fs): PStruct(m, [for (f in fs) { key: f.key, value: promotePattern(f.value, used, renames, patternBinders) }]);
      case PPin(inner): PPin(promotePattern(inner, used, renames, patternBinders));
      default: p;
    }
  }

  static function collectPatternBinders(p:EPattern, out:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n) if (n != null && n.length > 0):
        out.set(n, true);
      case PAlias(nm, inner):
        if (nm != null && nm.length > 0) out.set(nm, true);
        collectPatternBinders(inner, out);
      case PTuple(es) | PList(es):
        for (e in es) collectPatternBinders(e, out);
      case PCons(h, t):
        collectPatternBinders(h, out);
        collectPatternBinders(t, out);
      case PMap(kvs):
        for (kv in kvs) collectPatternBinders(kv.value, out);
      case PStruct(_, fs):
        for (f in fs) collectPatternBinders(f.value, out);
      case PPin(inner):
        collectPatternBinders(inner, out);
      default:
    }
  }

  static function renameVars(node: ElixirAST, renames: Map<String, String>): ElixirAST {
    if (node == null || renames == null) return node;
    if (!renames.keys().hasNext()) return node;
    return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EVar(v) if (v != null && renames.exists(v)):
          makeASTWithMeta(EVar(renames.get(v)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function collectUsedVars(body:ElixirAST, guard:Null<ElixirAST>):Map<String,Bool> {
    var s = new Map<String,Bool>();
    // Ingest builder metadata if present
    var arr = body != null ? body.metadata.usedLocalsFromTyped : null;
    if (arr != null) {
      for (n in arr) if (n != null && n.length > 0) s.set(n, true);
    }
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
    inline function noteName(v:String):Void {
      if (v != null && v.length > 0) s.set(v, true);
    }
    function visitor(n:ElixirAST):Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): noteName(v);
        case EString(sv): markTextInterps(sv);
        case ERaw(code): markTextInterps(code);
        default:
      }
    }
    function walk(n:ElixirAST):Void {
      if (n == null || n.def == null) return;
      visitor(n);
      switch (n.def) {
        case EParen(inner):
          walk(inner);
        case EBlock(stmts) | EDo(stmts):
          for (st in stmts) walk(st);
        case EIf(c, t, e):
          walk(c);
          walk(t);
          if (e != null) walk(e);
        case EBinary(_, l, r):
          walk(l);
          walk(r);
        case EMatch(_, rhs):
          walk(rhs);
        case ECall(tgt, _, args):
          if (tgt != null) walk(tgt);
          for (a in args) walk(a);
        case ERemoteCall(mod, _, args):
          walk(mod);
          for (a in args) walk(a);
        case ECase(expr, clauses):
          walk(expr);
          for (cl in clauses) {
            if (cl.guard != null) walk(cl.guard);
            walk(cl.body);
          }
        case EFn(clauses):
          for (cl in clauses) {
            if (cl.guard != null) walk(cl.guard);
            walk(cl.body);
          }
        default:
          // Fallback: traverse children defensively.
          ElixirASTTransformer.transformAST(n, function(child:ElixirAST):ElixirAST {
            walk(child);
            return child;
          });
      }
    }
    walk(body);
    if (guard != null) walk(guard);
    // Include guard metadata and interpolation scan
    if (guard != null) {
      var garr = guard.metadata.usedLocalsFromTyped;
      if (garr != null) {
        for (n in garr) if (n != null && n.length > 0) s.set(n, true);
      }
    }
    return s;
  }
}

#end
