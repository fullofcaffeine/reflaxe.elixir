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
    #if debug_perf var __p0 = reflaxe.elixir.debug.Perf.now(); #end
    var result = ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(functionName, parameters, guards, body):
          #if debug_perf var __p = reflaxe.elixir.debug.Perf.now(); #end
          var suffixMap = collectUniqueSuffixParams(parameters);
          #if debug_varref_suffix {
            var keys = [for (k in suffixMap.keys()) k].join(",");
          } #end
          var newBody = rewriteRefsScoped(body, suffixMap);
          var ret = makeASTWithMeta(EDef(functionName, parameters, guards, newBody), n.metadata, n.pos);
          #if debug_perf reflaxe.elixir.debug.Perf.add('VarRefSuffixParamNormalize.def', __p); #end
          ret;
        case EDefp(functionName, parameters, guards, body):
          #if debug_perf var __p2 = reflaxe.elixir.debug.Perf.now(); #end
          var suffixMap = collectUniqueSuffixParams(parameters);
          #if debug_varref_suffix {
            var keys = [for (k in suffixMap.keys()) k].join(",");
          } #end
          var newBody = rewriteRefsScoped(body, suffixMap);
          var ret2 = makeASTWithMeta(EDefp(functionName, parameters, guards, newBody), n.metadata, n.pos);
          #if debug_perf reflaxe.elixir.debug.Perf.add('VarRefSuffixParamNormalize.defp', __p2); #end
          ret2;
        default:
          n;
      }
    });
    #if debug_perf reflaxe.elixir.debug.Perf.add('VarRefSuffixParamNormalize.pass', __p0); #end
    return result;
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
        switch (x.def) {
          case EMatch(p,_):
            pat(p,d);
          case EBinary(Match, l,_):
            lhs(l,d);
          case ECase(_, clauses):
            for (cl in clauses) pat(cl.pattern, d);
          case EWith(clauses, _, _):
            for (cl in clauses) pat(cl.pattern, d);
          default:
        }
      });
      return d;
    }

    // Precompute top-level declared names once for the function body
    var topDeclaredCache:Map<String,Bool> = collectDeclared(body);

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
                  case EVar(v) if (v != null && suff.exists(v) && !declared.exists(v)):
                    var full = suff.get(v);
                    makeASTWithMeta(EVar(full), y.metadata, y.pos);
                  default: y;
                }
              });
              newClauses.push({ args: cl.args, guard: cl.guard, body: newBody });
            }
            makeASTWithMeta(EFn(newClauses), x.metadata, x.pos);
          case EVar(nm):
            // Top-level within function scope (use precomputed cache)
            if (nm != null && suff.exists(nm) && !topDeclaredCache.exists(nm)) {
              var fullTop = suff.get(nm);
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
