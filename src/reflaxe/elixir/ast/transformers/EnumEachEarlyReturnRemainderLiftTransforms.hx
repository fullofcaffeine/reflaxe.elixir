package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr.Position;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

private typedef EnumEachEarlyReturnTerminalCase = {
  caseExpr: ElixirAST,
  rebuild: ElixirAST -> ElixirAST
};

/**
 * EnumEachEarlyReturnRemainderLiftTransforms
 *
 * WHAT
 * - Fixes nested-block early-return rewrites where EnumEachEarlyReturnTransforms rewrote an inner
 *   loop block to a return-tagged `case Enum.reduce_while(...)` but could not capture the outer
 *   remainder statements that follow the loop.
 *
 * WHY
 * - Haxe desugars `for (x in array)` into a local counter + cached array + `while` block.
 * - Our builder can emit that loop as an `EBlock([counter_init, array_bind, Enum.each(...)])` which
 *   appears as a single statement in an outer block that continues with more statements.
 * - EnumEachEarlyReturnTransforms runs post-order and will match the inner block first, producing:
 *     (case Enum.reduce_while(...) do
 *       {:__reflaxe_return__, v} -> v
 *       _ -> nil
 *     end)
 *     <outer-remainder...>
 *   which overrides the intended return value.
 *
 * HOW
 * - Scan EBlock/EDo statement sequences.
 * - When a statement ends with a reflaxe return-tagged `case` whose wildcard clause body is `nil`,
 *   and there are subsequent statements in the same container, move *all* subsequent statements
 *   into that wildcard clause body and truncate the outer sequence.
 *
 * EXAMPLES
 * Elixir (before):
 *   _g = 0
 *   g_value = users()
 *   (case Enum.reduce_while(g_value, :__reflaxe_no_return__, fn u, _ ->
 *          if u.id == id, do: {:halt, {:__reflaxe_return__, {:some, u}}}, else: {:cont, :__reflaxe_no_return__}
 *        end) do
 *     {:__reflaxe_return__, v} -> v
 *     _ -> nil
 *   end)
 *   {:none}
 *
 * Elixir (after):
 *   _g = 0
 *   g_value = users()
 *   case Enum.reduce_while(g_value, :__reflaxe_no_return__, fn u, _ ->
 *          if u.id == id, do: {:halt, {:__reflaxe_return__, {:some, u}}}, else: {:cont, :__reflaxe_no_return__}
 *        end) do
 *     {:__reflaxe_return__, v} -> v
 *     _ -> {:none}
 *   end
 */
class EnumEachEarlyReturnRemainderLiftTransforms {
  static inline var RETURN_TAG: ElixirAtom = ElixirAtom.raw("__reflaxe_return__");

  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EBlock(stmts):
          makeASTWithMeta(EBlock(liftRemainder(stmts, node.metadata, node.pos)), node.metadata, node.pos);
        case EDo(stmts):
          makeASTWithMeta(EDo(liftRemainder(stmts, node.metadata, node.pos)), node.metadata, node.pos);
        default:
          node;
      };
    });
  }

  static function liftRemainder(stmts: Array<ElixirAST>, meta: ElixirMetadata, pos: Position): Array<ElixirAST> {
    if (stmts == null || stmts.length < 2) return stmts;

    var out: Array<ElixirAST> = [];
    var index = 0;
    while (index < stmts.length) {
      var stmt = stmts[index];

      var terminal = extractTerminalReturnCase(stmt);
      if (terminal != null && index < stmts.length - 1) {
        var remainder = stmts.slice(index + 1);
        var elseExpr = buildElseExprFromRemainder(remainder, meta, pos);

        var patched = patchReturnCaseElse(terminal.caseExpr, elseExpr);
        if (patched == null) {
          out.push(stmt);
          index++;
          continue;
        }

        out.push(terminal.rebuild(patched));
        return out; // remainder moved into the case; truncate
      }

      out.push(stmt);
      index++;
    }

    return out;
  }

  static function buildElseExprFromRemainder(remainder: Array<ElixirAST>, meta: ElixirMetadata, pos: Position): ElixirAST {
    if (remainder == null || remainder.length == 0) return makeAST(ENil);
    if (remainder.length == 1) return remainder[0];
    return makeASTWithMeta(EBlock(remainder), meta, pos);
  }

  static function extractTerminalReturnCase(stmt: ElixirAST): Null<EnumEachEarlyReturnTerminalCase> {
    if (stmt == null || stmt.def == null) return null;

    // Direct case expression statement
    if (isReturnTaggedCase(stmt) && caseWildcardIsNil(stmt)) {
      return {
        caseExpr: stmt,
        rebuild: patched -> patched
      };
    }

    // Statement block whose last meaningful statement is the return-tagged case
    return switch (stmt.def) {
      case EBlock(stmts):
        extractFromContainer(stmt, stmts, (rebuilt) -> makeASTWithMeta(EBlock(rebuilt), stmt.metadata, stmt.pos));
      case EDo(stmts):
        extractFromContainer(stmt, stmts, (rebuilt) -> makeASTWithMeta(EDo(rebuilt), stmt.metadata, stmt.pos));
      default:
        null;
    };
  }

  static function extractFromContainer(
    original: ElixirAST,
    stmts: Array<ElixirAST>,
    wrap: Array<ElixirAST> -> ElixirAST
  ): Null<EnumEachEarlyReturnTerminalCase> {
    if (stmts == null || stmts.length == 0) return null;

    var lastIndex = findLastMeaningfulIndex(stmts);
    if (lastIndex < 0) return null;

    var lastStmt = stmts[lastIndex];
    if (!isReturnTaggedCase(lastStmt) || !caseWildcardIsNil(lastStmt)) return null;

    return {
      caseExpr: lastStmt,
      rebuild: patched -> {
        var rebuilt = stmts.copy();
        rebuilt[lastIndex] = patched;
        wrap(rebuilt);
      }
    };
  }

  static function findLastMeaningfulIndex(stmts: Array<ElixirAST>): Int {
    if (stmts == null) return -1;
    var idx = stmts.length - 1;
    while (idx >= 0) {
      var s = stmts[idx];
      if (s != null && s.def != null && !isBareNumericSentinel(s)) return idx;
      idx--;
    }
    return -1;
  }

  static inline function isBareNumericSentinel(e: ElixirAST): Bool {
    return switch (e.def) {
      case EInteger(v) if (v == 0 || v == 1): true;
      case EFloat(f) if (f == 0.0): true;
      case ERaw(code) if (code != null && (StringTools.trim(code) == "0" || StringTools.trim(code) == "1")): true;
      default: false;
    };
  }

  static function isReturnTaggedCase(expr: ElixirAST): Bool {
    var core = unwrapParens(expr);
    return switch (core.def) {
      case ECase(_scrut, clauses) if (clauses != null && clauses.length > 0):
        // Must contain the return-tagged clause.
        for (clause in clauses) {
          if (patternHasReturnTag(clause.pattern)) return true;
        }
        false;
      default:
        false;
    };
  }

  static function caseWildcardIsNil(expr: ElixirAST): Bool {
    var core = unwrapParens(expr);
    return switch (core.def) {
      case ECase(_scrut, clauses) if (clauses != null):
        for (clause in clauses) {
          switch (clause.pattern) {
            case PWildcard:
              return isImplicitNil(clause.body);
            default:
          }
        }
        false;
      default:
        false;
    };
  }

  static function patchReturnCaseElse(caseExpr: ElixirAST, elseExpr: ElixirAST): Null<ElixirAST> {
    var parenCount = 0;
    var core = caseExpr;
    while (core != null && core.def != null) {
      switch (core.def) {
        case EParen(inner):
          parenCount++;
          core = inner;
        default:
          break;
      }
    }

    var patchedCore = switch (core.def) {
      case ECase(scrut, clauses) if (clauses != null):
        var hasReturnTag = false;
        for (clause in clauses) if (patternHasReturnTag(clause.pattern)) hasReturnTag = true;
        if (!hasReturnTag) return null;

        var newClauses = [];
        var changed = false;
        for (clause in clauses) {
          if (clause.pattern == PWildcard && isImplicitNil(clause.body)) {
            newClauses.push({pattern: clause.pattern, guard: clause.guard, body: elseExpr});
            changed = true;
          } else {
            newClauses.push(clause);
          }
        }
        if (!changed) return null;

        makeASTWithMeta(ECase(scrut, newClauses), caseExpr.metadata, caseExpr.pos);
      default:
        null;
    };

    if (patchedCore == null) return null;

    var wrapped = patchedCore;
    for (_ in 0...parenCount) {
      wrapped = makeASTWithMeta(EParen(wrapped), caseExpr.metadata, caseExpr.pos);
    }
    return wrapped;
  }

  static function patternHasReturnTag(pattern: EPattern): Bool {
    return switch (pattern) {
      case PTuple([PLiteral(lit), _]) if (lit != null && lit.def != null):
        switch (lit.def) {
          case EAtom(v): v == RETURN_TAG;
          default: false;
        }
      default:
        false;
    };
  }

  static function isImplicitNil(expr: ElixirAST): Bool {
    if (expr == null || expr.def == null) return true;
    return switch (expr.def) {
      case ENil: true;
      case EBlock(stmts) if (stmts == null || stmts.length == 0): true;
      case EDo(stmts2) if (stmts2 == null || stmts2.length == 0): true;
      default: false;
    };
  }

  static function unwrapParens(expr: ElixirAST): ElixirAST {
    if (expr == null || expr.def == null) return expr;
    return switch (expr.def) {
      case EParen(inner): unwrapParens(inner);
      default: expr;
    };
  }
}

#end
