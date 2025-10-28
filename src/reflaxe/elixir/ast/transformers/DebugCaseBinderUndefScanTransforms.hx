package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DebugCaseBinderUndefScanTransforms
 * - Debug-only scan that logs case clauses shaped {:atom, binder} and lists
 *   undefined lowercase locals used in their bodies. Helps verify binder
 *   alignment/injection passes.
 */
class DebugCaseBinderUndefScanTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      switch (n.def) {
        case ECase(_, clauses):
          for (cl in clauses) {
            var binder = switch (cl.pattern) {
              case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): n; default: null; }
              default: null;
            };
            if (binder != null) {
              var declared = new Map<String,Bool>();
              // declared: pattern vars + LHS in body
              function pat(p:EPattern){
                switch (p) { case PVar(n): declared.set(n,true); case PTuple(es) | PList(es): for (e in es) pat(e); case PCons(h,t): pat(h); pat(t); case PMap(kvs): for (kv in kvs) pat(kv.value); case PStruct(_,fs): for (f in fs) pat(f.value); case PPin(inner): pat(inner); default: }
              }
              pat(cl.pattern);
              reflaxe.elixir.ast.ASTUtils.walk(cl.body, function(x:ElixirAST){
                switch (x.def) { case EMatch(p,_): pat(p); case EBinary(Match, {def: EVar(l)}, _): declared.set(l,true); default: }
              });
              var used = new Map<String,Bool>();
              reflaxe.elixir.ast.ASTUtils.walk(cl.body, function(x:ElixirAST){ switch (x.def) { case EVar(v): used.set(v,true); default: } });
              var undef:Array<String> = [];
              for (k in used.keys()) if (!declared.exists(k) && allow(k)) undef.push(k);
              #if sys if (undef.length > 0) Sys.println('[DebugCaseBinderUndef] binder=' + binder + ' undef={' + undef.join(',') + '}'); #end
            }
          }
        default:
      }
      return n;
    });
  }
  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == 'socket' || name == 'params' || name == '_params' || name == 'event') return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
  }
}

#end

