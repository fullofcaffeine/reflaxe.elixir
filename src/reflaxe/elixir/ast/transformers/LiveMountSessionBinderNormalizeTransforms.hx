package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * LiveMountSessionBinderNormalizeTransforms
 *
 * WHAT
 * - Renames the second argument of mount/3 from `_session` to `session` when
 *   the body does not reference `session` (shape-only normalization for parity).
 *
 * WHY
 * - Snapshot expectations use `session` (non-underscored) even if unused.
 *   Some hygiene passes underscore it. This pass restores the expected shape
 *   without altering behavior (still unused).
 */
class LiveMountSessionBinderNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length >= 3):
          switch (args[1]) {
            case PVar(nm) if (nm == "_session" && !VariableUsageCollector.usedInFunctionScope(body, "session") && !VariableUsageCollector.usedInFunctionScope(body, "_session")):
              var na = args.copy(); na[1] = PVar("session");
              makeASTWithMeta(EDef(name, na, guards, body), n.metadata, n.pos);
            default: n;
          }
        case EDefp(name2, args2, guards2, body2) if (name2 == "mount" && args2 != null && args2.length >= 3):
          switch (args2[1]) {
            case PVar(nm2) if (nm2 == "_session" && !VariableUsageCollector.usedInFunctionScope(body2, "session") && !VariableUsageCollector.usedInFunctionScope(body2, "_session")):
              var nb = args2.copy(); nb[1] = PVar("session");
              makeASTWithMeta(EDefp(name2, nb, guards2, body2), n.metadata, n.pos);
            default: n;
          }
        default:
          n;
      }
    });
  }
}

#end

