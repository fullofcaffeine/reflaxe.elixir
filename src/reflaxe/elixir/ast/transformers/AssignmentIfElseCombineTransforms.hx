package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignmentIfElseCombineTransforms
 *
 * WHAT
 * - (Documented in-file; see the existing code below.)
 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.
 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.
 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */

class AssignmentIfElseCombineTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts):
          var out:Array<ElixirAST> = [];
          var i = 0;
          while (i < stmts.length) {
            if (i + 1 < stmts.length) {
              switch (stmts[i].def) {
                case EBinary(Match, {def: EVar(a)}, {def: EVar(b)}):
                  switch (stmts[i + 1].def) {
                    case EIf(cond, thenE, elseE):
                      var elseIsB = switch (elseE.def) { case EVar(bb) if (bb == b): true; default: false; };
                      if (elseIsB) {
                        out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), stmts[i].metadata, stmts[i].pos), makeASTWithMeta(EIf(cond, thenE, elseE), stmts[i + 1].metadata, stmts[i + 1].pos)), stmts[i].metadata, stmts[i].pos));
                        i += 2; continue;
                      }
                    default:
                  }
                default:
              }
            }
            out.push(stmts[i]); i++;
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          var j = 0;
          while (j < stmts2.length) {
            if (j + 1 < stmts2.length) {
              switch (stmts2[j].def) {
                case EBinary(Match, {def: EVar(a2)}, {def: EVar(b2)}):
                  switch (stmts2[j + 1].def) {
                    case EIf(cond2, then2, else2):
                      var elseIsB2 = switch (else2.def) { case EVar(bb2) if (bb2 == b2): true; default: false; };
                      if (elseIsB2) {
                        out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), stmts2[j].metadata, stmts2[j].pos), makeASTWithMeta(EIf(cond2, then2, else2), stmts2[j + 1].metadata, stmts2[j + 1].pos)), stmts2[j].metadata, stmts2[j].pos));
                        j += 2; continue;
                      }
                    default:
                  }
                default:
              }
            }
            out2.push(stmts2[j]); j++;
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end

