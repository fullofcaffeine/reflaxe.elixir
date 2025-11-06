package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IIFEInlineTransforms
 *
 * WHAT
 * - Inlines trivial immediately-invoked anonymous functions when the body is
 *   itself an anonymous function (EFn): (fn -> (fn args -> body end) end).()
 *   → (fn args -> body end).
 *
 * WHY
 * - Earlier safety wraps can produce nested fn wrappers in argument position
 *   which are unnecessary and harm readability (e.g., Enum.each second arg).
 * - Rewriting is semantics-preserving: the IIFE returns the inner function.
 *
 * HOW
 * - Walk nodes; whenever encountering ECall(EFn([{args:[], body: inner}]), "", [])
 *   with inner.def == EFn(_), replace the call with inner, preserving metadata.
 */
class IIFEInlineTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECall(targetExpr, name, callArgs):
          var isIIFE = (name == null || name == "") && (callArgs == null || callArgs.length == 0);
          // Unwrap parenthesis on target
          var t = targetExpr;
          while (true) switch (t.def) { case EParen(inner): t = inner; continue; default: break; }
          switch (t.def) {
            case EFn(clauses) if (isIIFE && clauses != null && clauses.length == 1):
              var c = clauses[0];
              var isZeroArg = (c.args == null || c.args.length == 0) && c.guard == null;
              if (isZeroArg) switch (c.body.def) {
                case EFn(_):
                #if debug_inline_iife
                trace('[IIFEInline] inlining trivial IIFE that returns EFn');
                #end
                // Return inner function, preserving outer metadata
                makeASTWithMeta(c.body.def, n.metadata, n.pos);
                default: n;
              } else n;
            default:
              n;
          }
        default:
          n;
      }
    });
  }
}

#end
