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
      case EDo(stmts2):
        // debug removed
        var out2:Array<ElixirAST> = [];
        var j = 0;
        while (j < stmts2.length) {
          if (j + 1 < stmts2.length) {
            switch (stmts2[j].def) {
              case EBinary(Match, {def: EVar(a)}, {def: EBinary(Match, {def: EVar(b)}, rhs)}):
                switch (stmts2[j + 1].def) {
                  case EIf(cond2, then2, else2):
                    var elseIsB = switch (else2.def) { case EVar(bb) if (bb == b): true; default: false; };
                    if (elseIsB) {
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b), stmts2[j].metadata, stmts2[j].pos), rhs), stmts2[j].metadata, stmts2[j].pos));
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), stmts2[j].metadata, stmts2[j].pos), makeASTWithMeta(EIf(cond2, then2, else2), stmts2[j + 1].metadata, stmts2[j + 1].pos)), stmts2[j].metadata, stmts2[j].pos));
                      j += 2; continue;
                    }
                  default:
                }
              case EMatch(PVar(aM), {def: EBinary(Match, {def: EVar(bM)}, rhsM)}):
                switch (stmts2[j + 1].def) {
                  case EIf(condM, thenM, elseM):
                    var elseIsBM = switch (elseM.def) { case EVar(bbM) if (bbM == bM): true; default: false; };
                    if (elseIsBM) {
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bM), stmts2[j].metadata, stmts2[j].pos), rhsM), stmts2[j].metadata, stmts2[j].pos));
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aM), stmts2[j].metadata, stmts2[j].pos), makeASTWithMeta(EIf(condM, thenM, elseM), stmts2[j + 1].metadata, stmts2[j + 1].pos)), stmts2[j].metadata, stmts2[j].pos));
                      j += 2; continue;
                    }
                  default:
                }
              case EMatch(PVar(aM2), {def: EMatch(PVar(bM2), rhsM2)}):
                switch (stmts2[j + 1].def) {
                  case EIf(condM2, thenM2, elseM2):
                    var elseIsBM2 = switch (elseM2.def) { case EVar(bbM2) if (bbM2 == bM2): true; default: false; };
                    if (elseIsBM2) {
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bM2), stmts2[j].metadata, stmts2[j].pos), rhsM2), stmts2[j].metadata, stmts2[j].pos));
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aM2), stmts2[j].metadata, stmts2[j].pos), makeASTWithMeta(EIf(condM2, thenM2, elseM2), stmts2[j + 1].metadata, stmts2[j + 1].pos)), stmts2[j].metadata, stmts2[j].pos));
                      j += 2; continue;
                    }
                  default:
                }
              default:
                // Additional window: a = (b <- rhs); if ... else b end
                switch (stmts2[j].def) {
                  case EBinary(Match, {def: EVar(a2)}, {def: EMatch(PVar(b2), rhs2)}):
                    switch (stmts2[j + 1].def) {
                      case EIf(condX, thenX, elseX):
                        var elseIsBX = switch (elseX.def) { case EVar(bbX) if (bbX == b2): true; default: false; };
                        if (elseIsBX) {
                          out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b2), stmts2[j].metadata, stmts2[j].pos), rhs2), stmts2[j].metadata, stmts2[j].pos));
                          out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), stmts2[j].metadata, stmts2[j].pos), makeASTWithMeta(EIf(condX, thenX, elseX), stmts2[j + 1].metadata, stmts2[j + 1].pos)), stmts2[j].metadata, stmts2[j].pos));
                          j += 2; continue;
                        }
                      default:
                    }
                  default:
                }
            }
          }
          out2.push(stmts2[j]);
          j++;
        }
        makeASTWithMeta(EDo(out2), block.metadata, block.pos);
      default:
        block;
    }
  }
}

#end
