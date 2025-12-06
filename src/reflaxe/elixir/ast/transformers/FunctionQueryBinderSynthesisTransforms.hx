package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FunctionQueryBinderSynthesisTransforms
 *
 * WHAT
 * - For any def/defp that has exactly one parameter ending with `_query`, if the
 *   function body references `query` but there is no prior local declaration of
 *   `query`, synthesize a leading binder:
 *       query = String.downcase(<param>)
 *
 * WHY
 * - Provides a deterministic, shape-based top-level binder to resolve late
 *   undefined `query` references in functions operating on *_query params.
 */
class FunctionQueryBinderSynthesisTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var p = detectQueryParam(args);
          if (p == null) n else makeASTWithMeta(EDef(name, args, guards, synthesize(body, p)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var p2 = detectQueryParam(args2);
          if (p2 == null) n else makeASTWithMeta(EDefp(name2, args2, guards2, synthesize(body2, p2)), n.metadata, n.pos);
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
  static function synthesize(body: ElixirAST, paramName:String): ElixirAST {
    var declared = new Map<String,Bool>();
    var usesQuery = false;
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x: ElixirAST) {
      switch (x.def) {
        case EVar(nm) if (nm == 'query'): usesQuery = true;
        case EMatch(p,_): pat(p, declared);
        case EBinary(Match, l,_): lhs(l, declared);
        default:
      }
    });
    if (!usesQuery || declared.exists('query')) return body;
    var binder = makeAST(EBinary(Match, makeAST(EVar('query')), makeAST(ERemoteCall(makeAST(EVar('String')), 'downcase', [makeAST(EVar(paramName))]))));
    return switch (body.def) {
      case EBlock(sts): makeASTWithMeta(EBlock([binder].concat(sts)), body.metadata, body.pos);
      case EDo(sts2): makeASTWithMeta(EDo([binder].concat(sts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock([binder, body]), body.metadata, body.pos);
    }
  }
  static function pat(p:EPattern, d:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n): d.set(n,true);
      case PTuple(es) | PList(es): for (e in es) pat(e,d);
      case PCons(h,t): pat(h,d); pat(t,d);
      case PMap(kvs): for (kv in kvs) pat(kv.value,d);
      case PStruct(_,fs): for (f in fs) pat(f.value,d);
      case PPin(inner): pat(inner,d);
      default:
    }
  }
  static function lhs(l:ElixirAST, d:Map<String,Bool>):Void {
    switch (l.def) { case EVar(n): d.set(n,true); case EBinary(Match, l2,_): lhs(l2,d); default: }
  }
}

#end
