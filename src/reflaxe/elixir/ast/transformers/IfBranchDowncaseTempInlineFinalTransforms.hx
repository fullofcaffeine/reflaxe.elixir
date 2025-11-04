package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfBranchDowncaseTempInlineFinalTransforms
 *
 * WHAT
 * - Inline underscore temporaries inside if/else branches when the branch body
 *   is exactly `_tmp = rhs; String.downcase(_tmp)`.
 *
 * WHY
 * - Removes underscored temp usage that trips warnings-as-errors in nested
 *   branches produced by earlier neutral lowerings.
 */
class IfBranchDowncaseTempInlineFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EIf(cond, thenE, elseE):
          var t2 = inlineDowncaseBlock(thenE);
          var e2 = (elseE == null) ? null : inlineDowncaseBlock(elseE);
          if (t2 != thenE || e2 != elseE) makeASTWithMeta(EIf(cond, t2, e2), n.metadata, n.pos) else n;
        default: n;
      }
    });
  }

  static function inlineDowncaseBlock(branch: ElixirAST): ElixirAST {
    return switch (branch.def) {
      case EBlock(stmts):
        var arr = stmts;
        if (arr != null && arr.length == 2) {
          var tmpName: Null<String> = null;
          var rhs: Null<ElixirAST> = null;
          switch (arr[0].def) {
            case EBinary(Match, {def: EVar(nm)}, r) if (nm != null && nm.length > 1 && nm.charAt(0) == "_"):
              tmpName = nm; rhs = r;
            case EMatch(PVar(nm2), r2) if (nm2 != null && nm2.length > 1 && nm2.charAt(0) == "_"):
              tmpName = nm2; rhs = r2;
            default:
          }
          if (tmpName != null && rhs != null) {
            switch (arr[1].def) {
              case ERemoteCall({def: EVar("String")}, fn, args) if (fn == "downcase" && args != null && args.length == 1):
                switch (args[0].def) {
                  case EVar(v) if (v == tmpName):
                    return makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "downcase", [rhs]), branch.metadata, branch.pos);
                  default:
                }
              default:
            }
          }
        }
        branch;
      case EDo(stmts2):
        var arr2 = stmts2;
        if (arr2 != null && arr2.length == 2) {
          var tmp2: Null<String> = null;
          var rhs2: Null<ElixirAST> = null;
          switch (arr2[0].def) {
            case EBinary(Match, {def: EVar(nm3)}, r3) if (nm3 != null && nm3.length > 1 && nm3.charAt(0) == "_"):
              tmp2 = nm3; rhs2 = r3;
            case EMatch(PVar(nm4), r4) if (nm4 != null && nm4.length > 1 && nm4.charAt(0) == "_"):
              tmp2 = nm4; rhs2 = r4;
            default:
          }
          if (tmp2 != null && rhs2 != null) {
            switch (arr2[1].def) {
              case ERemoteCall({def: EVar("String")}, fn2, args2) if (fn2 == "downcase" && args2 != null && args2.length == 1):
                switch (args2[0].def) {
                  case EVar(v2) if (v2 == tmp2):
                    return makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "downcase", [rhs2]), branch.metadata, branch.pos);
                  default:
                }
              default:
            }
          }
        }
        branch;
      default:
        branch;
    }
  }
}

#end
