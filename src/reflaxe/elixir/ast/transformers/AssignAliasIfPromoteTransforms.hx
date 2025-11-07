package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignAliasIfPromoteTransforms
 *
 * WHAT
 * - Promotes the window:
 *     a = b;
 *     if cond(a) do ... else b end
 *   into:
 *     a = if cond(b) do ... else b end
 *
 * WHY
 * - After splitting chains (a = b = rhs), code often becomes a=b; if cond(a) …
 *   Promoting this window restores intended shape and enables downstream folds.
 *
 * HOW
 * - Scan statement lists (EBlock/EDo). When [i] is a=b and [i+1] is EIf whose
 *   else is exactly b and whose condition references a, rewrite condition/body
 *   occurrences of a to b and promote into a single assignment.
 */
class AssignAliasIfPromoteTransforms {
  static inline function replaceVar(n: ElixirAST, from: String, to: String): ElixirAST {
    return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
        default: x;
      }
    });
  }

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
                      // else must be exactly b
                      var elseIsB = switch (elseE.def) { case EVar(bb) if (bb == b): true; default: false; };
                      if (elseIsB) {
                        // Require condition references a
                        var condHasA = false;
                        // Count if condition references `a` (public API: transformNode/visit)
                        ElixirASTTransformer.transformNode(cond, function(x: ElixirAST): ElixirAST {
                          switch (x.def) { case EVar(v) if (v == a): condHasA = true; default: }
                          return x;
                        });
                        if (condHasA) {
                          var newCond = replaceVar(cond, a, b);
                          var newThen = replaceVar(thenE, a, b);
                          out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), stmts[i].metadata, stmts[i].pos), makeASTWithMeta(EIf(newCond, newThen, elseE), stmts[i + 1].metadata, stmts[i + 1].pos)), stmts[i].metadata, stmts[i].pos));
                          i += 2;
                          continue;
                        }
                      }
                    default:
                  }
                default:
              }
            }
            out.push(stmts[i]);
            i++;
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(statements):
          var output:Array<ElixirAST> = [];
          var index = 0;
          while (index < statements.length) {
            if (index + 1 < statements.length) {
              switch (statements[index].def) {
                case EBinary(Match, {def: EVar(leftVar)}, {def: EVar(rightVar)}):
                  switch (statements[index + 1].def) {
                    case EIf(condExpr, thenExpr, elseExpr):
                      var elseIsRightVar = switch (elseExpr.def) { case EVar(ev) if (ev == rightVar): true; default: false; };
                      if (elseIsRightVar) {
                        var condReferencesLeftVar = false;
                        ElixirASTTransformer.transformNode(condExpr, function(x: ElixirAST): ElixirAST {
                          switch (x.def) { case EVar(v) if (v == leftVar): condReferencesLeftVar = true; default: }
                          return x;
                        });
                        if (condReferencesLeftVar) {
                          var rewrittenCond = replaceVar(condExpr, leftVar, rightVar);
                          var rewrittenThen = replaceVar(thenExpr, leftVar, rightVar);
                          output.push(
                            makeASTWithMeta(
                              EBinary(
                                Match,
                                makeASTWithMeta(EVar(leftVar), statements[index].metadata, statements[index].pos),
                                makeASTWithMeta(
                                  EIf(rewrittenCond, rewrittenThen, elseExpr),
                                  statements[index + 1].metadata,
                                  statements[index + 1].pos
                                )
                              ),
                              statements[index].metadata,
                              statements[index].pos
                            )
                          );
                          index += 2;
                          continue;
                        }
                      }
                    default:
                  }
                default:
              }
            }
            output.push(statements[index]);
            index++;
          }
          makeASTWithMeta(EDo(output), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
