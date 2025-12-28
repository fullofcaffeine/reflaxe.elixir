package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignIfFoldInRhsTransforms
 *
 * WHAT
 * - Statement-context fold for the pattern where an assignment's RHS is a two‑statement
 *   block consisting of an immediate assignment followed by an if whose else returns
 *   that assigned variable:
 *
 *   a = (do
 *     b = rhs
 *     if cond do ... else b end
 *   end)
 *
 *   →
 *
 *   b = rhs
 *   a = if cond do ... else b end
 *
 * WHY
 * - Earlier extraction passes may materialize small blocks inside assignment RHS in
 *   statement positions (case arms, function bodies). Leaving the block inline reduces
 *   readability and can interact poorly with downstream reshapes (e.g., switch/pattern
 *   side‑effect snapshots). This fold restores a clean, linear sequence without changing
 *   semantics. It is strictly shape‑based and target‑agnostic.
 *
 * HOW
 * - Runs over EBlock/EDo statement lists. When a statement is an assignment (either
 *   EBinary(Match, EVar(lhs), ...) or EMatch(PVar(lhs), ...)) whose RHS is an EBlock/EDo
 *   of exactly two statements [bind, if] and:
 *     bind ≡ (EVar|PVar)(b) = rhs
 *     if   ≡ EIf(_, _, else) with else ≡ EVar(b)
 *   then rewrite that single statement into two statements as above, preserving metadata.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class AssignIfFoldInRhsTransforms {
  static inline function rhsIsTwoStmtBlock(e: ElixirAST): Null<{first: ElixirAST, second: ElixirAST, ctor:String}> {
    if (e == null || e.def == null) return null;
    return switch (e.def) {
      case EBlock(stmts) if (stmts.length == 2): { first: stmts[0], second: stmts[1], ctor: "EBlock" };
      case EDo(stmts)    if (stmts.length == 2): { first: stmts[0], second: stmts[1], ctor: "EDo" };
      case EParen(inner): rhsIsTwoStmtBlock(inner);
      default: null;
    }
  }

  static inline function bindNameAndRhs(s: ElixirAST): Null<{name:String, rhs:ElixirAST}> {
    return switch (s.def) {
      case EBinary(Match, {def: EVar(n)}, r): { name: n, rhs: r };
      case EMatch(PVar(n), r): { name: n, rhs: r };
      default: null;
    }
  }

  static inline function elseReturnsVar(e: ElixirAST, name: String): Bool {
    return switch (e.def) { case EVar(v) if (v == name): true; default: false; };
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
            var rewritten = false;
            switch (s.def) {
              case EBinary(Match, left, rhs):
                var two = rhsIsTwoStmtBlock(rhs);
                if (two != null) {
                  var b = bindNameAndRhs(two.first);
                  switch (two.second.def) {
                    case EIf(cond, thenE, elseE) if (b != null && elseReturnsVar(elseE, b.name)):
                      // Emit: b = rhs; lhs = if ... end
                      out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b.name), two.first.metadata, two.first.pos), b.rhs), two.first.metadata, two.first.pos));
                      out.push(makeASTWithMeta(EBinary(Match, left, makeASTWithMeta(EIf(cond, thenE, elseE), two.second.metadata, two.second.pos)), s.metadata, s.pos));
                      rewritten = true;
                    default:
                  }
                }
              case EMatch(pat, rhs2):
                if (!rewritten) {
                  var two2 = rhsIsTwoStmtBlock(rhs2);
                  if (two2 != null) {
                    var b2 = bindNameAndRhs(two2.first);
                    switch (two2.second.def) {
                      case EIf(cond2, thenE2, elseE2) if (b2 != null && elseReturnsVar(elseE2, b2.name)):
                        // Emit: b = rhs; lhs = if ... end (preserve EMatch outer form)
                        out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b2.name), two2.first.metadata, two2.first.pos), b2.rhs), two2.first.metadata, two2.first.pos));
                        out.push(makeASTWithMeta(EMatch(pat, makeASTWithMeta(EIf(cond2, thenE2, elseE2), two2.second.metadata, two2.second.pos)), s.metadata, s.pos));
                        rewritten = true;
                      default:
                    }
                  }
                }
              default:
            }
            if (!rewritten) out.push(s);
            i++;
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);

        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          for (s2 in stmts2) {
            var done = false;
            switch (s2.def) {
              case EBinary(Match, left2, rhsX):
                var tw = rhsIsTwoStmtBlock(rhsX);
                if (tw != null) {
                  var bX = bindNameAndRhs(tw.first);
                  switch (tw.second.def) {
                    case EIf(condX, thenX, elseX) if (bX != null && elseReturnsVar(elseX, bX.name)):
                      out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bX.name), tw.first.metadata, tw.first.pos), bX.rhs), tw.first.metadata, tw.first.pos));
                      out2.push(makeASTWithMeta(EBinary(Match, left2, makeASTWithMeta(EIf(condX, thenX, elseX), tw.second.metadata, tw.second.pos)), s2.metadata, s2.pos));
                      done = true;
                    default:
                  }
                }
              case EMatch(p2, rhsY):
                if (!done) {
                  var tw2 = rhsIsTwoStmtBlock(rhsY);
                  if (tw2 != null) {
                    var bY = bindNameAndRhs(tw2.first);
                    switch (tw2.second.def) {
                      case EIf(condY, thenY, elseY) if (bY != null && elseReturnsVar(elseY, bY.name)):
                        out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bY.name), tw2.first.metadata, tw2.first.pos), bY.rhs), tw2.first.metadata, tw2.first.pos));
                        out2.push(makeASTWithMeta(EMatch(p2, makeASTWithMeta(EIf(condY, thenY, elseY), tw2.second.metadata, tw2.second.pos)), s2.metadata, s2.pos));
                        done = true;
                      default:
                    }
                  }
                }
              default:
            }
            if (!done) out2.push(s2);
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);

        default:
          n;
      }
    });
  }
}

#end
