package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnderscoreToParamFixTransforms
 *
 * WHAT
 * - For any def/defp that declares a `socket` parameter, replace references to
 *   `_socket` with `socket`. Also rewrite alias assignments `var = _socket` to
 *   `_ = socket` to avoid unused variable warnings.
 *
 * WHY
 * - Neutral lowering sometimes introduces `_socket` references and alias lines that
 *   cause WAE warnings. This pass fixes them generically, scoped only to functions
 *   that actually have a `socket` parameter.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class UnderscoreToParamFixTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var hasSocket = hasSocketParam(args);
          if (!hasSocket) return n;
          var nb = rewriteBody(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name, args2, guards2, body2):
          var hasSocket2 = hasSocketParam(args2);
          if (!hasSocket2) return n;
          var nb2 = rewriteBody(body2);
          makeASTWithMeta(EDefp(name, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function hasSocketParam(args:Array<EPattern>):Bool {
    if (args == null) return false;
    for (a in args) switch (a) { case PVar(nm) if (nm == "socket"): return true; default: }
    return false;
  }

  static function rewriteBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == "_socket"): makeASTWithMeta(EVar("socket"), x.metadata, x.pos);
        case EBinary(Match, left, right):
          var rhs = switch (right.def) { case EVar(rv) if (rv == "_socket"): makeASTWithMeta(EVar("socket"), right.metadata, right.pos); default: right; };
          switch (rhs.def) {
            case EVar("socket"):
              switch (left.def) {
                case EVar(_): makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), left.metadata, left.pos), rhs), x.metadata, x.pos);
                default: makeASTWithMeta(EBinary(Match, left, rhs), x.metadata, x.pos);
              }
            default:
              makeASTWithMeta(EBinary(Match, left, rhs), x.metadata, x.pos);
          }
        default:
          x;
      }
    });
  }
}

#end

