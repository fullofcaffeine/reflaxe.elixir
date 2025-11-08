package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LiveViewRenderHeadNormalizeTransforms
 *
 * WHAT
 * - In LiveView modules, normalize render head to `def render(assigns)`.
 *   Drops a leading placeholder parameter (e.g., `struct`) when present.
 *
 * WHY
 * - Snapshots and idiomatic Phoenix expect render/1. Some earlier builders
 *   emitted a two-arg shape (`render(struct, assigns)`). This pass corrects
 *   the head without touching the body: body already references `assigns`.
 *
 * HOW
 * - For modules with metadata.isLiveView == true, rewrite
 *     EDef("render", [a,b], g, body) → EDef("render", [b], g, body)
 *   when the first arg is a simple variable pattern.
 */
class LiveViewRenderHeadNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    // Apply globally but guard on HTML-like tails or existing ~H to avoid false positives
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body):
          var nb = [for (b in body) rewriteDef(b)];
          makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
        case EDefmodule(name2, doBlock):
          makeASTWithMeta(EDefmodule(name2, rewriteDef(doBlock)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteDef(n: ElixirAST): ElixirAST {
    return switch (n.def) {
      case EDef("render", args, guards, body) if (args != null && args.length == 2):
        if (bodyLooksHtmlish(body) || bodyContainsHeex(body)) {
          var assignsArg = args[1];
          makeASTWithMeta(EDef("render", [assignsArg], guards, body), n.metadata, n.pos);
        } else n;
      default:
        n;
    }
  }

  static function bodyLooksHtmlish(body: ElixirAST): Bool {
    function unwrap(x: ElixirAST): ElixirAST {
      var cur = x; while (Type.enumConstructor(cur.def) == "EParen") switch (cur.def) { case EParen(inner): cur = inner; default: } return cur;
    }
    function looks(s:String):Bool {
      if (s == null) return false; var t = StringTools.trim(s); return t.indexOf("<") != -1 && t.indexOf(">") != -1;
    }
    var b0 = unwrap(body);
    return switch (b0.def) {
      case EString(s): looks(s);
      case EBlock(stmts) if (stmts.length > 0):
        var last = unwrap(stmts[stmts.length-1]); switch (last.def) { case EString(ss): looks(ss); default: false; }
      case EDo(stmts2) if (stmts2.length > 0):
        var last2 = unwrap(stmts2[stmts2.length-1]); switch (last2.def) { case EString(ss2): looks(ss2); default: false; }
      default: false;
    }
  }

  static function bodyContainsHeex(body: ElixirAST): Bool {
    var found = false;
    function scan(x: ElixirAST): Void {
      if (found || x == null || x.def == null) return;
      switch (x.def) {
        case ESigil(t, _, _) if (t == "H"): found = true;
        case EBlock(ss): for (s in ss) scan(s);
        case EDo(ss2): for (s in ss2) scan(s);
        case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
        case ECase(e, cs): scan(e); for (c in cs) scan(c.body);
        case EBinary(_, l, r): scan(l); scan(r);
        case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
        case ERemoteCall(m,_,as2): scan(m); if (as2 != null) for (a in as2) scan(a);
        default:
      }
    }
    scan(body);
    return found;
  }
}

#end
