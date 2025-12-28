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

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseScrutineeHoistInAssignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs):
          var rhsCaseInfo: Null<{scrut:ElixirAST, clauses:Array<ECaseClause>}> = switch (rhs.def) {
            case ECase(caseScrutinee, caseClauses): {scrut: caseScrutinee, clauses: caseClauses};
            case EParen({def: ECase(parenScrutinee, parenClauses)}): {scrut: parenScrutinee, clauses: parenClauses};
            default: null;
          };
          if (rhsCaseInfo == null) n else {
            var caseScrutinee = rhsCaseInfo.scrut;
            var caseClauses = rhsCaseInfo.clauses;
          var scrutineeIsListOrBinary = switch (caseScrutinee.def) { case EList(_) | EBitstring(_): true; default: false; };
          if (!scrutineeIsListOrBinary) n else {
            var hoistedVarName = (switch (caseScrutinee.def) { case EBitstring(_): "bin_value"; default: "list_value"; });
            var assignHoisted = makeASTWithMeta(EBinary(Match, makeAST(EVar(hoistedVarName)), caseScrutinee), n.metadata, n.pos);
            var repairedClauses = CaseListScrutineeHoistTransforms.rewriteGuardsToListVar(caseClauses, hoistedVarName);
            var assignToLhs = makeASTWithMeta(EBinary(Match, makeAST(EVar(lhs)), makeAST(ECase(makeAST(EVar(hoistedVarName)), repairedClauses))), n.metadata, n.pos);
            makeASTWithMeta(EBlock([assignHoisted, assignToLhs]), n.metadata, n.pos);
          }
          }
        case EMatch(PVar(lhsName), rhsMatched):
          var rhsCaseInfoInner: Null<{scrut:ElixirAST, clauses:Array<ECaseClause>}> = switch (rhsMatched.def) {
            case ECase(caseScrutineeInner, caseClausesInner): {scrut: caseScrutineeInner, clauses: caseClausesInner};
            case EParen({def: ECase(parenScrutineeInner, parenClausesInner)}): {scrut: parenScrutineeInner, clauses: parenClausesInner};
            default: null;
          };
          if (rhsCaseInfoInner == null) n else {
            var caseScrutineeInner = rhsCaseInfoInner.scrut;
            var caseClausesInner = rhsCaseInfoInner.clauses;
          var scrutineeIsListOrBinaryInner = switch (caseScrutineeInner.def) { case EList(_) | EBitstring(_): true; default: false; };
          if (!scrutineeIsListOrBinaryInner) n else {
            var hoistedVarNameInner = (switch (caseScrutineeInner.def) { case EBitstring(_): "bin_value"; default: "list_value"; });
            var assignHoistedInner = makeASTWithMeta(EBinary(Match, makeAST(EVar(hoistedVarNameInner)), caseScrutineeInner), n.metadata, n.pos);
            var repairedClausesInner = CaseListScrutineeHoistTransforms.rewriteGuardsToListVar(caseClausesInner, hoistedVarNameInner);
            var assignToLhsInner = makeASTWithMeta(EBinary(Match, makeAST(EVar(lhsName)), makeAST(ECase(makeAST(EVar(hoistedVarNameInner)), repairedClausesInner))), n.metadata, n.pos);
            makeASTWithMeta(EBlock([assignHoistedInner, assignToLhsInner]), n.metadata, n.pos);
          }
          }
        default:
          n;
      }
    });
  }
}

#end
