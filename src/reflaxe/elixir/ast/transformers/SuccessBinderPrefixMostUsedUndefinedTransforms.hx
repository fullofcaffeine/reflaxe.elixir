package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SuccessBinderPrefixMostUsedUndefinedTransforms
 *
 * WHAT
 * - For case clauses shaped as `{:ok, binder}`, if the body references one or more
 *   undefined simple variables, prefix-bind the most frequently used one to `binder`:
 *     var = binder; <body>
 *
 * WHY
 * - Complements rename-based alignment when renaming would shadow existing outer names
 *   (e.g., `socket`). Prefix-binding preserves outer references and satisfies undefineds.
 *
 * HOW
 * - For each ECase clause with `{:ok, PVar(binder)}`:
 *   - Compute declared names (pattern + LHS binds in body)
 *   - Count EVar occurrences in body; choose the most frequent name not declared/reserved
 *   - Prefix `name = binder` and keep the original body unchanged
 */
class SuccessBinderPrefixMostUsedUndefinedTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out = [];
          for (cl in clauses) {
            var binder = extractOkBinder(cl.pattern);
            if (binder != null) {
              var declared = new Map<String,Bool>();
              collectPatternDecls(cl.pattern, declared);
              collectLhsDeclsInBody(cl.body, declared);
              var freq = countVars(cl.body);
              var best:Null<String> = null; var bestCount = 0;
              for (k in freq.keys()) if (!declared.exists(k) && allow(k)) {
                var c = freq.get(k);
                if (c > bestCount) { bestCount = c; best = k; }
              }
              if (best != null) {
                var prefix = makeAST(EBinary(Match, makeAST(EVar(best)), makeAST(EVar(binder))));
                var newBody = switch (cl.body.def) {
                  case EBlock(sts): makeASTWithMeta(EBlock([prefix].concat(sts)), cl.body.metadata, cl.body.pos);
                  case EDo(sts2): makeASTWithMeta(EDo([prefix].concat(sts2)), cl.body.metadata, cl.body.pos);
                  default: makeASTWithMeta(EBlock([prefix, cl.body]), cl.body.metadata, cl.body.pos);
                };
                out.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                continue;
              }
            }
            out.push(cl);
          }
          makeASTWithMeta(ECase(target, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function extractOkBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) { case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"): switch (es[1]) { case PVar(n): n; default: null; } default: null; }
      default: null;
    }
  }
  static function collectPatternDecls(p:EPattern, vars:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n): vars.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, vars);
      case PCons(h,t): collectPatternDecls(h, vars); collectPatternDecls(t, vars);
      case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, vars);
      case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, vars);
      case PPin(inner): collectPatternDecls(inner, vars);
      default:
    }
  }
  static function collectLhsDeclsInBody(body:ElixirAST, vars:Map<String,Bool>):Void {
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){
      switch (x.def) { case EMatch(p,_): collectPatternDecls(p, vars); case EBinary(Match, l,_): collectLhs(l, vars); default: }
    });
  }
  static function collectLhs(lhs:ElixirAST, vars:Map<String,Bool>):Void {
    switch (lhs.def) { case EVar(n): vars.set(n,true); case EBinary(Match,l2,_): collectLhs(l2, vars); default: }
  }
  static function countVars(body:ElixirAST): haxe.ds.StringMap<Int> {
    var m = new haxe.ds.StringMap<Int>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){
      switch (x.def) { case EVar(n): if (allow(n)) m.set(n, (m.exists(n) ? m.get(n) : 0) + 1); default: }
    });
    return m;
  }
  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "live_socket" || name == "params" || name == "_params") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
  }
}

#end

