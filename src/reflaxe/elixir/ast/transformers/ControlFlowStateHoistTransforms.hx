package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControlFlowStateHoistTransforms
 *
 * WHAT
 * - Hoists mutable-style updates inside control-flow statements (`if`/`unless`/`case`/`cond`)
 *   into an outer pattern match so updated values survive Elixir branch scoping.
 *
 * WHY
 * - In Elixir, rebinding inside `if`/`case`/`cond` does not update the outer scope:
 *     x = 0
 *     if cond, do: x = 1
 *     x # => 0 (and a warning)
 *   Haxe code frequently relies on imperative updates in these constructs. When we compile to Elixir,
 *   we must convert those updates into an expression result and bind it outside the control-flow.
 * - This pass fixes both semantics and the associated "variable is unused (same name in context)"
 *   warnings that become fatal under `--warnings-as-errors`.
 *
 * HOW
 * - For each function body (EDef/EDefp) and anonymous function clause (EFn):
 *   - Track which variables are already bound (params + prior assignments in the current block).
 *   - In statement position within a block/do list (all but the last expression):
 *     - If an `if`/`unless`/`case`/`cond` branch body assigns to any already-bound variable(s),
 *       rewrite the statement into a single outer match that binds the updated value(s):
 *         var = if cond do ... end
 *         {a, b} = case expr do ... end
 *     - Ensure each branch/clause returns the updated variable value(s) by appending the return
 *       expression (or tuple) to the end of each branch body.
 *
 * EXAMPLES
 * Haxe:
 *   var min = nums[0];
 *   if (n < min) min = n;
 *
 * Elixir (before):
 *   min = nums[0]
 *   if n < min do
 *     min = n
 *   end
 *
 * Elixir (after):
 *   min = nums[0]
 *   min = if n < min do
 *     min = n
 *     min
 *   else
 *     min
 *   end
 */
class ControlFlowStateHoistTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      if (node == null || node.def == null) return node;

      return switch (node.def) {
	        case EDef(name, args, guards, body):
	          var bound = collectBoundFromArgs(args);
	          var newGuards = guards != null ? rewriteInScope(guards, bound, true) : null;
	          var newBody = rewriteInScope(body, bound, true);
	          makeASTWithMeta(EDef(name, args, newGuards, newBody), node.metadata, node.pos);

	        case EDefp(name, args, guards, body):
	          var bound = collectBoundFromArgs(args);
	          var newGuards = guards != null ? rewriteInScope(guards, bound, true) : null;
	          var newBody = rewriteInScope(body, bound, true);
	          makeASTWithMeta(EDefp(name, args, newGuards, newBody), node.metadata, node.pos);

	        case EFn(clauses):
	          var newClauses = [];
	          for (cl in clauses) {
	            var clauseBound = collectBoundFromArgs(cl.args);
	            var newGuard = cl.guard != null ? rewriteInScope(cl.guard, clauseBound, true) : null;
	            var newClauseBody = rewriteInScope(cl.body, clauseBound, true);
	            newClauses.push({ args: cl.args, guard: newGuard, body: newClauseBody });
	          }
	          makeASTWithMeta(EFn(newClauses), node.metadata, node.pos);

        default:
          node;
      };
    });
  }

  // -------------------- Scope rewrite (carries bound-set) --------------------

  static function rewriteInScope(node: ElixirAST, bound: Map<String, Bool>, valueUsed: Bool): ElixirAST {
    if (node == null || node.def == null) return node;

    return switch (node.def) {
      case EBlock(stmts):
        makeASTWithMeta(EBlock(rewriteSeq(stmts, bound, valueUsed)), node.metadata, node.pos);
      case EDo(stmts):
        makeASTWithMeta(EDo(rewriteSeq(stmts, bound, valueUsed)), node.metadata, node.pos);

      case EIf(cond, thenB, elseB):
        var newCond = rewriteInScope(cond, bound, true);
        var newThen = rewriteInScope(thenB, clone(bound), true);
        var newElse = elseB != null ? rewriteInScope(elseB, clone(bound), true) : null;
        makeASTWithMeta(EIf(newCond, newThen, newElse), node.metadata, node.pos);

      case EUnless(cond, body, elseBranch):
        var newCond = rewriteInScope(cond, bound, true);
        var newBody = rewriteInScope(body, clone(bound), true);
        var newElse = elseBranch != null ? rewriteInScope(elseBranch, clone(bound), true) : null;
        makeASTWithMeta(EUnless(newCond, newBody, newElse), node.metadata, node.pos);

      case ECase(expr, clauses):
        var newExpr = rewriteInScope(expr, bound, true);
        var newClauses = [];
        for (cl in clauses) {
          var newGuard = cl.guard != null ? rewriteInScope(cl.guard, clone(bound), true) : null;
          var newBody = rewriteInScope(cl.body, clone(bound), true);
          newClauses.push({ pattern: cl.pattern, guard: newGuard, body: newBody });
        }
        makeASTWithMeta(ECase(newExpr, newClauses), node.metadata, node.pos);

      case ECond(clauses):
        var newClauses = [];
        for (cl in clauses) {
          newClauses.push({
            condition: rewriteInScope(cl.condition, bound, true),
            body: rewriteInScope(cl.body, clone(bound), true)
          });
        }
        makeASTWithMeta(ECond(newClauses), node.metadata, node.pos);

      case EWith(clauses, doBlock, elseBlock):
        var newClauses = [];
        for (c in clauses) newClauses.push({ pattern: c.pattern, expr: rewriteInScope(c.expr, bound, true) });
        var newDo = rewriteInScope(doBlock, clone(bound), true);
        var newElse = elseBlock != null ? rewriteInScope(elseBlock, clone(bound), true) : null;
        makeASTWithMeta(EWith(newClauses, newDo, newElse), node.metadata, node.pos);

      case EBinary(op, left, right):
        makeASTWithMeta(EBinary(op, rewriteInScope(left, bound, true), rewriteInScope(right, bound, true)), node.metadata, node.pos);
      case EMatch(p, rhs):
        makeASTWithMeta(EMatch(p, rewriteInScope(rhs, bound, true)), node.metadata, node.pos);
      case EUnary(opU, eU):
        makeASTWithMeta(EUnary(opU, rewriteInScope(eU, bound, true)), node.metadata, node.pos);
      case EParen(inner):
        makeASTWithMeta(EParen(rewriteInScope(inner, bound, valueUsed)), node.metadata, node.pos);
      case EPipe(l, r):
        makeASTWithMeta(EPipe(rewriteInScope(l, bound, true), rewriteInScope(r, bound, true)), node.metadata, node.pos);
      case ECall(tgt, fnName, args):
        makeASTWithMeta(ECall(tgt != null ? rewriteInScope(tgt, bound, true) : null, fnName, [for (a in args) rewriteInScope(a, bound, true)]), node.metadata, node.pos);
      case ERemoteCall(target, functionName, args):
        makeASTWithMeta(ERemoteCall(rewriteInScope(target, bound, true), functionName, [for (a in args) rewriteInScope(a, bound, true)]), node.metadata, node.pos);
      case EField(obj, fieldName):
        makeASTWithMeta(EField(rewriteInScope(obj, bound, true), fieldName), node.metadata, node.pos);
      case EAccess(obj, key):
        makeASTWithMeta(EAccess(rewriteInScope(obj, bound, true), rewriteInScope(key, bound, true)), node.metadata, node.pos);
      case EKeywordList(pairs):
        makeASTWithMeta(EKeywordList([for (p in pairs) { key: p.key, value: rewriteInScope(p.value, bound, true) }]), node.metadata, node.pos);
      case EMap(pairs):
        makeASTWithMeta(EMap([for (p in pairs) { key: rewriteInScope(p.key, bound, true), value: rewriteInScope(p.value, bound, true) }]), node.metadata, node.pos);
      case EStructUpdate(base, fields):
        makeASTWithMeta(EStructUpdate(rewriteInScope(base, bound, true), [for (f in fields) { key: f.key, value: rewriteInScope(f.value, bound, true) }]), node.metadata, node.pos);
      case ETuple(elems):
        makeASTWithMeta(ETuple([for (e in elems) rewriteInScope(e, bound, true)]), node.metadata, node.pos);
      case EList(elems):
        makeASTWithMeta(EList([for (e in elems) rewriteInScope(e, bound, true)]), node.metadata, node.pos);
      case ERange(start, end, exclusive, step):
        makeASTWithMeta(ERange(rewriteInScope(start, bound, true), rewriteInScope(end, bound, true), exclusive, step != null ? rewriteInScope(step, bound, true) : null), node.metadata, node.pos);
      case EPin(inner):
        makeASTWithMeta(EPin(rewriteInScope(inner, bound, true)), node.metadata, node.pos);

      // Nested scopes are handled by the outer transformNode walk.
      case EDef(_, _, _, _) | EDefp(_, _, _, _) | EFn(_):
        node;

      default:
        node;
    };
  }

  static function rewriteSeq(stmts: Array<ElixirAST>, bound: Map<String, Bool>, blockValueUsed: Bool): Array<ElixirAST> {
    if (stmts == null) return stmts;

    var localBound = clone(bound);
    var out: Array<ElixirAST> = [];

    for (i in 0...stmts.length) {
      var stmt = stmts[i];
      var stmtValueUsed = blockValueUsed && (i == stmts.length - 1);
      var newStmt = rewriteInScope(stmt, localBound, stmtValueUsed);

      // Hoist only in statement position:
      // - In value-used blocks, that's "all but last".
      // - In statement-only blocks, even the last statement's value is unused.
      if (!stmtValueUsed) {
        newStmt = maybeHoistControlFlowStatement(newStmt, localBound);
      }

      out.push(newStmt);
      bindFromStatement(newStmt, localBound);
    }

    return out;
  }

  // -------------------- Hoisting logic --------------------

  static function maybeHoistControlFlowStatement(stmt: ElixirAST, bound: Map<String, Bool>): ElixirAST {
    if (stmt == null || stmt.def == null) return stmt;

    return switch (stmt.def) {
      case EParen(inner):
        // Parentheses are frequently introduced by other passes for consistent printing.
        // If the inner expression is a hoistable control-flow statement, hoist it.
        maybeHoistControlFlowStatement(inner, bound);

      // Some pipelines materialize statement-position control-flow as `_ = <expr>`.
      // If the RHS is a control-flow form, treat it as a statement to hoist.
      case EBinary(Match, left, rhs) if (isUnderscoredVar(left) && isControlFlowExpr(rhs)):
        maybeHoistControlFlowStatement(rhs, bound);
      case EMatch(PVar(lhs), rhs) if (lhs != null && lhs.length > 0 && lhs.charAt(0) == '_' && isControlFlowExpr(rhs)):
        maybeHoistControlFlowStatement(rhs, bound);

      case EIf(cond, thenB, elseB):
        var updates = collectAssignedToBoundVars([thenB, elseB], bound);
        if (updates.length == 0) return stmt;
        var ret = makeReturnExpr(updates);

        var newThen = ensureReturns(thenB, ret);
        var newElse = (elseB != null) ? ensureReturns(elseB, ret) : ret;

        // Hoisting the outer `if` can change inner statement positions (e.g. the previous last
        // expression becomes a statement once we append the return expr). Re-run scope rewrite
        // on the new control-flow expression so nested hoists apply.
        var newIf = makeASTWithMeta(EIf(cond, newThen, newElse), stmt.metadata, stmt.pos);
        var rewrittenIf = rewriteInScope(newIf, clone(bound), true);
        makeHoistMatch(updates, rewrittenIf, stmt);

      case EUnless(cond, body, elseBranch):
        var updates = collectAssignedToBoundVars([body, elseBranch], bound);
        if (updates.length == 0) return stmt;
        var ret = makeReturnExpr(updates);

        var newBody = ensureReturns(body, ret);
        var newElse = (elseBranch != null) ? ensureReturns(elseBranch, ret) : ret;

        var newUnless = makeASTWithMeta(EUnless(cond, newBody, newElse), stmt.metadata, stmt.pos);
        var rewrittenUnless = rewriteInScope(newUnless, clone(bound), true);
        makeHoistMatch(updates, rewrittenUnless, stmt);

      case ECase(expr, clauses):
        var bodies:Array<ElixirAST> = [for (c in clauses) c.body];
        var updates = collectAssignedToBoundVars(bodies, bound);
        if (updates.length == 0) return stmt;
        var ret = makeReturnExpr(updates);

        var newClauses = [];
        for (c in clauses) {
          newClauses.push({ pattern: c.pattern, guard: c.guard, body: ensureReturns(c.body, ret) });
        }
        var newCase = makeASTWithMeta(ECase(expr, newClauses), stmt.metadata, stmt.pos);
        var rewrittenCase = rewriteInScope(newCase, clone(bound), true);
        makeHoistMatch(updates, rewrittenCase, stmt);

      case ECond(clauses):
        var bodies:Array<ElixirAST> = [for (c in clauses) c.body];
        var updates = collectAssignedToBoundVars(bodies, bound);
        if (updates.length == 0) return stmt;
        var ret = makeReturnExpr(updates);

        var newClauses = [];
        for (c in clauses) {
          newClauses.push({ condition: c.condition, body: ensureReturns(c.body, ret) });
        }
        var newCond = makeASTWithMeta(ECond(newClauses), stmt.metadata, stmt.pos);
        var rewrittenCond = rewriteInScope(newCond, clone(bound), true);
        makeHoistMatch(updates, rewrittenCond, stmt);

      default:
        stmt;
    };
  }

  static inline function isUnderscoredVar(lhs: ElixirAST): Bool {
    if (lhs == null || lhs.def == null) return false;
    return switch (lhs.def) {
      case EVar(nm) if (nm != null && nm.length > 0 && nm.charAt(0) == '_'): true;
      default: false;
    }
  }

  static function isControlFlowExpr(e: ElixirAST): Bool {
    if (e == null || e.def == null) return false;
    var cur = e;
    while (true) {
      switch (cur.def) {
        case EParen(inner): cur = inner; continue;
        default: break;
      }
    }
    return switch (cur.def) {
      case EIf(_, _, _) | EUnless(_, _, _) | ECase(_, _) | ECond(_): true;
      default: false;
    }
  }

  static function makeHoistMatch(updates: Array<String>, rhs: ElixirAST, originalStmt: ElixirAST): ElixirAST {
    if (updates.length == 1) {
      return makeASTWithMeta(EMatch(PVar(updates[0]), rhs), originalStmt.metadata, originalStmt.pos);
    }
    var pat = PTuple([for (n in updates) PVar(n)]);
    return makeASTWithMeta(EMatch(pat, rhs), originalStmt.metadata, originalStmt.pos);
  }

  static function ensureReturns(body: ElixirAST, returnExpr: ElixirAST): ElixirAST {
    if (body == null || body.def == null) return returnExpr;

    return switch (body.def) {
      case EBlock(stmts):
        var out = stmts == null ? [] : stmts.copy();
        out.push(returnExpr);
        makeASTWithMeta(EBlock(out), body.metadata, body.pos);
      case EDo(stmts):
        var out = stmts == null ? [] : stmts.copy();
        out.push(returnExpr);
        makeASTWithMeta(EDo(out), body.metadata, body.pos);
      default:
        makeASTWithMeta(EBlock([body, returnExpr]), body.metadata, body.pos);
    };
  }

  static function makeReturnExpr(names: Array<String>): ElixirAST {
    if (names.length == 1) return makeAST(EVar(names[0]));
    return makeAST(ETuple([for (n in names) makeAST(EVar(n))]));
  }

  static function collectAssignedToBoundVars(bodies: Array<ElixirAST>, bound: Map<String, Bool>): Array<String> {
    var found = new Map<String, Bool>();
    for (b in bodies) if (b != null) collectAssignedVars(b, bound, found);

    var out = [];
    for (k in found.keys()) out.push(k);
    out.sort(Reflect.compare);
    return out;
  }

  static function collectAssignedVars(node: ElixirAST, bound: Map<String, Bool>, out: Map<String, Bool>): Void {
    if (node == null || node.def == null) return;

    switch (node.def) {
      // Stop at inner closures; they are separate scopes.
      case EFn(_):
        return;

      case EMatch(pat, rhs):
        switch (pat) {
          case PVar(name) if (isBindableName(name) && bound.exists(name)):
            out.set(name, true);
          default:
        }
        collectAssignedVars(rhs, bound, out);

      case EBinary(Match, left, rhs):
        switch (left.def) {
          case EVar(name) if (isBindableName(name) && bound.exists(name)):
            out.set(name, true);
          default:
        }
        collectAssignedVars(rhs, bound, out);

      default:
        reflaxe.elixir.ast.ElixirASTTransformer.transformAST(node, function(n: ElixirAST): ElixirAST {
          collectAssignedVars(n, bound, out);
          return n;
        });
    }
  }

  // -------------------- Bound tracking --------------------

  static function bindFromStatement(stmt: ElixirAST, bound: Map<String, Bool>): Void {
    if (stmt == null || stmt.def == null) return;
    switch (stmt.def) {
      case EMatch(pat, _):
        bindFromPattern(pat, bound);
      case EBinary(Match, left, _):
        switch (left.def) { case EVar(name): if (isBindableName(name)) bound.set(name, true); default: }
      default:
    }
  }

  static function collectBoundFromArgs(args: Array<EPattern>): Map<String, Bool> {
    var m = new Map<String, Bool>();
    if (args == null) return m;
    for (a in args) bindFromPattern(a, m);
    return m;
  }

  static function bindFromPattern(p: EPattern, out: Map<String, Bool>): Void {
    if (p == null) return;
    switch (p) {
      case PVar(name):
        if (isBindableName(name)) out.set(name, true);
      case PAlias(aliasName, pat):
        if (isBindableName(aliasName)) out.set(aliasName, true);
        bindFromPattern(pat, out);
      case PTuple(items) | PList(items):
        for (i in items) bindFromPattern(i, out);
      case PCons(h, t):
        bindFromPattern(h, out);
        bindFromPattern(t, out);
      case PMap(fields):
        for (f in fields) bindFromPattern(f.value, out);
      case PStruct(_, structFields):
        for (f in structFields) bindFromPattern(f.value, out);
      case PBinary(segs):
        for (s in segs) bindFromPattern(s.pattern, out);
      case PPin(inner):
        bindFromPattern(inner, out);
      default:
    }
  }

  static inline function isBindableName(name: String): Bool {
    return name != null && name.length > 0 && name != "_";
  }

  static function clone(m: Map<String, Bool>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (m != null) for (k in m.keys()) out.set(k, true);
    return out;
  }
}

#end
