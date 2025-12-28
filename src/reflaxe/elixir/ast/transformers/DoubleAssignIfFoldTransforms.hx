package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DoubleAssignIfFoldTransforms
 *
 * WHAT
 * - Folds the window: `a = (b = rhs); if cond(b) do ... else b end`
 *   into: `b = rhs; a = if cond(b) do ... else b end`.
 *
 * WHY
 * - Snapshot SwitchSideEffects expects linear assignments without chained matches, and
 *   the conditional applied to the assigned accumulator.
 *
 * HOW
 * - Runs late; scans EBlock/EDo (and recursively within EFn bodies via transformNode).
 * - Matches adjacent or small-window patterns and rewrites as two statements.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DoubleAssignIfFoldTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts):
          var out:Array<ElixirAST> = [];
          var i = 0;
          while (i < stmts.length) {
            var s = stmts[i];
            var folded = false;
            switch (s.def) {
              case EBinary(Match, {def: EVar(a)}, {def: EBinary(Match, {def: EVar(b)}, rhs)}):
                if (i + 1 < stmts.length) {
                  switch (stmts[i + 1].def) {
                    case EIf(cond, thenE, elseE):
                      var elseIsB = switch (elseE.def) { case EVar(bb) if (bb == b): true; default: false; };
                      if (elseIsB) {
                        out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b), s.metadata, s.pos), rhs), s.metadata, s.pos));
                        out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EIf(cond, thenE, elseE), stmts[i + 1].metadata, stmts[i + 1].pos)), s.metadata, s.pos));
                        i += 2; folded = true;
                      }
                    default:
                  }
                }
              default:
            }
            if (!folded) { out.push(s); i++; }
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          var j = 0;
          while (j < stmts2.length) {
            var s2 = stmts2[j];
            var folded2 = false;
            switch (s2.def) {
              case EBinary(Match, {def: EVar(a2)}, {def: EBinary(Match, {def: EVar(b2)}, rhs2)}):
                if (j + 1 < stmts2.length) {
                  switch (stmts2[j + 1].def) {
                    case EIf(cond2, then2, else2):
                      var elseIsB2 = switch (else2.def) { case EVar(bb2) if (bb2 == b2): true; default: false; };
                      if (elseIsB2) {
                        out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b2), s2.metadata, s2.pos), rhs2), s2.metadata, s2.pos));
                        out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), s2.metadata, s2.pos), makeASTWithMeta(EIf(cond2, then2, else2), stmts2[j + 1].metadata, stmts2[j + 1].pos)), s2.metadata, s2.pos));
                        j += 2; folded2 = true;
                      }
                    default:
                  }
                }
              default:
            }
            if (!folded2) { out2.push(s2); j++; }
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
