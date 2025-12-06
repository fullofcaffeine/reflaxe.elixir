package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseUnderscoreCaseHoistBlockTransforms
 *
 * WHAT
 * - Within EBlock bodies, rewrites `_ = case <call> do ... end` into two statements:
 *   `parsed_result = <call>` and `case parsed_result do ... end`.
 *
 * WHY
 * - Snapshot style prefers a named scrutinee variable over discarding the assignment.
 * - Keeps changes generic and shape-based without coupling to app code.
 */
class CaseUnderscoreCaseHoistBlockTransforms {
  static inline function isDiscardPattern(p: EPattern): Bool {
    return switch (p) {
      case PVar(name) if (name == "_"): true;
      case PWildcard: true;
      case PPin(inner): isDiscardPattern(inner);
      default: false;
    }
  }
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts):
          var out:Array<ElixirAST> = [];
          for (i in 0...stmts.length) {
            var s = stmts[i];
            // Recursively transform nested blocks first so inner `_ = case` becomes visible here
            s = transformPass(s);
            var hoisted = false;
            switch (s.def) {
              case EMatch(pat, {def: ECase(scrut, clauses)}) if (isDiscardPattern(pat)):
                var assign = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("parsed_result"), s.metadata, s.pos), scrut), s.metadata, s.pos);
                var caze = makeASTWithMeta(ECase(makeASTWithMeta(EVar("parsed_result"), s.metadata, s.pos), clauses), s.metadata, s.pos);
                out.push(assign);
                out.push(caze);
                hoisted = true;
              case EBinary(Match, {def: EVar("_")}, {def: ECase(scr2, cls2)}):
                var assign2 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("parsed_result"), s.metadata, s.pos), scr2), s.metadata, s.pos);
                var caze2 = makeASTWithMeta(ECase(makeASTWithMeta(EVar("parsed_result"), s.metadata, s.pos), cls2), s.metadata, s.pos);
                out.push(assign2);
                out.push(caze2);
                hoisted = true;
              default:
            }
            #if debug_case_hoist if (!hoisted) {
              var extra = switch (s.def) {
                case EMatch(pat0, rhs): ' (lhsPattern=' + Type.enumConstructor(pat0) + ', rhs=' + Type.enumConstructor(rhs.def) + ')';
                default: '';
              };
              // DEBUG: Sys.println('[CaseUnderscoreCaseHoist] No match for stmt[' + i + '] kind=' + Type.enumConstructor(s.def) + extra + ' = ' + ElixirASTPrinter.print(s, 0));
            } #end
            if (!hoisted) out.push(s);
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          for (i2 in 0...stmts2.length) {
            var s2 = stmts2[i2];
            s2 = transformPass(s2);
            var hoisted2 = false;
            switch (s2.def) {
              case EMatch(p3, {def: ECase(scr3, cls3)}) if (isDiscardPattern(p3)):
                var assign3 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("parsed_result"), s2.metadata, s2.pos), scr3), s2.metadata, s2.pos);
                var caze3 = makeASTWithMeta(ECase(makeASTWithMeta(EVar("parsed_result"), s2.metadata, s2.pos), cls3), s2.metadata, s2.pos);
                out2.push(assign3);
                out2.push(caze3);
                hoisted2 = true;
              case EBinary(Match, {def: EVar("_")}, {def: ECase(scr4, cls4)}):
                var assign4 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("parsed_result"), s2.metadata, s2.pos), scr4), s2.metadata, s2.pos);
                var caze4 = makeASTWithMeta(ECase(makeASTWithMeta(EVar("parsed_result"), s2.metadata, s2.pos), cls4), s2.metadata, s2.pos);
                out2.push(assign4);
                out2.push(caze4);
                hoisted2 = true;
              default:
            }
            if (!hoisted2) out2.push(s2);
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
