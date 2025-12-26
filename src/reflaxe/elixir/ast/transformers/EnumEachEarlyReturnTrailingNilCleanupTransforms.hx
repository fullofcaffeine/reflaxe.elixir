package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * EnumEachEarlyReturnTrailingNilCleanupTransforms
 *
 * WHAT
 * - Removes a redundant trailing `nil` statement after a block whose prior expression is a
 *   `case` introduced by EnumEachEarlyReturnTransforms (`:__reflaxe_return__` tagging).
 *
 * WHY
 * - Some later hygiene/return-shaping passes can append an explicit `nil` after a terminal
 *   `Enum.each` statement. When EnumEachEarlyReturnTransforms rewrites that terminal `Enum.each`
 *   to a `case Enum.reduce_while(...)` expression (which already yields `nil` on the no-return
 *   path), a subsequently appended `nil` overrides the intended return value.
 *
 * HOW
 * - Walk EBlock/EDo sequences:
 *   - If the last statement is ENil AND the preceding statement is (or evaluates to) an
 *     `ECase` whose first-clause pattern begins with `:__reflaxe_return__`, drop the trailing ENil.
 *
 * EXAMPLES
 * Elixir (before):
 *   case Enum.reduce_while(...) do
 *     {:__reflaxe_return__, v} -> v
 *     _ -> nil
 *   end
 *   nil
 * Elixir (after):
 *   case Enum.reduce_while(...) do
 *     {:__reflaxe_return__, v} -> v
 *     _ -> nil
 *   end
 */
class EnumEachEarlyReturnTrailingNilCleanupTransforms {
  static inline var RETURN_TAG: ElixirAtom = ElixirAtom.raw("__reflaxe_return__");

  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EBlock(stmts):
          cleanupSequence(stmts, exprs -> makeASTWithMeta(EBlock(exprs), node.metadata, node.pos));
        case EDo(stmts):
          cleanupSequence(stmts, exprs -> makeASTWithMeta(EDo(exprs), node.metadata, node.pos));
        default:
          node;
      };
    });
  }

  static function cleanupSequence(stmts: Array<ElixirAST>, wrap: Array<ElixirAST> -> ElixirAST): ElixirAST {
    if (stmts == null || stmts.length < 2) return wrap(stmts);

    var last = stmts[stmts.length - 1];
    var lastIsNil = switch (last.def) { case ENil: true; default: false; };
    if (!lastIsNil) return wrap(stmts);

    var prev = stmts[stmts.length - 2];
    var matches = isReflaxeReturnCase(prev);

    if (!matches) return wrap(stmts);

    return wrap(stmts.slice(0, stmts.length - 1));
  }

  static function isReflaxeReturnCase(expr: ElixirAST): Bool {
    var core = unwrapParens(expr);

    // `_ = case ...` still evaluates to the RHS; unwrap to recognize the tag.
    core = switch (core.def) {
      case EMatch(PVar("_"), rhs):
        unwrapParens(rhs);
      case EBinary(Match, {def: EVar("_")}, rhs2):
        unwrapParens(rhs2);
      default:
        core;
    };

    // Some pipeline stages wrap expressions in a one-off block; peel it back so the
    // cleanup can recognize the return-tagged `case` as the last meaningful expr.
    core = switch (core.def) {
      case EBlock(stmts) | EDo(stmts):
        var filtered = [for (s in stmts) s];
        filtered.length > 0 ? unwrapParens(filtered[filtered.length - 1]) : core;
      default:
        core;
    };

    return switch (core.def) {
      case ECase(_scrut, clauses) if (clauses != null && clauses.length > 0):
        clausesHasReturnTag(clauses);
      default:
        false;
    };
  }

  static function clausesHasReturnTag(clauses: Array<{pattern: EPattern, guard: Null<ElixirAST>, body: ElixirAST}>): Bool {
    for (clause in clauses) {
      if (patternHasReturnTag(clause.pattern)) return true;
    }
    return false;
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

  static function unwrapParens(expr: ElixirAST): ElixirAST {
    if (expr == null || expr.def == null) return expr;
    return switch (expr.def) {
      case EParen(inner): unwrapParens(inner);
      default: expr;
    };
  }
}

#end
