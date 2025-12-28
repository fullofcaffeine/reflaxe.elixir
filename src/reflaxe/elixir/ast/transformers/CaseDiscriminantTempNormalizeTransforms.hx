package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseDiscriminantTempNormalizeTransforms
 *
 * WHAT
 * - Normalizes case discriminant variable usage to match the most recent nearby
 *   assignment when only a leading underscore differs (e.g., `g` vs `_g`).
 *
 * WHY
 * - Hygiene passes may underscore a temp variable in references while the assignment
 *   was emitted without the underscore (or vice versa), yielding `g = ...; case _g do`.
 *   This produces undefined-variable errors.
 *
 * HOW
 * - In an EBlock context, when a statement `lhs = ...` or `lhs <- ...` is immediately
 *   followed by `case var do ... end` where `var` equals `lhs` modulo a single leading
 *   underscore, rewrite the case discriminant to use `lhs` exactly.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseDiscriminantTempNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts) if (stmts.length >= 2):
          var out:Array<ElixirAST> = [];
          for (i in 0...stmts.length) {
            var cur = stmts[i];
            // Try to fix case targets that mismatch nearest prior assignment modulo underscore
            function nearestLhsFor(targetVar:String): Null<String> {
              var k = i - 1;
              while (k >= 0) {
                switch (out[k].def) {
                  case EBinary(Match, leftK, _):
                    switch (leftK.def) { case EVar(nm): if (equalModuloLeadingUnderscore(targetVar, nm)) return nm; default: }
                  case EMatch(patK, _):
                    switch (patK) { case PVar(nmk): if (equalModuloLeadingUnderscore(targetVar, nmk)) return nmk; default: }
                  default:
                }
                k--;
              }
              return null;
            }
            var replaced: Null<ElixirAST> = null;
            switch (cur.def) {
              case ECase(tgt, cls):
                switch (tgt.def) { case EVar(tv): var lhs = nearestLhsFor(tv); if (lhs != null) replaced = makeASTWithMeta(ECase(makeAST(EVar(lhs)), cls), cur.metadata, cur.pos); default: }
              case EParen(inner):
                switch (inner.def) { case ECase(tgt2, cls2): switch (tgt2.def) { case EVar(tv2): var lhs2 = nearestLhsFor(tv2); if (lhs2 != null) replaced = makeASTWithMeta(EParen(makeAST(ECase(makeAST(EVar(lhs2)), cls2))), cur.metadata, cur.pos); default: } default: }
              case EBinary(Match, leftN, rhsN):
                switch (rhsN.def) { case ECase(tN, csN): switch (tN.def) { case EVar(tvN): var lhsN = nearestLhsFor(tvN); if (lhsN != null) { var newR = makeASTWithMeta(ECase(makeAST(EVar(lhsN)), csN), rhsN.metadata, rhsN.pos); replaced = makeASTWithMeta(EBinary(Match, leftN, newR), cur.metadata, cur.pos); } default: } default: }
              case EMatch(patM, rhsM):
                switch (rhsM.def) { case ECase(tM, csM): switch (tM.def) { case EVar(tvM): var lhsM = nearestLhsFor(tvM); if (lhsM != null) { var newR2 = makeASTWithMeta(ECase(makeAST(EVar(lhsM)), csM), rhsM.metadata, rhsM.pos); replaced = makeASTWithMeta(EMatch(patM, newR2), cur.metadata, cur.pos); } default: } default: }
              default:
            }
            out.push(replaced != null ? replaced : cur);
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2) if (stmts2.length >= 2):
          // Mirror logic for do-blocks inside closures
          var out2:Array<ElixirAST> = [];
          for (j in 0...stmts2.length) {
            var cur2 = stmts2[j];
            function nearestLhs2(targetVar:String): Null<String> {
              var k2 = j - 1;
              while (k2 >= 0) {
                switch (out2[k2].def) {
                  case EBinary(Match, l2, _): switch (l2.def) { case EVar(nm): if (equalModuloLeadingUnderscore(targetVar, nm)) return nm; default: }
                  case EMatch(p2, _): switch (p2) { case PVar(nm2): if (equalModuloLeadingUnderscore(targetVar, nm2)) return nm2; default: }
                  default:
                }
                k2--;
              }
              return null;
            }
            var rep2: Null<ElixirAST> = null;
            switch (cur2.def) {
              case ECase(t2, c2): switch (t2.def) { case EVar(tv): var lhs = nearestLhs2(tv); if (lhs != null) rep2 = makeASTWithMeta(ECase(makeAST(EVar(lhs)), c2), cur2.metadata, cur2.pos); default: }
              case EParen(in2): switch (in2.def) { case ECase(tt, cc): switch (tt.def) { case EVar(tv3): var lhs3 = nearestLhs2(tv3); if (lhs3 != null) rep2 = makeASTWithMeta(EParen(makeAST(ECase(makeAST(EVar(lhs3)), cc))), cur2.metadata, cur2.pos); default: } default: }
              case EBinary(Match, lN, rN): switch (rN.def) { case ECase(tN2, csN2): switch (tN2.def) { case EVar(tvn): var lhn = nearestLhs2(tvn); if (lhn != null) { var nr = makeASTWithMeta(ECase(makeAST(EVar(lhn)), csN2), rN.metadata, rN.pos); rep2 = makeASTWithMeta(EBinary(Match, lN, nr), cur2.metadata, cur2.pos); } default: } default: }
              case EMatch(pN2, rN2): switch (rN2.def) { case ECase(tM2, csM2): switch (tM2.def) { case EVar(tvM2): var lhm2 = nearestLhs2(tvM2); if (lhm2 != null) { var nr2 = makeASTWithMeta(ECase(makeAST(EVar(lhm2)), csM2), rN2.metadata, rN2.pos); rep2 = makeASTWithMeta(EMatch(pN2, nr2), cur2.metadata, cur2.pos); } default: } default: }
              default:
            }
            out2.push(rep2 != null ? rep2 : cur2);
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function equalModuloLeadingUnderscore(a:String, b:String): Bool {
    if (a == b) return true;
    var a2 = (a != null && a.length > 0 && a.charAt(0) == "_") ? a.substr(1) : a;
    var b2 = (b != null && b.length > 0 && b.charAt(0) == "_") ? b.substr(1) : b;
    return a2 == b2;
  }
}

#end
