package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.TemplateHelpers;

/**
 * RenderStringToSigilUltraFinalTransforms
 *
 * WHAT
 * - Ultra-final safety net: convert render(_, assigns) or render(assigns) that
 *   return a literal HTML-looking string into ~H. Global, but strictly scoped
 *   to functions named "render" to avoid touching helpers.
 */
class RenderStringToSigilUltraFinalTransforms {
  static inline function looksHtml(s:String):Bool {
    if (s == null) return false; var t = StringTools.trim(s); return t.indexOf('<') != -1 && t.indexOf('>') != -1;
  }
  static inline function unwrap(n:ElixirAST):ElixirAST {
    var cur = n; while (Type.enumConstructor(cur.def) == "EParen") switch (cur.def) { case EParen(inner): cur = inner; default: } return cur;
  }

  static function rewrite(n: ElixirAST): ElixirAST {
    return switch (n.def) {
      case EDef("render", args, guards, body):
        var b0 = unwrap(body);
        switch (b0.def) {
          case EString(s) if (looksHtml(s)):
            var conv = TemplateHelpers.rewriteControlTags(TemplateHelpers.rewriteInterpolations(s));
            makeASTWithMeta(EDef("render", args, guards, makeAST(ESigil("H", conv, ""))), n.metadata, n.pos);
          case EBlock(ss) if (ss.length > 0):
            var last = unwrap(ss[ss.length-1]);
            switch (last.def) {
              case EString(s2) if (looksHtml(s2)):
                var conv2 = TemplateHelpers.rewriteControlTags(TemplateHelpers.rewriteInterpolations(s2));
                var out = ss.copy(); out[out.length-1] = makeAST(ESigil("H", conv2, ""));
                makeASTWithMeta(EDef("render", args, guards, makeAST(EBlock(out))), n.metadata, n.pos);
              default: n;
            }
          case EDo(ss2) if (ss2.length > 0):
            var last2 = unwrap(ss2[ss2.length-1]);
            switch (last2.def) {
              case EString(s3) if (looksHtml(s3)):
                var conv3 = TemplateHelpers.rewriteControlTags(TemplateHelpers.rewriteInterpolations(s3));
                var out2 = ss2.copy(); out2[out2.length-1] = makeAST(ESigil("H", conv3, ""));
                makeASTWithMeta(EDef("render", args, guards, makeAST(EDo(out2))), n.metadata, n.pos);
              default: n;
            }
          default: n;
        }
      default: n;
    }
  }

  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body):
          var nb = [for (b in body) rewrite(b)];
          makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
        case EDefmodule(name2, doBlock):
          makeASTWithMeta(EDefmodule(name2, rewrite(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }
}

#end

