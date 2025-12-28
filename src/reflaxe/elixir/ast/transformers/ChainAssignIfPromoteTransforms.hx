package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ChainAssignIfPromoteTransforms
 *
 * WHAT
 * - Promotes chained assignment followed by an if expression into two linear assignments:
 *   a = (b = rhs);
 *   if cond(b) do ... else b end
 *   →
 *   b = rhs;
 *   a = if cond(b) do ... else b end
 *
 * WHY
 * - Improves readability and matches expected snapshot shapes in loop/reduce_while bodies.
 * - Generic, shape-based; no app coupling or name heuristics.
 *
 * HOW
 * - Scan EBlock/EDo statements; when statement[i] is a=(b=rhs) and statement[i+1] is an EIf
 *   whose else branch is exactly `b`, rewrite as above. Handles both EBinary/EMatch on outer assign.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ChainAssignIfPromoteTransforms {
  static function unwrapChain(e: ElixirAST): Null<{outer:String, inner:String, rhs:ElixirAST}> {
    if (e == null || e.def == null) return null;
    return switch (e.def) {
      case EBinary(Match, {def: EVar(b)}, rhs): {outer: null, inner: b, rhs: rhs};
      case EMatch(PVar(bp), rhsP): {outer: null, inner: bp, rhs: rhsP};
      case EParen(inner): unwrapChain(inner);
      case EBlock(es) if (es.length == 1): unwrapChain(es[0]);
      default: null;
    }
  }

  static inline function isElseVar(elseE: ElixirAST, name: String): Bool {
    return switch (elseE.def) { case EVar(v) if (v == name): true; default: false; };
  }

  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EFn(clauses):
          var newClauses = [];
          for (cl in clauses) {
            var nb = transformPass(cl.body);
            newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
          }
          makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
        case EBlock(stmts):
          var out:Array<ElixirAST> = [];
          var i = 0;
          while (i < stmts.length) {
            var s = stmts[i];
            var consumed = false;
            // EBinary outer: a = (b = rhs)
            switch (s.def) {
              case EBinary(Match, {def: EVar(a)}, rhsAny):
                var ch = unwrapChain(rhsAny);
                if (ch != null && ch.inner != null && ch.rhs != null && i + 1 < stmts.length) {
                  switch (stmts[i + 1].def) {
                    case EIf(cond, thenE, elseE) if (isElseVar(elseE, ch.inner)):
                      // debug removed
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(ch.inner), s.metadata, s.pos), ch.rhs), s.metadata, s.pos));
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EIf(cond, thenE, elseE), stmts[i + 1].metadata, stmts[i + 1].pos)), s.metadata, s.pos));
                      i += 2; consumed = true;
                    default:
                  }
                }
              case EMatch(PVar(a2), rhsAny2):
                if (!consumed) {
                  var ch2 = unwrapChain(rhsAny2);
                  if (ch2 != null && ch2.inner != null && ch2.rhs != null && i + 1 < stmts.length) {
                    switch (stmts[i + 1].def) {
                      case EIf(cond2, thenE2, elseE2) if (isElseVar(elseE2, ch2.inner)):
                        // debug removed
                        out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(ch2.inner), s.metadata, s.pos), ch2.rhs), s.metadata, s.pos));
                        out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), s.metadata, s.pos), makeASTWithMeta(EIf(cond2, thenE2, elseE2), stmts[i + 1].metadata, stmts[i + 1].pos)), s.metadata, s.pos));
                        i += 2; consumed = true;
                      default:
                    }
                  }
                }
              default:
            }
            if (!consumed) { out.push(s); i++; }
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          var j = 0;
          while (j < stmts2.length) {
            var s2 = stmts2[j];
            var consumed2 = false;
            switch (s2.def) {
              case EBinary(Match, {def: EVar(a3)}, rhsAny3):
                var ch3 = unwrapChain(rhsAny3);
                if (ch3 != null && ch3.inner != null && ch3.rhs != null && j + 1 < stmts2.length) {
                  switch (stmts2[j + 1].def) {
                    case EIf(cond3, thenE3, elseE3) if (isElseVar(elseE3, ch3.inner)):
                      // debug removed
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(ch3.inner), s2.metadata, s2.pos), ch3.rhs), s2.metadata, s2.pos));
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a3), s2.metadata, s2.pos), makeASTWithMeta(EIf(cond3, thenE3, elseE3), stmts2[j + 1].metadata, stmts2[j + 1].pos)), s2.metadata, s2.pos));
                      j += 2; consumed2 = true;
                    default:
                  }
                }
              case EMatch(PVar(a4), rhsAny4):
                if (!consumed2) {
                  var ch4 = unwrapChain(rhsAny4);
                  if (ch4 != null && ch4.inner != null && ch4.rhs != null && j + 1 < stmts2.length) {
                    switch (stmts2[j + 1].def) {
                      case EIf(cond4, thenE4, elseE4) if (isElseVar(elseE4, ch4.inner)):
                        // debug removed
                        out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(ch4.inner), s2.metadata, s2.pos), ch4.rhs), s2.metadata, s2.pos));
                        out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a4), s2.metadata, s2.pos), makeASTWithMeta(EIf(cond4, thenE4, elseE4), stmts2[j + 1].metadata, stmts2[j + 1].pos)), s2.metadata, s2.pos));
                        j += 2; consumed2 = true;
                      default:
                    }
                  }
                }
              default:
            }
            if (!consumed2) { out2.push(s2); j++; }
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
