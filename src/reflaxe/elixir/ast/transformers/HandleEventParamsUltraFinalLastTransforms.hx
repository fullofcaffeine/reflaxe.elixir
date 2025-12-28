package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventParamsUltraFinalLastTransforms
 *
 * WHAT
 * - Absolute last guard: if a handle_event/3 body still references `_params`,
 *   rename the second parameter binder to `params` and rewrite body refs.
 *
 * WHY
 * - Earlier hygiene passes may re-underscore the head or fail to rewrite body
 *   occurrences. This final pass ensures we never ship code that uses `_params`.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventParamsUltraFinalLastTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
          if (containsVar(body, "_params")) {
            var newArgs = args.copy(); newArgs[1] = PVar("params");
            var nb = rewrite(body, "_params", "params");
            makeASTWithMeta(EDef(name, newArgs, guards, nb), n.metadata, n.pos);
          } else n;
        default:
          n;
      }
    });
  }

  static function containsVar(body: ElixirAST, nm: String): Bool {
    var found = false;
    function walk(x: ElixirAST) {
      if (found || x == null || x.def == null) return;
      switch (x.def) {
        case EVar(v) if (v == nm): found = true;
        case EBinary(_, l, r): walk(l); walk(r);
        case EMatch(_, rhs): walk(rhs);
        case EBlock(ss): for (s in ss) walk(s);
        case EDo(ss2): for (s in ss2) walk(s);
        case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
        case ECase(e2, cs): walk(e2); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body); }
        case ECall(tg, _, as): if (tg != null) walk(tg); if (as != null) for (a in as) walk(a);
        case ERemoteCall(tg2, _, as2): walk(tg2); if (as2 != null) for (a2 in as2) walk(a2);
        case EField(obj,_): walk(obj);
        case EAccess(obj2,key): walk(obj2); walk(key);
        default:
      }
    }
    walk(body); return found;
  }

  static function rewrite(body: ElixirAST, from:String, to:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end

