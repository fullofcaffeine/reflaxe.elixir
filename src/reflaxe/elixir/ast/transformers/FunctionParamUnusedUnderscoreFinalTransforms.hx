package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * FunctionParamUnusedUnderscoreFinalTransforms
 *
 * WHAT
 * - Absolute-final pass: underscores unused function parameters in def/defp.
 *
 * WHY
 * - Eliminates warnings-as-errors for unused parameters (e.g., `event` in
 *   a handle_event/3 catch-all, or `online_users` in a render helper).
 *
 * HOW
 * - For each EDef/EDefp, collect used identifiers in the body. For each
 *   positional argument that is a simple PVar(name) and not used, rename
 *   it to PVar("_" + name).
 */
class FunctionParamUnusedUnderscoreFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var used = collectUsed(body);
          var newArgs = underscoreUnused(args, used);
          makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var used2 = collectUsed(body2);
          var newArgs2 = underscoreUnused(args2, used2);
          makeASTWithMeta(EDefp(name2, newArgs2, guards2, body2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function underscoreUnused(args:Array<EPattern>, used: Map<String,Bool>): Array<EPattern> {
    if (args == null) return args;
    var out:Array<EPattern> = [];
    for (a in args) switch (a) {
      case PVar(n):
        if (!used.exists(n) && n.charAt(0) != '_') out.push(PVar('_' + n));
        else out.push(a);
      default:
        out.push(a);
    }
    return out;
  }

  static function collectUsed(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    ASTUtils.walk(ast, function(x: ElixirAST) {
      switch (x.def) { case EVar(v): names.set(v, true); default: }
    });
    return names;
  }
}

#end

