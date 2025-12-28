package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ConcatListLiteralNormalizeTransforms
 *
 * WHAT
 * - Normalizes match expressions whose RHS is a nested wildcard/alias match to an
 *   empty-list concatenation with a singleton list into a direct list literal.
 *
 * WHY
 * - Desugared comprehensions and nested list constructions can leave shapes like:
 *     data = _ = [] ++ [expr]
 *   This is valid but non-idiomatic and obstructs later comprehension reconstruction.
 *   Rewriting it to `data = [expr]` preserves semantics and yields a clean AST.
 *
 * HOW
 * - For any EBinary(Match, left, EBinary(Match, _, EBinary(Concat, EList([]), EList([elem]))))
 *   rewrite to EBinary(Match, left, EList([elem])).
 * - Also handle the variant without the inner match: EBinary(Match, left, EBinary(Concat, EList([]), EList([elem]))).

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ConcatListLiteralNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        // data = _ = [] ++ [expr]  →  data = [expr]
        case EBinary(Match, left, {def: EBinary(Match, _innerLeft, innerRhs)}):
          switch (innerRhs.def) {
            case EBinary(Concat, {def: EList(empty)} , {def: EList(single)}) if (empty != null && empty.length == 0 && single != null && single.length == 1):
              makeASTWithMeta(EBinary(Match, left, makeASTWithMeta(EList(single), n.metadata, n.pos)), n.metadata, n.pos);
            default:
              n;
          }
        // data = [] ++ [expr]  →  data = [expr]
        case EBinary(Match, left, {def: EBinary(Concat, {def: EList(empty)}, {def: EList(single)})}) if (empty != null && empty.length == 0 && single != null && single.length == 1):
          makeASTWithMeta(EBinary(Match, left, makeASTWithMeta(EList(single), n.metadata, n.pos)), n.metadata, n.pos);
        // _ = [] ++ [expr] → _ = [expr]
        case EMatch(PWildcard, {def: EBinary(Concat, {def: EList(empty2)}, {def: EList(single2)})}) if (empty2 != null && empty2.length == 0 && single2 != null && single2.length == 1):
          makeASTWithMeta(EMatch(PWildcard, makeASTWithMeta(EList(single2), n.metadata, n.pos)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
