package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * NormalizeBlankMatchLhsToUnderscoreTransforms
 *
 * WHAT
 * - Ensures any `=` match with an empty/blank variable on the LHS is normalized to `_`.
 *
 * WHY
 * - Defensive hygiene: rare rename/order interactions can leave the match LHS with an
 *   empty identifier, which prints as ` = rhs` (invalid). Normalizing to `_` preserves
 *   intent (discard) and restores valid syntax.
 */
class NormalizeBlankMatchLhsToUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(Match, left, right):
          var fixedLeft = switch (left.def) {
            case EVar(name) if (name == null || name.length == 0): makeASTWithMeta(EVar("_"), left.metadata, left.pos);
            default:
              // Fallback using printer: if LHS would render empty/whitespace, normalize to `_`
              var printed = ElixirASTPrinter.printAST(left);
              if (printed == null || StringTools.trim(printed).length == 0) makeASTWithMeta(EVar("_"), left.metadata, left.pos) else left;
          };
          if (fixedLeft != left) makeASTWithMeta(EBinary(Match, fixedLeft, right), n.metadata, n.pos) else n;
        case EMatch(pat, rhs):
          var fixedPat = switch (pat) {
            case PVar(name) if (name == null || name.length == 0): PVar("_");
            default: pat;
          };
          if (fixedPat != pat) makeASTWithMeta(EMatch(fixedPat, rhs), n.metadata, n.pos) else n;
        default:
          n;
      }
    });
  }
}

#end
