package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseScrutineeHoistInAssignTransforms
 *
 * WHAT
 * - When a case expression with a non-variable list/bitstring scrutinee appears
 *   on the RHS of an assignment (var = case scrutinee do ... end), hoist the
 *   scrutinee to a local variable before the assignment, then case on it.
 *
 * WHY
 * - Hoisting enables subsequent list-pattern and guard repairs while keeping the
 *   assignment expression valid in Elixir (no raw multi-statement RHS).
 *
 * HOW
 * - Match EBinary(Match, EVar(lhs), ECase(scrutinee, clauses)). If scrutinee is
 *   EList/EBitstring, emit:
 *     list_value = scrutinee
 *     lhs = case list_value do ... end
 */
class CaseScrutineeHoistInAssignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs):
          var rhsCase: Null<{scrut:ElixirAST, clauses:Array<ECaseClause>}> = switch (rhs.def) {
            case ECase(s, cs): {scrut: s, clauses: cs};
            case EParen({def: ECase(s2, cs2)}): {scrut: s2, clauses: cs2};
            default: null;
          };
          if (rhsCase == null) n else {
            var scrutinee = rhsCase.scrut;
            var clauses = rhsCase.clauses;
          var needs = switch (scrutinee.def) { case EList(_) | EBitstring(_): true; default: false; };
          if (!needs) n else {
            var tmp = (switch (scrutinee.def) { case EBitstring(_): "bin_value"; default: "list_value"; });
            var assignTmp = makeASTWithMeta(EBinary(Match, makeAST(EVar(tmp)), scrutinee), n.metadata, n.pos);
            var repairedClauses = CaseListScrutineeHoistTransforms.rewriteGuardsToListVar(clauses, tmp);
            var assignLhs = makeASTWithMeta(EBinary(Match, makeAST(EVar(lhs)), makeAST(ECase(makeAST(EVar(tmp)), repairedClauses))), n.metadata, n.pos);
            makeASTWithMeta(EBlock([assignTmp, assignLhs]), n.metadata, n.pos);
          }
          }
        case EMatch(PVar(lhs2), rhs2):
          var rhsCase2: Null<{scrut:ElixirAST, clauses:Array<ECaseClause>}> = switch (rhs2.def) {
            case ECase(s3, cs3): {scrut: s3, clauses: cs3};
            case EParen({def: ECase(s4, cs4)}): {scrut: s4, clauses: cs4};
            default: null;
          };
          if (rhsCase2 == null) n else {
            var scrutinee2 = rhsCase2.scrut;
            var clauses2 = rhsCase2.clauses;
          var needs2 = switch (scrutinee2.def) { case EList(_) | EBitstring(_): true; default: false; };
          if (!needs2) n else {
            var tmp2 = (switch (scrutinee2.def) { case EBitstring(_): "bin_value"; default: "list_value"; });
            var assignTmp2 = makeASTWithMeta(EBinary(Match, makeAST(EVar(tmp2)), scrutinee2), n.metadata, n.pos);
            var repairedClauses2 = CaseListScrutineeHoistTransforms.rewriteGuardsToListVar(clauses2, tmp2);
            var assignLhs2 = makeASTWithMeta(EBinary(Match, makeAST(EVar(lhs2)), makeAST(ECase(makeAST(EVar(tmp2)), repairedClauses2))), n.metadata, n.pos);
            makeASTWithMeta(EBlock([assignTmp2, assignLhs2]), n.metadata, n.pos);
          }
          }
        default:
          n;
      }
    });
  }
}

#end
