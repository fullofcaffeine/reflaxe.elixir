package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseFlattenNestedSwitchTransforms
 *
 * WHAT
 * - Flattens nested case/switch patterns of the shape:
 *     case opt do
 *       {:some, v} ->
 *         case v do
 *           <inner_pattern_1> -> body1
 *           <inner_pattern_2> -> body2
 *           _ -> body_default
 *         end
 *       :none -> body_none
 *     end
 *   into a single case with combined patterns:
 *     case opt do
 *       {:some, <inner_pattern_1>} -> body1
 *       {:some, <inner_pattern_2>} -> body2
 *       {:some, _} -> body_default    # when present
 *       :none -> body_none
 *     end
 *
 * WHY
 * - Haxe enum-of-enum matching (e.g., Some(TodoCreated(todo))) can be lowered to
 *   a two-stage case in the generated Elixir AST. Flattening restores the intended
 *   single-case shape with nested tuple patterns which is idiomatic and more robust.
 *
 * HOW
 * - Detect ECase with a clause pattern `{:some, var}` and a body that is itself an
 *   ECase on that `var` (allowing simple wrappers like EParen/EBlock-single).
 * - Replace that clause with a set of clauses combining `{:some, <inner_pattern>}`
 *   with each inner clause’s body/guard.
 */
class CaseFlattenNestedSwitchTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out: Array<ElixirAST.ECaseClause> = [];
          var changed = false;

          for (cl in clauses) {
            var flattened = false;

            // Helper: unwrap simple wrappers to reach a direct ECase
            inline function unwrapToCase(e: ElixirAST): Null<{ scrut: ElixirAST, clauses: Array<ElixirAST.ECaseClause> }>{
              var cur = e;
              // Unwrap one-level parens or single-stmt blocks
              switch (cur.def) {
                case EParen(inner): cur = inner;
                default:
              }
              switch (cur.def) {
                case EBlock(stmts) if (stmts.length == 1): cur = stmts[0];
                default:
              }
              return switch (cur.def) {
                case ECase(s, cls): { scrut: s, clauses: cls };
                default: null;
              };
            }

            // Match pattern {:some, var}
            switch (cl.pattern) {
              case PTuple(elems) if (elems.length == 2):
                var first = elems[0];
                var second = elems[1];

                var isSome = switch (first) {
                  case PLiteral({def: EAtom(a)}): Std.string(a) == "some";
                  default: false;
                };

                switch (second) {
                  case PVar(varName) if (isSome):
                    // Check if body is a case on that var
                    var inner = unwrapToCase(cl.body);
                    if (inner != null && (switch (inner.scrut.def) { case EVar(v): v == varName; default: false; })) {
                      // Combine patterns
                      for (icl in inner.clauses) {
                        var combined = PTuple([
                          first, // {:some, ...}
                          icl.pattern
                        ]);
                        out.push({ pattern: combined, guard: icl.guard, body: icl.body });
                      }
                      changed = true; flattened = true;
                    }
                  default:
                }
              default:
            }

            if (!flattened) out.push(cl);
          }

          if (changed) makeASTWithMeta(ECase(target, out), n.metadata, n.pos) else n;

        default:
          n;
      }
    });
  }
}

#end

