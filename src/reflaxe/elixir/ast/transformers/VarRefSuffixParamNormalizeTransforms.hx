package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * VarRefSuffixParamNormalizeTransforms
 *
 * WHAT
 * - Rewrites references to short names to a parameter whose name ends with `_<short>` when:
 *   - The function has exactly one parameter name that matches the suffix rule, and
 *   - No local declaration for the short name exists in the function body.
 *
 * WHY
 * - Common pattern: param `search_query` but body references `query`. This pass normalizes
 *   the reference to `search_query` without app-specific knowledge.
 */
class VarRefSuffixParamNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(functionName, parameters, guards, body):
          var suffixMap = collectUniqueSuffixParams(parameters);
          #if (sys && !no_traces) {
            var keys = [for (k in suffixMap.keys()) k].join(",");
            #if debug_varref_suffix
            if (keys.length > 0) Sys.println('[VarRefSuffixParamNormalize] def ' + functionName + ' suffixes={' + keys + '}');
            #end
          } #end
          var newBody = rewriteRefsScoped(body, suffixMap);
          makeASTWithMeta(EDef(functionName, parameters, guards, newBody), n.metadata, n.pos);
        case EDefp(functionName, parameters, guards, body):
          var suffixMap = collectUniqueSuffixParams(parameters);
          #if (sys && !no_traces) {
            var keys = [for (k in suffixMap.keys()) k].join(",");
            #if debug_varref_suffix
            if (keys.length > 0) Sys.println('[VarRefSuffixParamNormalize] defp ' + functionName + ' suffixes={' + keys + '}');
            #end
          } #end
          var newBody = rewriteRefsScoped(body, suffixMap);
          makeASTWithMeta(EDefp(functionName, parameters, guards, newBody), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function collectUniqueSuffixParams(args:Array<EPattern>): haxe.ds.StringMap<String> {
    var counts = new haxe.ds.StringMap<Int>();
    var firstSeen = new haxe.ds.StringMap<String>();
    var result = new haxe.ds.StringMap<String>();
    if (args != null) for (a in args) switch (a) {
      case PVar(p):
        var idx = p.lastIndexOf("_");
        if (idx > 0 && idx < p.length - 1) {
          var suff = p.substr(idx + 1);
          var c = counts.exists(suff) ? counts.get(suff) + 1 : 1;
          counts.set(suff, c);
          if (!firstSeen.exists(suff)) firstSeen.set(suff, p);
        }
      default:
    }
    // Only keep suffixes that are unique among params
    for (k in counts.keys()) if (counts.get(k) == 1) result.set(k, firstSeen.get(k));
    return result;
  }
  // Scoped rewrite that respects nested function scopes and local declarations.
  static function rewriteRefsScoped(body:ElixirAST, suff:haxe.ds.StringMap<String>): ElixirAST {
    function pat(p:EPattern, d:Map<String,Bool>):Void {
      switch (p) { case PVar(n): d.set(n,true); case PTuple(es) | PList(es): for (e in es) pat(e,d); case PCons(h,t): pat(h,d); pat(t,d); case PMap(kvs): for (kv in kvs) pat(kv.value,d); case PStruct(_,fs): for (f in fs) pat(f.value,d); case PPin(inner): pat(inner,d); default: }
    }
    function lhs(l:ElixirAST, d:Map<String,Bool>):Void {
      switch (l.def) { case EVar(n): d.set(n,true); case EBinary(Match, l2,_): lhs(l2,d); default: }
    }
    function collectDeclared(n:ElixirAST):Map<String,Bool> {
      var d = new Map<String,Bool>();
      reflaxe.elixir.ast.ASTUtils.walk(n, function(x:ElixirAST){
        switch (x.def) { case EMatch(p,_): pat(p,d); case EBinary(Match, l,_): lhs(l,d); default: }
      });
      return d;
    }

    // Enter a new scope at each anonymous fn and recompute declared-set locally
    function transformNodeScoped(n:ElixirAST):ElixirAST {
      return ElixirASTTransformer.transformNode(n, function(x:ElixirAST):ElixirAST {
        return switch (x.def) {
          case EFn(clauses):
            // Recompute declared-set per clause to respect inner arg binders
            var newClauses = [];
            for (cl in clauses) {
              var declared = collectDeclared(makeASTWithMeta(EFn([cl]), x.metadata, x.pos));
              var newBody = ElixirASTTransformer.transformNode(cl.body, function(y:ElixirAST):ElixirAST {
                return switch (y.def) {
                  case EVar(v) if (suff.exists(v) && !declared.exists(v)):
                    var full = suff.get(v);
                    #if (sys && debug_varref_suffix && !no_traces) Sys.println('[VarRefSuffixParamNormalize] ' + v + ' -> ' + full);
                    #end
                    makeASTWithMeta(EVar(full), y.metadata, y.pos);
                  default: y;
                }
              });
              newClauses.push({ args: cl.args, guard: cl.guard, body: newBody });
            }
            makeASTWithMeta(EFn(newClauses), x.metadata, x.pos);
          case EVar(nm):
            // Top-level within function scope
            var topDeclared = collectDeclared(body);
            if (suff.exists(nm) && !topDeclared.exists(nm)) {
              var fullTop = suff.get(nm);
              #if (sys && debug_varref_suffix && !no_traces) Sys.println('[VarRefSuffixParamNormalize] ' + nm + ' -> ' + fullTop);
              #end
              makeASTWithMeta(EVar(fullTop), x.metadata, x.pos);
            } else x;
          default: x;
        }
      });
    }
    return transformNodeScoped(body);
  }
}

#end
