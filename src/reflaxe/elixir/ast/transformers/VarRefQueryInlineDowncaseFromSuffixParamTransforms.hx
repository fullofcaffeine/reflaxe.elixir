package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * VarRefQueryInlineDowncaseFromSuffixParamTransforms
 *
 * WHAT
 * - For any def/defp that has exactly one parameter ending with `_query`,
 *   rewrite free references to `query` anywhere in the function body to
 *   `String.downcase(<that_param>)`.
 *
 * WHY
 * - Guards against late ordering issues where `query` appears but only
 *   `<param>_query` is declared. Produces a safe, deterministic inlined
 *   expression while avoiding app-specific names.
 */
class VarRefQueryInlineDowncaseFromSuffixParamTransforms {
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
    if (args == null) return null;
    var found:Null<String> = null; var count = 0;
    for (a in args) switch (a) { case PVar(n) if (StringTools.endsWith(n, "_query")): found = n; count++; default: }
    return count == 1 ? found : null;
  }
  static function rewrite(body: ElixirAST, paramName:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(nm) if (nm == "query"):
          #if sys Sys.println('[VarRefQueryInlineDowncase] query -> String.downcase(' + paramName + ')'); #end
          makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar(paramName))]), x.metadata, x.pos);
        default: x;
      }
    });
  }
  static function pat(p:EPattern, d:Map<String,Bool>):Void {
    switch (p) { case PVar(n): d.set(n,true); case PTuple(es) | PList(es): for (e in es) pat(e,d); case PCons(h,t): pat(h,d); pat(t,d); case PMap(kvs): for (kv in kvs) pat(kv.value,d); case PStruct(_,fs): for (f in fs) pat(f.value,d); case PPin(inner): pat(inner,d); default: }
  }
  static function lhs(l:ElixirAST, d:Map<String,Bool>):Void {
    switch (l.def) { case EVar(n): d.set(n,true); case EBinary(Match, l2,_): lhs(l2,d); default: }
  }
}

#end
