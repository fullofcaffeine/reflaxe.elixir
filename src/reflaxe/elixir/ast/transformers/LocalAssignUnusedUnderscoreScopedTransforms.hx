package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * LocalAssignUnusedUnderscoreScopedTransforms
 *
 * WHAT
 * - Underscore assignment binders that are not referenced later in the same
 *   block, but only within safe scopes: any def/defp except `mount`.
 *
 * WHY
 * - Silences unused local warnings in controllers, LiveView handle_event
 *   bodies, and render helpers without touching mount/3 where rebinding
 *   `socket` may be intentionally propagated.
 *
 * HOW
 * - For each EDef/EDefp whose name != "mount", rewrite EBlock/EDo children so
 *   that `name = expr` becomes `_name = expr` when `name` is not referenced in
 *   any subsequent statement within the same block.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
  class LocalAssignUnusedUnderscoreScopedTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      // Gate (relaxed for WAE): when inside LiveView modules, only allow on
      // render_* helpers and handle_event/3 to avoid false positives.
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name != "mount"):
          if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
            var isRender = StringTools.startsWith(name, "render_");
            var isHandleEvent = name == "handle_event" && args != null && args.length == 3;
            var isHandleInfo = name == "handle_info" && args != null && args.length == 2;
            if (!isRender && !isHandleEvent && !isHandleInfo) return n;
          }
          var newBody = rewriteWithScope(body, collectPatternVars(args));
          makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
        case EDefp(name, args, guards, body) if (name != "mount"):
          if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
            var isRender = StringTools.startsWith(name, "render_");
            var isHandleEvent = name == "handle_event" && args != null && args.length == 3;
            var isHandleInfo = name == "handle_info" && args != null && args.length == 2;
            if (!isRender && !isHandleEvent && !isHandleInfo) return n;
          }
          var newBody = rewriteWithScope(body, collectPatternVars(args));
          makeASTWithMeta(EDefp(name, args, guards, newBody), n.metadata, n.pos);
        case EMacroCall("test", macroArgs, doBlock):
          // ExUnit "test" blocks are macro do-blocks, not def bodies, but they compile as
          // regular Elixir code and are subject to --warnings-as-errors.
          var newDoBlock = rewriteWithScope(doBlock, new Map<String, Bool>());
          makeASTWithMeta(EMacroCall("test", macroArgs, newDoBlock), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteWithScope(node: ElixirAST, outerScope: Map<String, Bool>): ElixirAST {
    if (node == null || node.def == null) return node;
    var scope = outerScope != null ? outerScope : new Map<String, Bool>();

    return switch (node.def) {
      case EBlock(stmts):
        // First rewrite nested blocks with sequential scope, then apply same-level
        // unused-assign underscore on the block statements.
        var localScope = cloneScope(scope);
        var nested:Array<ElixirAST> = [];
        for (s in stmts) {
          var rewrittenStmt = rewriteWithScope(s, localScope);
          nested.push(rewrittenStmt);
          bindFromStatement(rewrittenStmt, localScope);
        }
        makeASTWithMeta(EBlock(rewrite(nested, scope)), node.metadata, node.pos);

      case EDo(stmts):
        var localScope = cloneScope(scope);
        var nested:Array<ElixirAST> = [];
        for (s in stmts) {
          var rewrittenStmt = rewriteWithScope(s, localScope);
          nested.push(rewrittenStmt);
          bindFromStatement(rewrittenStmt, localScope);
        }
        makeASTWithMeta(EDo(rewrite(nested, scope)), node.metadata, node.pos);

      case ECase(expr, clauses):
        var newExpr = rewriteWithScope(expr, scope);
        var newClauses = rewriteClauses(clauses, scope);
        makeASTWithMeta(ECase(newExpr, newClauses), node.metadata, node.pos);

      case EFn(clauses):
        var outClauses = [];
        for (c in clauses) {
          var fnScope = cloneScope(scope);
          for (a in c.args) collectPatternVarsInto(a, fnScope);
          var newGuard = c.guard != null ? rewriteWithScope(c.guard, fnScope) : null;
          var newBody = rewriteWithScope(c.body, fnScope);
          outClauses.push({args: c.args, guard: newGuard, body: newBody});
        }
        makeASTWithMeta(EFn(outClauses), node.metadata, node.pos);

      default:
        ElixirASTTransformer.transformAST(node, child -> rewriteWithScope(child, scope));
    };
  }

  static function rewrite(stmts:Array<ElixirAST>, outerScope: Map<String, Bool>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var usedLater = new Map<String,Bool>();

    // Track which assignments are *rebindings* (the binder name appeared earlier in the same block).
    // We must be conservative here: rewriting a rebinding `name = ...` to `_name = ...` can corrupt
    // semantics when the variable is used after the block (or when later passes normalize names).
    var rebindAt:Array<Map<String,Bool>> = [];
    var declaredSoFar = new Map<String,Bool>();
    if (outerScope != null) for (k in outerScope.keys()) declaredSoFar.set(k, true);
    for (i in 0...stmts.length) {
      var rebindNames = new Map<String,Bool>();
      var binders = getStatementBinders(stmts[i]);
      for (b in binders) {
        if (declaredSoFar.exists(b)) rebindNames.set(b, true);
        declaredSoFar.set(b, true);
      }
      rebindAt.push(rebindNames);
    }

    // Reverse scan so we see future uses without quadratic lookahead
    var idx = stmts.length - 1;
    while (idx >= 0) {
      var s = stmts[idx];
      var rewritten = s;
      var nextStmt:ElixirAST = (idx + 1 < stmts.length) ? stmts[idx + 1] : null;
      switch (s.def) {
        case EMatch(PVar(b), rhs):
          if (skipAliasToCaseScrutinee(rhs, nextStmt)) {
            idx--;
            continue;
          }
          if (!isRebind(b, rebindAt, idx) && shouldRewriteBinder(b, usedLater)) {
            rewritten = makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
          }
        case EMatch(PTuple(items), rhs):
          // Tuple rebinding (common for while→reduce_while): underscore any binder element
          // that is not referenced later in the same block to avoid WAE warnings like:
          //   "variable \"pos\" is unused (there is a variable with the same name in the context ...)".
          var newItems = [];
          var changed = false;
          for (it in items) {
            var rewrittenIt = underscoreTupleBinderIfUnused(it, usedLater);
            if (rewrittenIt != it) changed = true;
            newItems.push(rewrittenIt);
          }
          if (changed) {
            rewritten = makeASTWithMeta(EMatch(PTuple(newItems), rhs), s.metadata, s.pos);
          }
        case EBinary(Match, {def: EVar(b2)}, rhs2):
          if (skipAliasToCaseScrutinee(rhs2, nextStmt)) {
            idx--;
            continue;
          }
          if (!isRebind(b2, rebindAt, idx) && shouldRewriteBinder(b2, usedLater)) {
            rewritten = makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), rhs2), s.metadata, s.pos);
          } else {
            // also allow aligning Map.get(params, "key") → key when key used later
            switch (rhs2.def) {
              case ERemoteCall({def: EVar("Map")}, "get", ra) if (ra != null && ra.length == 2):
                switch (ra[1].def) {
                  case EString(key) if (usedLater.exists(key) && !usedLater.exists(b2)):
                    rewritten = makeASTWithMeta(EBinary(Match, makeAST(EVar(key)), rhs2), s.metadata, s.pos);
                  default:
                }
              default:
            }
          }
        default:
      }

      collectUsedVars(rewritten, usedLater);
      out.unshift(rewritten);
      idx--;
    }
    return out;
  }

  static function getStatementBinders(stmt: ElixirAST): Array<String> {
    if (stmt == null || stmt.def == null) return [];
    return switch (stmt.def) {
      case EMatch(PVar(name), _): name == null ? [] : [name];
      case EBinary(Match, {def: EVar(name)}, _): name == null ? [] : [name];
      default: [];
    }
  }

  static inline function isRebind(name: String, rebindAt: Array<Map<String,Bool>>, idx: Int): Bool {
    if (name == null || name.length == 0) return false;
    if (rebindAt == null || idx < 0 || idx >= rebindAt.length) return false;
    var m = rebindAt[idx];
    return m != null && m.exists(name);
  }

  static function underscoreTupleBinderIfUnused(p:EPattern, usedLater:Map<String,Bool>):EPattern {
    return switch (p) {
      case PVar(name):
        if (name == null || name.length == 0) return p;
        if (name == "children") return p;
        if (name == "_" || name.charAt(0) == '_') return p;
        if (usedLater.exists(name)) return p;
        PVar('_' + name);
      case PTuple(items): PTuple([for (it in items) underscoreTupleBinderIfUnused(it, usedLater)]);
      case PList(items): PList([for (it in items) underscoreTupleBinderIfUnused(it, usedLater)]);
      case PCons(h, t): PCons(underscoreTupleBinderIfUnused(h, usedLater), underscoreTupleBinderIfUnused(t, usedLater));
      case PMap(fs): PMap([for (f in fs) { key: f.key, value: underscoreTupleBinderIfUnused(f.value, usedLater) }]);
      case PStruct(mod, fs): PStruct(mod, [for (f in fs) { key: f.key, value: underscoreTupleBinderIfUnused(f.value, usedLater) }]);
      case PBinary(segs): PBinary([for (s in segs) { pattern: underscoreTupleBinderIfUnused(s.pattern, usedLater), size: s.size, type: s.type, modifiers: s.modifiers }]);
      case PPin(inner): PPin(underscoreTupleBinderIfUnused(inner, usedLater));
      case PAlias(nm, inner):
        var renamedInner = underscoreTupleBinderIfUnused(inner, usedLater);
        if (nm != null && nm.length > 0 && nm.charAt(0) != '_' && !usedLater.exists(nm)) {
          PAlias('_' + nm, renamedInner);
        } else {
          PAlias(nm, renamedInner);
        }
      default:
        p;
    }
  }

  static inline function shouldRewriteBinder(name:String, usedLater:Map<String,Bool>):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "children") return false;
    if (name.charAt(0) == '_') return false;
    if (usedLater.exists(name)) return false;
    // Elixir warns on any unused local binder regardless of RHS shape. Haxe does not, so
    // we treat unused locals as non-fatal and underscore them to keep generated code WAE-clean.
    return true;
  }

  static function collectUsedVars(node: ElixirAST, out: Map<String,Bool>): Void {
    // IMPORTANT: use exact tracking here. Variant-aware collection (snake/camel/base/underscore)
    // can produce false positives from tokens inside raw strings (e.g., "User not found"),
    // preventing legitimate unused-local underscoring and causing WAE failures.
    OptimizedVarUseAnalyzer.collectReferencedVarsExactInto(node, out);
  }

  static function skipAliasToCaseScrutinee(rhs:ElixirAST, nextStmt:ElixirAST):Bool {
    if (nextStmt == null || nextStmt.def == null) return false;
    var rhsVar:Null<String> = switch (rhs.def) { case EVar(v): v; default: null; };
    if (rhsVar == null) return false;
    return switch (nextStmt.def) {
      case ECase(expr, _):
        switch (expr.def) { case EVar(v2) if (v2 == rhsVar): true; default: false; }
      default: false;
    }
  }

  static function rewriteClauses(cs:Array<ECaseClause>, outerScope: Map<String, Bool>):Array<ECaseClause> {
    var out:Array<ECaseClause> = [];
    for (c in cs) {
      var used = new Map<String,Bool>();
      var clauseScope = cloneScope(outerScope);
      collectPatternVarsInto(c.pattern, clauseScope);
      var newBody = rewriteWithScope(c.body, clauseScope);
      if (newBody != null) collectUsedVars(newBody, used);
      var newGuard = c.guard != null ? rewriteWithScope(c.guard, clauseScope) : null;
      if (newGuard != null) collectUsedVars(newGuard, used);
      var pat = underscoreUnusedInPattern(c.pattern, used);
      out.push({ pattern: pat, guard: newGuard, body: newBody });
    }
    return out;
  }

  static function underscoreUnusedInPattern(p:EPattern, used:Map<String,Bool>):EPattern {
    return switch (p) {
      case PVar(n) if (n != null && n.length > 0 && n.charAt(0) != '_' && !used.exists(n)): PVar('_' + n);
      case PTuple(items):
        PTuple([for (i in items) underscoreUnusedInPattern(i, used)]);
      case PList(items):
        PList([for (i in items) underscoreUnusedInPattern(i, used)]);
      case PCons(h, t):
        PCons(underscoreUnusedInPattern(h, used), underscoreUnusedInPattern(t, used));
      case PMap(fs):
        PMap([for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, used) }]);
      case PStruct(mod, fs):
        PStruct(mod, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, used) }]);
      case PBinary(segs):
        PBinary([for (s in segs) { pattern: underscoreUnusedInPattern(s.pattern, used), size: s.size, type: s.type, modifiers: s.modifiers }]);
      case PPin(inner):
        PPin(underscoreUnusedInPattern(inner, used));
      default:
        p;
    }
  }

  static function cloneScope(m: Map<String, Bool>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (m != null) for (k in m.keys()) out.set(k, true);
    return out;
  }

  static function bindFromStatement(stmt: ElixirAST, scope: Map<String, Bool>): Void {
    if (stmt == null || stmt.def == null) return;
    switch (stmt.def) {
      case EMatch(pat, _):
        collectPatternVarsInto(pat, scope);
      case EBinary(Match, left, _):
        collectLhsVars(left, scope);
      default:
    }
  }

  static function collectLhsVars(lhs: ElixirAST, out: Map<String, Bool>): Void {
    if (lhs == null || lhs.def == null) return;
    switch (lhs.def) {
      case EVar(nm) if (nm != null && nm.length > 0):
        out.set(nm, true);
      case EPin(_):
        // pinned vars do not bind
      case ETuple(items) | EList(items):
        for (i in items) collectLhsVars(i, out);
      case EKeywordList(pairs):
        for (p in pairs) collectLhsVars(p.value, out);
      case EMap(pairs2):
        for (p in pairs2) collectLhsVars(p.value, out);
      case EBinary(Match, l, r):
        collectLhsVars(l, out);
        collectLhsVars(r, out);
      default:
    }
  }

  static function collectPatternVars(args: Array<EPattern>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (args == null) return out;
    for (p in args) collectPatternVarsInto(p, out);
    return out;
  }

  static function collectPatternVarsInto(p: EPattern, out: Map<String, Bool>): Void {
    if (p == null) return;
    switch (p) {
      case PVar(n) if (n != null && n.length > 0):
        out.set(n, true);
      case PAlias(nm, inner):
        if (nm != null && nm.length > 0) out.set(nm, true);
        collectPatternVarsInto(inner, out);
      case PPin(_):
        // pinned vars do not bind
      case PTuple(es) | PList(es):
        for (e in es) collectPatternVarsInto(e, out);
      case PCons(h, t):
        collectPatternVarsInto(h, out);
        collectPatternVarsInto(t, out);
      case PMap(kvs):
        for (kv in kvs) collectPatternVarsInto(kv.value, out);
      case PStruct(_, fs):
        for (f in fs) collectPatternVarsInto(f.value, out);
      case PBinary(segs):
        for (s in segs) collectPatternVarsInto(s.pattern, out);
      default:
    }
  }
}

#end
