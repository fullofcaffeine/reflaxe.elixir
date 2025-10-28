package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * QueryVarUltimateNormalizeTransforms
 *
 * WHAT
 * - Ultra-final safeguard for functions that accept exactly one `*_query` parameter.
 *   Rewrites any remaining free references to `query` anywhere in the function body to a
 *   well-defined expression:
 *     - If the function contains an in-place normalization `p = String.downcase(p)`,
 *       rewrite `query` → `p` (the normalized param).
 *     - Otherwise, rewrite `query` → `String.downcase(p)`.
 *
 * WHY
 * - Late ordering interactions can still leave `query` references in nested closures
 *   (e.g., Enum.filter predicates). This pass provides a deterministic, shape-based,
 *   non-app-coupled fix at the very end of the pipeline.
 *
 * HOW
 * - Detect the single `*_query` parameter in def/defp.
 * - Scan the body for a self-normalizing assignment of that parameter.
 * - Replace EVar("query") accordingly across the body subtree.
 *
 * EXAMPLES
 * Before:
 *   p = String.downcase(p)
 *   Enum.filter(list, fn t -> String.contains?(t.title, query) end)
 * After:
 *   p = String.downcase(p)
 *   Enum.filter(list, fn t -> String.contains?(t.title, p) end)
 */
class QueryVarUltimateNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var p = detectQueryParam(args);
          if (p == null) n else makeASTWithMeta(EDef(name, args, guards, rewrite(body, p)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var p2 = detectQueryParam(args2);
          if (p2 == null) n else makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2, p2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function detectQueryParam(args:Array<EPattern>): Null<String> {
    if (args == null) return null; var found:Null<String> = null; var count = 0;
    for (a in args) switch (a) { case PVar(n) if (StringTools.endsWith(n, "_query")): found = n; count++; default: }
    return count == 1 ? found : null;
  }

  static function hasSelfDowncase(body: ElixirAST, param:String): Bool {
    var yes = false;
    ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      if (yes) return x;
      switch (x.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs) if (lhs == param): if (isDowncaseOfParam(param, rhs)) yes = true;
        case EMatch(PVar(lhs2), rhs2) if (lhs2 == param): if (isDowncaseOfParam(param, rhs2)) yes = true;
        default:
      }
      return x;
    });
    return yes;
  }

  static function isDowncaseOfParam(param:String, e:ElixirAST): Bool {
    return switch (e.def) {
      case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
        switch (args[0].def) { case EVar(v) if (v == param): true; default: false; }
      default: false;
    }
  }

  static function rewrite(body: ElixirAST, param:String): ElixirAST {
    var preferParam = hasSelfDowncase(body, param);
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(nm) if (nm == "query"):
          #if sys Sys.println('[QueryUltimateNormalize] query -> ' + (preferParam ? param : ('String.downcase(' + param + ')')));
          #end
          if (preferParam) makeASTWithMeta(EVar(param), x.metadata, x.pos) else makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar(param))]), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end

