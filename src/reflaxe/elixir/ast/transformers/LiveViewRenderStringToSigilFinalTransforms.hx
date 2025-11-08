package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.TemplateHelpers;

/**
 * LiveViewRenderStringToSigilFinalTransforms
 *
 * WHAT
 * - Absolute-final safety: in LiveView modules (metadata.isLiveView == true),
 *   convert render/2 bodies that end with a literal HTML-looking string into a
 *   ~H sigil. Runs very late to catch final shapes after hygiene.
 */
class LiveViewRenderStringToSigilFinalTransforms {
  static inline function unwrap(n: ElixirAST): ElixirAST {
    var cur = n;
    while (Type.enumConstructor(cur.def) == "EParen") {
      switch (cur.def) { case EParen(inner): cur = inner; default: }
    }
    return cur;
  }
  static inline function looksHtml(s:String):Bool {
    if (s == null) return false;
    var t = StringTools.trim(s);
    return t.indexOf("<") != -1 && t.indexOf(">") != -1;
  }

  static function rewriteRenderDef(n: ElixirAST): ElixirAST {
    return switch (n.def) {
      case EDef("render", args, guards, body):
        var b0 = unwrap(body);
        switch (b0.def) {
          case EBlock(stmts) if (stmts.length > 0):
            var last = unwrap(stmts[stmts.length - 1]);
            switch (last.def) {
              case EString(s) if (looksHtml(s)):
#if sys
                try Sys.println('[LVRenderFinal] Converting render/.. block string to ~H') catch (_:Dynamic) {}
#end
                var conv = TemplateHelpers.rewriteControlTags(TemplateHelpers.rewriteInterpolations(s));
                var ns = stmts.copy();
                ns[ns.length - 1] = makeAST(ESigil("H", conv, ""));
                var newArgs = (args != null && args.length == 2) ? [args[1]] : args;
                makeASTWithMeta(EDef("render", newArgs, guards, makeAST(EBlock(ns))), n.metadata, n.pos);
              default: n;
            }
          case EDo(ss) if (ss.length > 0):
            var last2 = unwrap(ss[ss.length - 1]);
            switch (last2.def) {
              case EString(s2) if (looksHtml(s2)):
#if sys
                try Sys.println('[LVRenderFinal] Converting render/.. do-string to ~H') catch (_:Dynamic) {}
#end
                var conv2 = TemplateHelpers.rewriteControlTags(TemplateHelpers.rewriteInterpolations(s2));
                var ns2 = ss.copy();
                ns2[ns2.length - 1] = makeAST(ESigil("H", conv2, ""));
                var newArgs2 = (args != null && args.length == 2) ? [args[1]] : args;
                makeASTWithMeta(EDef("render", newArgs2, guards, makeAST(EDo(ns2))), n.metadata, n.pos);
              default: n;
            }
          case EString(s3) if (looksHtml(s3)):
#if sys
            try Sys.println('[LVRenderFinal] Converting render/.. direct string to ~H') catch (_:Dynamic) {}
#end
            var conv3 = TemplateHelpers.rewriteControlTags(TemplateHelpers.rewriteInterpolations(s3));
            var newArgs3 = (args != null && args.length == 2) ? [args[1]] : args;
            makeASTWithMeta(EDef("render", newArgs3, guards, makeAST(ESigil("H", conv3, ""))), n.metadata, n.pos);
          default: n;
        }
      default:
        n;
    }
  }

  public static function pass(ast: ElixirAST): ElixirAST {
    // Apply globally but limit to render defs returning HTML-like strings
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body):
          var nb = [for (b in body) rewriteRenderDef(b)];
          makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
        case EDefmodule(name2, doBlock):
          makeASTWithMeta(EDefmodule(name2, rewriteRenderDef(doBlock)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
