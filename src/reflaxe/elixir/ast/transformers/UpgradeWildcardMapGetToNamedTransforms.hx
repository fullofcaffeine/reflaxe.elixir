package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UpgradeWildcardMapGetToNamedTransforms
 *
 * WHAT
 * - Rewrites wildcard assignments `_ = Map.get(params, "key")` and
 *   `_ <- Map.get(params, "key")` into named snake_case binds: `key = Map.get(...)`.
 *
 * WHY
 * - Later passes (e.g., VarNameNormalization) can then rewrite camelCase references
 *   to the declared snake_case binding. This avoids undefined-variable errors when
 *   a shape emits a discarded Map.get followed by a camelCase usage.
 *
 * HOW
 * - Walk all nodes and pattern-match wildcard assignment shapes. When the RHS is
 *   a Map.get/2 call with a literal string key, replace the LHS wildcard with a
 *   PVar/EVar named exactly as the key string.
 */
class UpgradeWildcardMapGetToNamedTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(Match, {def: EVar("_")}, rhs):
          var key = extractMapGetKey(rhs);
          if (key != null) {
            makeASTWithMeta(EBinary(Match, makeAST(EVar(key)), rhs), n.metadata, n.pos);
          } else n;
        case EMatch(PVar("_"), rhs2):
          var key2 = extractMapGetKey(rhs2);
          if (key2 != null) {
            makeASTWithMeta(EBinary(Match, makeAST(EVar(key2)), rhs2), n.metadata, n.pos);
          } else n;
        default:
          n;
      }
    });
  }

  static function extractMapGetKey(expr: ElixirAST): Null<String> {
    return switch (expr.def) {
      case ERemoteCall(mod, name, args):
        var isMap = switch (mod.def) { case EVar(m): m == "Map"; default: false; };
        if (isMap && name == "get" && args != null && args.length >= 2)
          switch (args[1].def) { case EString(s): s; default: null; } else null;
      case ECall(target, funcName, args2):
        var isMapGet = (funcName == "get") && (target != null) && switch (target.def) { case EVar(m2): m2 == "Map"; default: false; };
        if (isMapGet && args2 != null && args2.length >= 2)
          switch (args2[1].def) { case EString(s2): s2; default: null; } else null;
      case EParen(inner):
        extractMapGetKey(inner);
      default: null;
    }
  }
}

#end
