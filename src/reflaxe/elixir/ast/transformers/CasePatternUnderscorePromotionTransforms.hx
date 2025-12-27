package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

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
    var used = new Map<String,Bool>();

    inline function mergeFromTyped(node: ElixirAST): Void {
      if (node == null) return;
      var arr = node.metadata.usedLocalsFromTyped;
      if (arr != null) for (n in arr) if (n != null && n.length > 0) used.set(n, true);
    }

    inline function mergeRefs(node: ElixirAST): Void {
      if (node == null) return;
      var refs = VariableUsageCollector.referencedInFunctionScope(node);
      for (k in refs.keys()) used.set(k, true);
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
          if (id != null && id.length > 0 && id.charAt(0) != '_') used.set(id, true);
          tpos = tok.matchedPos().pos + tok.matchedPos().len;
        }
        pos = re.matchedPos().pos + re.matchedPos().len;
      }
    }

    inline function scanInterpolations(node: ElixirAST): Void {
      if (node == null) return;
      ASTUtils.walk(node, function(n: ElixirAST) {
        if (n == null || n.def == null) return;
        switch (n.def) {
          case EString(v): markTextInterps(v);
          case ERaw(code): markTextInterps(code);
          default:
        }
      });
    }

    mergeFromTyped(body);
    mergeRefs(body);
    scanInterpolations(body);

    if (guard != null) {
      mergeFromTyped(guard);
      mergeRefs(guard);
      scanInterpolations(guard);
    }

    return used;
  }
}

#end
