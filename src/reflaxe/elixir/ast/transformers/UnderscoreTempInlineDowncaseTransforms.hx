package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnderscoreTempInlineDowncaseTransforms
 *
 * WHAT
 * - Inlines simple underscore-temporary assignment immediately followed by
 *   a String.downcase call in the same block.
 *
 * WHY
 * - Eliminates "underscored variable _this is used" warnings in nested
 *   if/else branches by removing the temporary altogether.
 *
 * HOW
 * - For consecutive statements: `_x = rhs; String.downcase(_x)` →
 *   `String.downcase(rhs)`.
 */
class UnderscoreTempInlineDowncaseTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var i = 0;
    while (i < stmts.length) {
      if (i + 1 < stmts.length) {
        switch (stmts[i].def) {
          case EBinary(Match, {def: EVar(tmp)}, rhs) if (tmp != null && tmp.length > 1 && tmp.charAt(0) == "_"):
            switch (stmts[i+1].def) {
              case ERemoteCall({def: EVar("String")}, fnName, args) if (fnName == "downcase" && args != null && args.length == 1):
                switch (args[0].def) {
                  case EVar(v) if (v == tmp):
                    out.push(makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "downcase", [rhs]), stmts[i+1].metadata, stmts[i+1].pos));
                    i += 2;
                    continue;
                  default:
                }
              default:
            }
          case EMatch(PVar(tmp2), rhs2) if (tmp2 != null && tmp2.length > 1 && tmp2.charAt(0) == "_"):
            switch (stmts[i+1].def) {
              case ERemoteCall({def: EVar("String")}, fnName2, args2) if (fnName2 == "downcase" && args2 != null && args2.length == 1):
                switch (args2[0].def) {
                  case EVar(v2) if (v2 == tmp2):
                    out.push(makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "downcase", [rhs2]), stmts[i+1].metadata, stmts[i+1].pos));
                    i += 2;
                    continue;
                  default:
                }
              default:
            }
          default:
        }
      }
      out.push(stmts[i]);
      i++;
    }
    return out;
  }
}

#end
