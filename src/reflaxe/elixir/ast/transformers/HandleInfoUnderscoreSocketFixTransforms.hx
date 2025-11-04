package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoUnderscoreSocketFixTransforms
 *
 * WHAT
 * - In `handle_info/2`, replace references to `_socket` with `socket` and
 *   rewrite alias assignments like `value = _socket` to `_ = socket`.
 *
 * WHY
 * - Avoids warnings "underscored variable used after being set" and unused
 *   alias variables in the {:some, _socket} branch produced by neutral lowering.
 */
class HandleInfoUnderscoreSocketFixTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_info" || name == "handleInfo"):
          var nb = ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
              // Replace `_socket` references with `socket`
              case EVar(v) if (v == "_socket"): makeASTWithMeta(EVar("socket"), x.metadata, x.pos);
              // Rewrite alias `var = _socket` or `var = socket` to `_ = socket`
              case EBinary(Match, left, right):
                // First, normalize RHS `_socket` -> `socket`
                var normRight = switch (right.def) { case EVar(rv) if (rv == "_socket"): makeASTWithMeta(EVar("socket"), right.metadata, right.pos); default: right; };
                switch (normRight.def) {
                  case EVar(rv2) if (rv2 == "socket"):
                    switch (left.def) {
                      case EVar(_): makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), left.metadata, left.pos), normRight), x.metadata, x.pos);
                      default: makeASTWithMeta(EBinary(Match, left, normRight), x.metadata, x.pos);
                    }
                  default:
                    makeASTWithMeta(EBinary(Match, left, normRight), x.metadata, x.pos);
                }
              default: x;
            }
          });
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
