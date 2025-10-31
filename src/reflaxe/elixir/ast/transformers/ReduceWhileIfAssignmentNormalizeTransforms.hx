package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceWhileIfAssignmentNormalizeTransforms
 *
 * WHAT
 * - Inside Enum.reduce_while anonymous functions, normalize the common pattern:
 *   a = (b = expr); if cond(b) do ... else b end → b = expr; a = if cond(b) do ... else b end
 *
 * WHY
 * - Haxe double-assignment lowers to chained matches that are hard to read and break snapshot shapes.
 *   This normalization restores the intended assignment to `a` based on the conditional.
 *
 * HOW
 * - Walk EFn clause bodies under ERemoteCall(Enum, "reduce_while", ...); for each EBlock, search windows
 *   for `a = (b = rhs)` followed by an EIf whose else branch is `b`, and rewrite to two statements,
 *   dropping the standalone if.
 */
class ReduceWhileIfAssignmentNormalizeTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ERemoteCall(module, "reduce_while", args) if (args != null && args.length >= 3):
          #if debug_reduce_while Sys.println('[ReduceWhileNormalize] Visiting Enum.reduce_while(...)'); #end
          var collection = args[0];
          var init = args[1];
          var fnArg = args[2];
          switch (fnArg.def) {
            case EFn(clauses):
              var outClauses = [];
              for (cl in clauses) {
                #if debug_reduce_while Sys.println('[ReduceWhileNormalize]   Clause body before = ' + ElixirASTPrinter.print(cl.body, 0)); #end
                var nb = normalizeBlock(cl.body);
                #if debug_reduce_while Sys.println('[ReduceWhileNormalize]   Clause body after  = ' + ElixirASTPrinter.print(nb, 0)); #end
                outClauses.push({ args: cl.args, guard: cl.guard, body: nb });
              }
              makeASTWithMeta(ERemoteCall(module, "reduce_while", [collection, init, makeAST(EFn(outClauses))]), n.metadata, n.pos);
            default:
              n;
          }
        // Global fallback: apply the same window normalization in any anonymous fn bodies
        case EFn(clauses):
          #if debug_reduce_while Sys.println('[ReduceWhileNormalize] Visiting generic EFn with ' + clauses.length + ' clause(s)'); #end
          var outClauses = [];
          for (cl in clauses) {
            #if debug_reduce_while Sys.println('[ReduceWhileNormalize]   (generic) body before = ' + ElixirASTPrinter.print(cl.body, 0)); #end
            var normalizedBody = normalizeBlock(cl.body);
            #if debug_reduce_while Sys.println('[ReduceWhileNormalize]   (generic) body after  = ' + ElixirASTPrinter.print(normalizedBody, 0)); #end
            outClauses.push({ args: cl.args, guard: cl.guard, body: normalizedBody });
          }
          makeASTWithMeta(EFn(outClauses), n.metadata, n.pos);
        default:
          // Also run over plain blocks to catch top-level windows
          switch (n.def) {
            case EBlock(_): normalizeBlock(n);
            default: n;
          }
      }
    });
  }

  static function normalizeBlock(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        var out:Array<ElixirAST> = [];
        var i = 0;
        while (i < stmts.length) {
          var s = stmts[i];
          var rewritten = false;
          switch (s.def) {
            case EBinary(Match, {def: EVar(a)}, {def: EBinary(Match, {def: EVar(b)}, rhs)}):
              #if debug_reduce_while Sys.println('[ReduceWhileNormalize]   Found double-assign window: ' + a + ' = (' + b + ' = <rhs>)'); #end
              var j = i + 1;
              while (j < stmts.length && j <= i + 3) {
                switch (stmts[j].def) {
                  case EIf(cond, thenE, elseE) if (elseE != null):
                    var elseIsB = switch (elseE.def) { case EVar(bb) if (bb == b): true; default: false; };
                    if (elseIsB) {
                      #if debug_reduce_while Sys.println('[ReduceWhileNormalize]   Matched trailing if ... else ' + b + ' → rewriting to b = rhs; ' + a + ' = if ...'); #end
                      // Emit: b = rhs; a = if ...
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b), s.metadata, s.pos), rhs), s.metadata, s.pos));
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EIf(cond, thenE, elseE), stmts[j].metadata, stmts[j].pos)), s.metadata, s.pos));
                      // Copy any non-if statements in between
                      for (k in i + 1...j) out.push(stmts[k]);
                      i = j + 1;
                      rewritten = true;
                    }
                  default:
                }
                if (rewritten) break;
                j++;
              }
            // Additional shapes: EMatch-based variants
            case EMatch(PVar(aM), {def: EBinary(Match, {def: EVar(bM)}, rhsM)}):
              var scanIndexSecondary = i + 1;
              while (scanIndexSecondary < stmts.length && scanIndexSecondary <= i + 3) {
                switch (stmts[scanIndexSecondary].def) {
                  case EIf(condM, thenM, elseM) if (elseM != null):
                    var elseIsBM = switch (elseM.def) { case EVar(bbM) if (bbM == bM): true; default: false; };
                    if (elseIsBM) {
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bM), s.metadata, s.pos), rhsM), s.metadata, s.pos));
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aM), s.metadata, s.pos), makeASTWithMeta(EIf(condM, thenM, elseM), stmts[scanIndexSecondary].metadata, stmts[scanIndexSecondary].pos)), s.metadata, s.pos));
                      for (k2 in i + 1...scanIndexSecondary) out.push(stmts[k2]);
                      i = scanIndexSecondary + 1; rewritten = true;
                    }
                  default:
                }
                if (rewritten) break;
                scanIndexSecondary++;
              }
            case EMatch(PVar(lhsName), {def: EMatch(PVar(rhsBinder), rhsValue)}):
              var scanIndexTertiary = i + 1;
              while (scanIndexTertiary < stmts.length && scanIndexTertiary <= i + 3) {
                switch (stmts[scanIndexTertiary].def) {
                  case EIf(nestedCond, nestedThen, nestedElse) if (nestedElse != null):
                    var elseReturnsBinder = switch (nestedElse.def) { case EVar(binderName) if (binderName == rhsBinder): true; default: false; };
                    if (elseReturnsBinder) {
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(rhsBinder), s.metadata, s.pos), rhsValue), s.metadata, s.pos));
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(lhsName), s.metadata, s.pos), makeASTWithMeta(EIf(nestedCond, nestedThen, nestedElse), stmts[scanIndexTertiary].metadata, stmts[scanIndexTertiary].pos)), s.metadata, s.pos));
                      for (k3 in i + 1...scanIndexTertiary) out.push(stmts[k3]);
                      i = scanIndexTertiary + 1; rewritten = true;
                    }
                  default:
                }
                if (rewritten) break;
                scanIndexTertiary++;
              }
            default:
          }
          if (!rewritten) {
            out.push(s);
            i++;
          }
        }
        makeASTWithMeta(EBlock(out), body.metadata, body.pos);
      default:
        body;
    }
  }
}

#end
