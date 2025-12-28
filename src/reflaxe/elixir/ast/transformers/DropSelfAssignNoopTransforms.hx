package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DropSelfAssignNoopTransforms
 *
 * WHAT
 * - Remove no-op self-assignments like `v = v` (EBinary(Match, EVar(v), EVar(v)))
 *   that may appear in clause bodies after guard/pattern rewrites.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DropSelfAssignNoopTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push({ pattern: cl.pattern, guard: cl.guard, body: clean(cl.body) });
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function clean(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(sts): makeASTWithMeta(EBlock(filter(sts)), x.metadata, x.pos);
        case EDo(sts2): makeASTWithMeta(EDo(filter(sts2)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function filter(sts:Array<ElixirAST>):Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (s in sts) switch (s.def) {
      case EBinary(Match, {def: EVar(l)}, {def: EVar(r)}) if (l == r):
        // drop
      case EMatch(PVar(l2), {def: EVar(r2)}) if (l2 == r2):
        // drop
      default:
        out.push(s);
    }
    return out;
  }
}

#end
