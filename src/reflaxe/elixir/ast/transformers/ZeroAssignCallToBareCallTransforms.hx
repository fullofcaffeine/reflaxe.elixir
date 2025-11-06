package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ZeroAssignCallToBareCallTransforms
 *
 * WHAT
 * - Rewrites numeric-sentinel assignments like `0 = call(...)` or
 *   `0 = Mod.call(...)` back to bare calls.
 *
 * WHY
 * - Some upstream lowering paths introduce `0 = ...` as a side-effect sentinel.
 *   This form is non-idiomatic and mismatches snapshot expectations. A bare
 *   call (or an underscore assignment handled elsewhere) communicates intent.
 *
 * HOW
 * - Pattern-match on EBinary(Match, EInteger(0), <call> | EParen(<call>))
 *   and replace the whole expression with the call expression itself.
 */
class ZeroAssignCallToBareCallTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(Match, {def: EInteger(0)}, rhs):
          switch (rhs.def) {
            case ECall(_, _, _) | ERemoteCall(_, _, _): rhs;
            case EParen(inner):
              switch (inner.def) {
                case ECall(_, _, _) | ERemoteCall(_, _, _): inner;
                default: n;
              }
            default: n;
          }
        case EMatch(PLiteral({def: EInteger(0)}), rhs2):
          switch (rhs2.def) {
            case ECall(_, _, _) | ERemoteCall(_, _, _): rhs2;
            case EParen(inner2):
              switch (inner2.def) {
                case ECall(_, _, _) | ERemoteCall(_, _, _): inner2;
                default: n;
              }
            default: n;
          }
        default:
          n;
      }
    });
  }
}

#end
