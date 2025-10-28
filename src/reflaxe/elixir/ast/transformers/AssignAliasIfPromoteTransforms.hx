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
                        var condHasA2 = false;
                        ElixirASTTransformer.transformNode(cond2, function(x: ElixirAST): ElixirAST {
                          switch (x.def) { case EVar(v) if (v == a2): condHasA2 = true; default: }
                          return x;
                        });
                        if (condHasA2) {
                          var newCond2 = replaceVar(cond2, a2, b2);
                          var newThen2 = replaceVar(then2, a2, b2);
                          out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), stmts2[j].metadata, stmts2[j].pos), makeASTWithMeta(EIf(newCond2, newThen2, else2), stmts2[j + 1].metadata, stmts2[j + 1].pos)), stmts2[j].metadata, stmts2[j].pos));
                          j += 2;
                          continue;
                        }
                      }
                    default:
                  }
                default:
              }
            }
            out2.push(stmts2[j]);
            j++;
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
