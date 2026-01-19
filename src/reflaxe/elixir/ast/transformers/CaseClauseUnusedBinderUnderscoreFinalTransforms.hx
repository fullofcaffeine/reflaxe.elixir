package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer.OptimizedUsageIndex;

/**
 * CaseClauseUnusedBinderUnderscoreFinalTransforms
 *
 * WHAT
 * - Absolute-final pass: underscore simple pattern binders that are not referenced
 *   in their visible scope.
 * - Applies to:
 *   - `case` / `receive` clauses (clause-local)
 *   - `with` clause patterns (used in later clauses + do/else blocks)
 *   - `try` rescue/catch patterns (clause-local)
 *   - comprehension generator patterns (`for ... <- ...`) (used in later generators + filters + body)
 *
 * WHY
 * - Elixir warns about unused variables in pattern matches. Adding underscore
 *   prefix (_value) silences these warnings for intentionally unused binders.
 *
 * HOW
 * - Build a conservative usage index for the scope where the binder is visible,
 *   then underscore any pattern binders not present in that usage index.
 *
 * NOTE
 * - We do not rewrite pinned patterns (`^var`) because pins are *uses*, not binders.
 *
 * EXAMPLES
 * Before:
 *   case result do
 *     {:ok, value} -> :ok
 *   end
 * After:
 *   case result do
 *     {:ok, _value} -> :ok
 *   end
 */
class CaseClauseUnusedBinderUnderscoreFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrut, clauses):
          var cls = [];
          for (c in clauses) cls.push(rewriteClause(c));
          makeASTWithMeta(ECase(scrut, cls), n.metadata, n.pos);
        case EReceive(clauses, after):
          var cls = [];
          for (c in clauses) cls.push(rewriteClause(c));
          makeASTWithMeta(EReceive(cls, after), n.metadata, n.pos);
        case EWith(clauses, doBlock, elseBlock):
          makeASTWithMeta(EWith(rewriteWithClauses(clauses, doBlock, elseBlock), doBlock, elseBlock), n.metadata, n.pos);
        case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
          var newRescue = [for (c in rescue) rewriteRescueClause(c)];
          var newCatch = [for (c in catchClauses) rewriteCatchClause(c)];
          makeASTWithMeta(ETry(body, newRescue, newCatch, afterBlock, elseBlock), n.metadata, n.pos);
        case EFor(generators, filters, body, into, uniq):
          makeASTWithMeta(EFor(rewriteGenerators(generators, filters, body, into), filters, body, into, uniq), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteClause(c: ECaseClause): ECaseClause {
    var usageNodes:Array<ElixirAST> = [c.body];
    if (c.guard != null) usageNodes.unshift(c.guard);
    var usage = OptimizedVarUseAnalyzer.build(usageNodes);
    var newPat = underscoreUnusedInPattern(c.pattern, usage);
    return { pattern: newPat, guard: c.guard, body: c.body };
  }

  static function rewriteWithClauses(clauses: Array<EWithClause>, doBlock: ElixirAST, elseBlock: Null<ElixirAST>): Array<EWithClause> {
    // Sequential scope: binders from a clause are visible in subsequent clause exprs,
    // in the do-block, and (when present) in the else-block.
    var out:Array<EWithClause> = [];
    for (i in 0...clauses.length) {
      var usageNodes:Array<ElixirAST> = [doBlock];
      if (elseBlock != null) usageNodes.push(elseBlock);
      for (j in (i + 1)...clauses.length) usageNodes.push(clauses[j].expr);
      var usage = OptimizedVarUseAnalyzer.build(usageNodes);
      out.push({ pattern: underscoreUnusedInPattern(clauses[i].pattern, usage), expr: clauses[i].expr });
    }
    return out;
  }

  static function rewriteGenerators(generators: Array<EGenerator>, filters: Array<ElixirAST>, body: ElixirAST, into: Null<ElixirAST>): Array<EGenerator> {
    // Sequential scope: binders from a generator are visible in subsequent generator exprs,
    // filters, body, and into.
    var out:Array<EGenerator> = [];
    for (i in 0...generators.length) {
      var usageNodes:Array<ElixirAST> = [body];
      for (f in filters) usageNodes.push(f);
      if (into != null) usageNodes.push(into);
      for (j in (i + 1)...generators.length) usageNodes.push(generators[j].expr);
      var usage = OptimizedVarUseAnalyzer.build(usageNodes);
      out.push({ pattern: underscoreUnusedInPattern(generators[i].pattern, usage), expr: generators[i].expr });
    }
    return out;
  }

  static function rewriteRescueClause(c: ERescueClause): ERescueClause {
    var usage = OptimizedVarUseAnalyzer.build([c.body]);
    var newPat = underscoreUnusedInPattern(c.pattern, usage);
    var newVarName = c.varName;
    if (newVarName != null && newVarName.length > 0 && newVarName.charAt(0) != '_' && !OptimizedVarUseAnalyzer.usedLater(usage, 0, newVarName)) {
      newVarName = '_' + newVarName;
    }
    return { pattern: newPat, varName: newVarName, body: c.body };
  }

  static function rewriteCatchClause(c: ECatchClause): ECatchClause {
    var usage = OptimizedVarUseAnalyzer.build([c.body]);
    var newPat = underscoreUnusedInPattern(c.pattern, usage);
    return { kind: c.kind, pattern: newPat, body: c.body };
  }

  static function underscoreUnusedInPattern(p: EPattern, usage: OptimizedUsageIndex): EPattern {
    // Two-phase rewrite:
    // 1) Collect binder names (excluding pins) and decide which are unused.
    // 2) Build a stable rename map oldName -> newName and apply it consistently,
    //    preserving equality semantics for repeated binders.
    var binders = collectPatternBinders(p);
    if (binders.length == 0) return p;

    var rename:Map<String, String> = new Map();
    var taken:Map<String, Bool> = new Map();
    for (b in binders) taken.set(b, true);

    for (b in binders) {
      if (b == null || b.length == 0 || b == "_" || b.charAt(0) == "_") continue;
      // Only underscore binders that are not referenced in the visible usage scope.
      if (OptimizedVarUseAnalyzer.usedLater(usage, 0, b)) continue;

      if (!rename.exists(b)) {
        var candidate = "_" + b;
        while (taken.exists(candidate)) candidate = "_" + candidate;
        rename.set(b, candidate);
        taken.set(candidate, true);
      }
    }

    if (!rename.keys().hasNext()) return p;
    return applyPatternRenames(p, rename);
  }

  static function collectPatternBinders(p: EPattern): Array<String> {
    var out:Array<String> = [];
    function walk(px: EPattern): Void {
      switch (px) {
        case PVar(n):
          out.push(n);
        case PAlias(aliasName, inner):
          out.push(aliasName);
          walk(inner);
        case PTuple(es):
          for (e in es) walk(e);
        case PList(es):
          for (e in es) walk(e);
        case PCons(h, t):
          walk(h);
          walk(t);
        case PMap(kvs):
          for (kv in kvs) walk(kv.value);
        case PStruct(_, fs):
          for (f in fs) walk(f.value);
        case PBinary(segs):
          for (s in segs) walk(s.pattern);
        case PPin(_):
          // Pins are *uses*, not binders.
        default:
      }
    }
    walk(p);
    return out;
  }

  static function applyPatternRenames(p: EPattern, rename: Map<String, String>): EPattern {
    return switch (p) {
      case PVar(n):
        rename.exists(n) ? PVar(rename.get(n)) : p;
      case PAlias(aliasName, inner):
        var newAlias = rename.exists(aliasName) ? rename.get(aliasName) : aliasName;
        PAlias(newAlias, applyPatternRenames(inner, rename));
      case PTuple(es):
        PTuple([for (e in es) applyPatternRenames(e, rename)]);
      case PList(es):
        PList([for (e in es) applyPatternRenames(e, rename)]);
      case PCons(h, t):
        PCons(applyPatternRenames(h, rename), applyPatternRenames(t, rename));
      case PMap(kvs):
        PMap([for (kv in kvs) { key: kv.key, value: applyPatternRenames(kv.value, rename) }]);
      case PStruct(nm, fs):
        PStruct(nm, [for (f in fs) { key: f.key, value: applyPatternRenames(f.value, rename) }]);
      case PBinary(segs):
        PBinary([for (s in segs) { pattern: applyPatternRenames(s.pattern, rename), size: s.size, type: s.type, modifiers: s.modifiers }]);
      case PPin(inner):
        // Pins must remain intact.
        PPin(inner);
      default:
        p;
    }
  }
}

#end
