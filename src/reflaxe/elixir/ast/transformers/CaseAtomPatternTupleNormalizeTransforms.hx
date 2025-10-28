package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseAtomPatternTupleNormalizeTransforms
 *
 * WHAT
 * - Within a case expression, if any clause pattern is a tagged tuple like {:tag, ...},
 *   normalize sibling single-atom patterns (:tag) to the tuple form {:tag} for consistency.
 *
 * WHY
 * - Snapshot expectations prefer {:none} instead of :none when matching alongside {:some, v}.
 * - This stays generic and shape-based without app coupling.
 */
class CaseAtomPatternTupleNormalizeTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var hasTaggedTuple = false;
          for (cl in clauses) switch (cl.pattern) {
            case PTuple(es) if (es.length >= 1):
              switch (es[0]) { case PLiteral({def: EAtom(_)}): hasTaggedTuple = true; default: }
            default:
          }
          if (!hasTaggedTuple) return n;
          var out = [];
          for (cl in clauses) {
            var pat = cl.pattern;
            switch (pat) {
              case PLiteral({def: EAtom(a)}):
                pat = PTuple([PLiteral(makeAST(ElixirASTDef.EAtom(a)))]);
              default:
            }
            out.push({pattern: pat, guard: cl.guard, body: cl.body});
          }
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
