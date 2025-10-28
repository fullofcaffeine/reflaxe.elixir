package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * CaseScrutineeHoistTransforms
 *
 * WHAT
 * - Hoists `case parse_* (args) do ... end` into a local binding followed by `case var do`.
 *
 * WHY
 * - Improves readability and matches common patterns for parsing flows:
 *   parsed_result = parse_*(...)
 *   case parsed_result do ... end
 * - Generic, shape-based, and limited to `parse_*` scrutinees to avoid broad rewrites.
 *
 * HOW
 * - Detect EMatch(PVar("_"), ECase(ECall/ERemoteCall parse_* ...)) and rewrite to:
 *   EBlock([ EBinary(Match, EVar("parsed_result"), scrutinee), ECase(EVar("parsed_result"), clauses) ])
 */
class CaseScrutineeHoistTransforms {
  static inline function isParseCall(e: ElixirAST): Bool {
    // Generic: any direct function call (local or remote) qualifies as a scrutinee hoist candidate
    // when the result is immediately switched on and the outer assignment discards it ("_").
    return switch (e.def) {
      case ECall(_, _, _): true;
      case ERemoteCall(_, _, _): true;
      default: false;
    }
  }

  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        // Pattern: _ = case parse_*(...) do ... end
        case EMatch(PVar("_"), {def: ECase(scrut, clauses)}):
          if (isParseCall(scrut)) {
            #if debug_case_hoist Sys.println('[CaseScrutineeHoist] Hoisting scrutinee to parsed_result (EMatch)'); #end
            var varName = "parsed_result";
            var assign = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(varName), n.metadata, n.pos), scrut), n.metadata, n.pos);
            var caze = makeASTWithMeta(ECase(makeASTWithMeta(EVar(varName), n.metadata, n.pos), clauses), n.metadata, n.pos);
            makeASTWithMeta(EBlock([assign, caze]), n.metadata, n.pos);
          } else n;
        // Pattern: _ =^ EBinary(Match, EVar("_"), ECase(scrut, clauses)) — simple assignment
        case EBinary(Match, {def: EVar("_")}, {def: ECase(scrut2, clauses2)}):
          if (isParseCall(scrut2)) {
            #if debug_case_hoist Sys.println('[CaseScrutineeHoist] Hoisting scrutinee to parsed_result (EBinary)'); #end
            var varName2 = "parsed_result";
            var assign2 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(varName2), n.metadata, n.pos), scrut2), n.metadata, n.pos);
            var caze2 = makeASTWithMeta(ECase(makeASTWithMeta(EVar(varName2), n.metadata, n.pos), clauses2), n.metadata, n.pos);
            makeASTWithMeta(EBlock([assign2, caze2]), n.metadata, n.pos);
          } else n;
        default:
          n;
      }
    });
  }
}

#end
