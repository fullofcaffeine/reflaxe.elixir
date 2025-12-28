package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HoistNestedAssignFromStringConcatTransforms
 *
 * WHAT
 * - Hoists nested assignments that appear inside string concatenations on the RHS of an
 *   outer assignment: `target = left <> (name = expr)` → `name = expr; target = left <> name`.
 *
 * WHY
 * - Nested `=` inside `<>` can print as `target = left <> name = expr`, which is invalid or
 *   misleading Elixir. Hoisting restores a linear, readable sequence and matches snapshot
 *   expectations in core/basic_syntax and related suites.
 *
 * HOW
 * - For each EBlock/EDo statement of shape `EBinary(Match, lhs, rhs)` where `rhs` contains
 *   `EBinary(StringConcat, left, inner)` and `inner` is an assignment to a simple variable,
 *   emit two statements: the inner assignment first, then the original outer assignment with
 *   the inner replaced by the bound variable.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HoistNestedAssignFromStringConcatTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (s in stmts) {
      var handled = false;
      switch (s.def) {
        case EBinary(Match, lhs, rhs):
          switch (rhs.def) {
            case EBinary(StringConcat, left, inner):
              var hoisted = tryHoist(inner);
              if (hoisted != null) {
                // Emit: (inner assignment), then the outer assign with inner replaced by EVar(name)
                out.push(hoisted.assign);
                var replacedRhs = makeAST(EBinary(StringConcat, left, makeAST(EVar(hoisted.name))));
                out.push(makeASTWithMeta(EBinary(Match, lhs, replacedRhs), s.metadata, s.pos));
                handled = true;
              }
            default:
          }
        default:
      }
      if (!handled) out.push(s);
    }
    return out;
  }

  static function tryHoist(inner: ElixirAST): Null<{name:String, assign:ElixirAST}> {
    return switch (inner.def) {
      case EBinary(Match, {def: EVar(v)}, rhs): { name: v, assign: makeAST(EBinary(Match, makeAST(EVar(v)), rhs)) };
      case EMatch(PVar(v2), rhs2): { name: v2, assign: makeAST(EMatch(PVar(v2), rhs2)) };
      case EParen(p): tryHoist(p);
      default: null;
    }
  }
}

#end

