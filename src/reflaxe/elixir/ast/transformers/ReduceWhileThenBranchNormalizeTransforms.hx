package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceWhileThenBranchNormalizeTransforms
 *
 * WHAT
 * - Inside an EIf then-branch EBlock, rewrite the window:
 *   a = (b = rhs);
 *   if cond(b) do ... else b end
 *   →
 *   b = rhs;
 *   a = if cond(b) do ... else b end
 *
 * WHY
 * - Ensures accumulator threading and readable shape in reduce_while bodies.
 *
 * HOW
 * - Runs late and matches any EIf node; if its then-branch is EBlock, apply the normalization.
 */
class ReduceWhileThenBranchNormalizeTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EIf(cond, thenE, elseE):
          // debug removed
          var newThen = normalizeBlock(thenE);
          if (newThen != thenE) makeASTWithMeta(EIf(cond, newThen, elseE), n.metadata, n.pos) else n;
        default:
          n;
      }
    });
  }

  static function normalizeBlock(block: ElixirAST): ElixirAST {
    return switch (block.def) {
      case EBlock(stmts):
        // debug removed
        var out:Array<ElixirAST> = [];
        var i = 0;
        while (i < stmts.length) {
          if (i + 1 < stmts.length) {
            switch (stmts[i].def) {
              case EBinary(Match, {def: EVar(a)}, {def: EBinary(Match, {def: EVar(b)}, rhs)}):
                // debug removed
                switch (stmts[i + 1].def) {
                  case EIf(cond2, then2, else2):
                    // debug removed
                    var elseIsB = switch (else2.def) { case EVar(bb) if (bb == b): true; default: false; };
                    if (elseIsB) {
                      // debug removed
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b), stmts[i].metadata, stmts[i].pos), rhs), stmts[i].metadata, stmts[i].pos));
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), stmts[i].metadata, stmts[i].pos), makeASTWithMeta(EIf(cond2, then2, else2), stmts[i + 1].metadata, stmts[i + 1].pos)), stmts[i].metadata, stmts[i].pos));
                      i += 2; continue;
                    }
                  default:
                }
              case EMatch(PVar(aM), {def: EBinary(Match, {def: EVar(bM)}, rhsM)}):
                // debug removed
                switch (stmts[i + 1].def) {
                  case EIf(condM, thenM, elseM):
                    var elseIsBM = switch (elseM.def) { case EVar(bbM) if (bbM == bM): true; default: false; };
                    if (elseIsBM) {
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bM), stmts[i].metadata, stmts[i].pos), rhsM), stmts[i].metadata, stmts[i].pos));
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aM), stmts[i].metadata, stmts[i].pos), makeASTWithMeta(EIf(condM, thenM, elseM), stmts[i + 1].metadata, stmts[i + 1].pos)), stmts[i].metadata, stmts[i].pos));
                      i += 2; continue;
                    }
                  default:
                }
              case EMatch(PVar(aM2), {def: EMatch(PVar(bM2), rhsM2)}):
                // debug removed
                switch (stmts[i + 1].def) {
                  case EIf(condM2, thenM2, elseM2):
                    var elseIsBM2 = switch (elseM2.def) { case EVar(bbM2) if (bbM2 == bM2): true; default: false; };
                    if (elseIsBM2) {
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bM2), stmts[i].metadata, stmts[i].pos), rhsM2), stmts[i].metadata, stmts[i].pos));
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aM2), stmts[i].metadata, stmts[i].pos), makeASTWithMeta(EIf(condM2, thenM2, elseM2), stmts[i + 1].metadata, stmts[i + 1].pos)), stmts[i].metadata, stmts[i].pos));
                      i += 2; continue;
                    }
                  default:
                }
              default:
              // Additional windows: a = (b <- rhs); if ... else b end
              switch (stmts[i].def) {
                case EBinary(Match, {def: EVar(a2)}, {def: EMatch(PVar(b2), rhs2)}):
                  switch (stmts[i + 1].def) {
                    case EIf(condX, thenX, elseX):
                      var elseIsBX = switch (elseX.def) { case EVar(bbX) if (bbX == b2): true; default: false; };
                      if (elseIsBX) {
                        out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b2), stmts[i].metadata, stmts[i].pos), rhs2), stmts[i].metadata, stmts[i].pos));
                        out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), stmts[i].metadata, stmts[i].pos), makeASTWithMeta(EIf(condX, thenX, elseX), stmts[i + 1].metadata, stmts[i + 1].pos)), stmts[i].metadata, stmts[i].pos));
                        i += 2; continue;
                      }
                    default:
                  }
                default:
              }
            }
          }
          out.push(stmts[i]);
          i++;
        }
        makeASTWithMeta(EBlock(out), block.metadata, block.pos);
      case EDo(statements):
        // debug removed
        var output:Array<ElixirAST> = [];
        var index = 0;
        while (index < statements.length) {
          if (index + 1 < statements.length) {
            switch (statements[index].def) {
              case EBinary(Match, {def: EVar(a)}, {def: EBinary(Match, {def: EVar(b)}, rhs)}):
                switch (statements[index + 1].def) {
                  case EIf(condExpr, thenExpr, elseExpr):
                    var elseIsB = switch (elseExpr.def) { case EVar(bb) if (bb == b): true; default: false; };
                    if (elseIsB) {
                      output.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b), statements[index].metadata, statements[index].pos), rhs), statements[index].metadata, statements[index].pos));
                      output.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), statements[index].metadata, statements[index].pos), makeASTWithMeta(EIf(condExpr, thenExpr, elseExpr), statements[index + 1].metadata, statements[index + 1].pos)), statements[index].metadata, statements[index].pos));
                      index += 2; continue;
                    }
                  default:
                }
              case EMatch(PVar(aM), {def: EBinary(Match, {def: EVar(bM)}, rhsM)}):
                switch (statements[index + 1].def) {
                  case EIf(condM, thenM, elseM):
                    var elseIsBM = switch (elseM.def) { case EVar(bbM) if (bbM == bM): true; default: false; };
                    if (elseIsBM) {
                      output.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bM), statements[index].metadata, statements[index].pos), rhsM), statements[index].metadata, statements[index].pos));
                      output.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aM), statements[index].metadata, statements[index].pos), makeASTWithMeta(EIf(condM, thenM, elseM), statements[index + 1].metadata, statements[index + 1].pos)), statements[index].metadata, statements[index].pos));
                      index += 2; continue;
                    }
                  default:
                }
              case EMatch(PVar(aM2), {def: EMatch(PVar(bM2), rhsM2)}):
                switch (statements[index + 1].def) {
                  case EIf(condM2, thenM2, elseM2):
                    var elseIsBM2 = switch (elseM2.def) { case EVar(bbM2) if (bbM2 == bM2): true; default: false; };
                    if (elseIsBM2) {
                      output.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bM2), statements[index].metadata, statements[index].pos), rhsM2), statements[index].metadata, statements[index].pos));
                      output.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aM2), statements[index].metadata, statements[index].pos), makeASTWithMeta(EIf(condM2, thenM2, elseM2), statements[index + 1].metadata, statements[index + 1].pos)), statements[index].metadata, statements[index].pos));
                      index += 2; continue;
                    }
                  default:
                }
              default:
                // Additional window: a = (b <- rhs); if ... else b end
                switch (statements[index].def) {
                  case EBinary(Match, {def: EVar(leftVar)}, {def: EMatch(PVar(rightVar), rhsExpr)}):
                    switch (statements[index + 1].def) {
                      case EIf(condX, thenX, elseX):
                        var elseIsBX = switch (elseX.def) { case EVar(bbX) if (bbX == rightVar): true; default: false; };
                        if (elseIsBX) {
                          output.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(rightVar), statements[index].metadata, statements[index].pos), rhsExpr), statements[index].metadata, statements[index].pos));
                          output.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(leftVar), statements[index].metadata, statements[index].pos), makeASTWithMeta(EIf(condX, thenX, elseX), statements[index + 1].metadata, statements[index + 1].pos)), statements[index].metadata, statements[index].pos));
                          index += 2; continue;
                        }
                      default:
                    }
                  default:
                }
            }
          }
          output.push(statements[index]);
          index++;
        }
        makeASTWithMeta(EDo(output), block.metadata, block.pos);
      default:
        block;
    }
  }
}

#end
