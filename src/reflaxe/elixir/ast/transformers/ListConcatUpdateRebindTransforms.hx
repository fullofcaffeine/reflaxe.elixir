package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ListConcatUpdateRebindTransforms
 *
 * WHAT
 * - Converts "update-like" list concat expressions that appear in statement position into explicit
 *   rebindings of the target variable.
 * - Also rewrites statement-position control-flow (`if`/`unless`) whose branches return an updated
 *   list value back into a binding assignment to the updated variable.
 *
 * WHY
 * - On the Elixir target, many Haxe "mutation" calls (notably `Array.push`) lower to expressions like:
 *     list ++ [value]
 *   In Elixir, this does not mutate `list`; it merely computes a new list.
 * - When such expressions occur as statements (or as the value of a statement-position `if`), the
 *   computed list is dropped and state updates are lost. This breaks real apps (todo-app online users)
 *   and produces confusing "works sometimes" behavior depending on surrounding scoping/hoisting.
 *
 * HOW
 * - Walk statement lists (EBlock/EDo) with a simple "bound so far" set.
 * - Rewrite patterns like:
 *     _ = list ++ [x]                     -> list = list ++ [x]
 *     list ++ [x]                         -> list = list ++ [x]
 *     _ = if cond, do: list ++ [x], else: list
 *       -> list = if cond, do: list ++ [x], else: list
 * - We only rewrite when the target variable is already bound in the current scope, to avoid
 *   accidentally inventing new bindings for arbitrary list expressions.
 *
 * EXAMPLES
 * - Haxe:
 *     if (cond) errors.push("x");
 *   Elixir (before):
 *     _ = if cond, do: errors ++ ["x"], else: errors
 *   Elixir (after):
 *     errors = if cond, do: errors ++ ["x"], else: errors
 */
class ListConcatUpdateRebindTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      if (node == null || node.def == null) return node;
      return switch (node.def) {
        case EDef(name, args, guards, body):
          var bound = collectBoundFromArgs(args);
          var newGuards = guards != null ? rewriteInScope(guards, clone(bound), true) : null;
          var newBody = rewriteInScope(body, bound, true);
          makeASTWithMeta(EDef(name, args, newGuards, newBody), node.metadata, node.pos);

        case EDefp(name, args, guards, body):
          var bound2 = collectBoundFromArgs(args);
          var newGuards2 = guards != null ? rewriteInScope(guards, clone(bound2), true) : null;
          var newBody2 = rewriteInScope(body, bound2, true);
          makeASTWithMeta(EDefp(name, args, newGuards2, newBody2), node.metadata, node.pos);

        case EFn(clauses):
          var outClauses = [];
          for (cl in clauses) {
            var clauseBound = collectBoundFromArgs(cl.args);
            var newGuard3 = cl.guard != null ? rewriteInScope(cl.guard, clone(clauseBound), true) : null;
            var newBody3 = rewriteInScope(cl.body, clauseBound, true);
            outClauses.push({ args: cl.args, guard: newGuard3, body: newBody3 });
          }
          makeASTWithMeta(EFn(outClauses), node.metadata, node.pos);

        default:
          node;
      };
    });
  }

  static function rewriteInScope(node: ElixirAST, bound: Map<String, Bool>, valueUsed: Bool): ElixirAST {
    if (node == null || node.def == null) return node;
    return switch (node.def) {
      case EBlock(stmts):
        makeASTWithMeta(EBlock(rewriteSeq(stmts, bound, valueUsed)), node.metadata, node.pos);
      case EDo(stmts):
        makeASTWithMeta(EDo(rewriteSeq(stmts, bound, valueUsed)), node.metadata, node.pos);

      case EIf(cond, thenB, elseB):
        // Recurse but do not rewrite deep concat expressions in general expression context.
        // The statement list rewriting handles the actual rebinding decisions.
        var newCond = rewriteInScope(cond, bound, true);
        var newThen = rewriteInScope(thenB, clone(bound), true);
        var newElse = elseB != null ? rewriteInScope(elseB, clone(bound), true) : null;
        makeASTWithMeta(EIf(newCond, newThen, newElse), node.metadata, node.pos);

      case EUnless(cond, body, elseB):
        var newCond2 = rewriteInScope(cond, bound, true);
        var newBody2 = rewriteInScope(body, clone(bound), true);
        var newElse2 = elseB != null ? rewriteInScope(elseB, clone(bound), true) : null;
        makeASTWithMeta(EUnless(newCond2, newBody2, newElse2), node.metadata, node.pos);

      default:
        // Only traverse structural nodes; avoid inventing rebindings inside arbitrary expressions.
        ElixirASTTransformer.transformAST(node, function(child) return rewriteInScope(child, bound, true));
    };
  }

  static function rewriteSeq(stmts: Array<ElixirAST>, bound: Map<String, Bool>, blockValueUsed: Bool): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var localBound = clone(bound);
    var out: Array<ElixirAST> = [];

    for (i in 0...stmts.length) {
      var stmt = stmts[i];
      var stmtValueUsed = blockValueUsed && (i == stmts.length - 1);
      var rewritten = rewriteInScope(stmt, localBound, stmtValueUsed);
      rewritten = maybeRebindStatementUpdate(rewritten, localBound);
      out.push(rewritten);
      bindFromStatement(rewritten, localBound);
    }

    return out;
  }

  static function maybeRebindStatementUpdate(stmt: ElixirAST, bound: Map<String, Bool>): ElixirAST {
    if (stmt == null || stmt.def == null) return stmt;

    // unwrap `_ = ...` in statement position (common for unused statement results)
    var rhs: ElixirAST = null;
    switch (stmt.def) {
      case EMatch(PVar(name), r) if (name == "_"):
        rhs = r;
      case EBinary(Match, left, r2):
        switch (left.def) {
          case EVar(nm) if (nm == "_"):
            rhs = r2;
          default:
        }
      default:
    }

    if (rhs != null) {
      var rebindVar = updateTargetFromExpr(rhs, bound);
      if (rebindVar != null) {
        return makeASTWithMeta(EMatch(PVar(rebindVar), ensureIfElseReturnsVar(rhs, rebindVar)), stmt.metadata, stmt.pos);
      }
    }

    // Bare update expression as a statement: `list ++ [x]` / `Enum.concat(list, [x])`
    var direct = updateTargetFromExpr(stmt, bound);
    if (direct != null) {
      return makeASTWithMeta(EMatch(PVar(direct), stmt), stmt.metadata, stmt.pos);
    }

    // Statement-position control-flow that returns an updated list value: bind it.
    var flow = updateTargetFromExpr(stmt, bound);
    if (flow != null) {
      return makeASTWithMeta(EMatch(PVar(flow), ensureIfElseReturnsVar(stmt, flow)), stmt.metadata, stmt.pos);
    }

    return stmt;
  }

  static function updateTargetFromExpr(expr: ElixirAST, bound: Map<String, Bool>): Null<String> {
    if (expr == null || expr.def == null) return null;
    return switch (expr.def) {
      case EBinary(Concat, left, right):
        switch (left.def) {
          case EVar(name) if (isBindableName(name) && bound.exists(name)):
            name;
          default:
            null;
        }
      case ERemoteCall({def: EVar("Enum")}, "concat", args) if (args != null && args.length >= 2):
        switch (args[0].def) {
          case EVar(name2) if (isBindableName(name2) && bound.exists(name2)):
            name2;
          default:
            null;
        }
      case EIf(_, thenB, elseB):
        updateTargetFromIfBranches(thenB, elseB, bound);
      case EUnless(_, body, elseB2):
        updateTargetFromIfBranches(body, elseB2, bound);
      default:
        null;
    };
  }

  static function updateTargetFromIfBranches(thenBranch: ElixirAST, elseBranch: Null<ElixirAST>, bound: Map<String, Bool>): Null<String> {
    var thenExpr = branchValueExpr(thenBranch);
    var thenTarget = updateTargetFromBranchExpr(thenExpr, bound);
    if (thenTarget == null) return null;

    if (elseBranch == null) return thenTarget;

    var elseExpr = branchValueExpr(elseBranch);
    var elseTarget = updateTargetFromBranchExpr(elseExpr, bound);
    if (elseTarget == null) {
      // allow "else var" as unchanged branch
      switch (elseExpr.def) {
        case EVar(name) if (name == thenTarget):
          return thenTarget;
        default:
      }
      return null;
    }
    return (elseTarget == thenTarget) ? thenTarget : null;
  }

  static function updateTargetFromBranchExpr(expr: ElixirAST, bound: Map<String, Bool>): Null<String> {
    if (expr == null || expr.def == null) return null;
    return switch (expr.def) {
      case EBinary(Concat, left, _):
        switch (left.def) {
          case EVar(name) if (isBindableName(name) && bound.exists(name)):
            name;
          default:
            null;
        }
      case ERemoteCall({def: EVar("Enum")}, "concat", args) if (args != null && args.length >= 2):
        switch (args[0].def) {
          case EVar(name2) if (isBindableName(name2) && bound.exists(name2)):
            name2;
          default:
            null;
        }
      default:
        null;
    };
  }

  static function ensureIfElseReturnsVar(expr: ElixirAST, varName: String): ElixirAST {
    if (expr == null || expr.def == null) return expr;
    return switch (expr.def) {
      case EIf(cond, thenB, elseB):
        var fixedElse = elseB != null ? elseB : makeAST(EVar(varName));
        makeASTWithMeta(EIf(cond, thenB, fixedElse), expr.metadata, expr.pos);
      case EUnless(cond, body, elseB2):
        var fixedElse2 = elseB2 != null ? elseB2 : makeAST(EVar(varName));
        makeASTWithMeta(EUnless(cond, body, fixedElse2), expr.metadata, expr.pos);
      default:
        expr;
    };
  }

  static function branchValueExpr(branch: ElixirAST): ElixirAST {
    if (branch == null || branch.def == null) return makeAST(ENil);
    return switch (branch.def) {
      case EBlock(stmts):
        (stmts != null && stmts.length > 0) ? stmts[stmts.length - 1] : makeAST(ENil);
      case EDo(stmts):
        (stmts != null && stmts.length > 0) ? stmts[stmts.length - 1] : makeAST(ENil);
      default:
        branch;
    };
  }

  static function collectBoundFromArgs(args: Array<EPattern>): Map<String, Bool> {
    var m = new Map<String, Bool>();
    if (args == null) return m;
    for (a in args) bindFromPattern(a, m);
    return m;
  }

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

