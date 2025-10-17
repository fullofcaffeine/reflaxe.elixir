package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.TemplateHelpers;

/**
 * HeexRenderStringToSigilTransforms
 *
 * WHAT
 * - Ensures LiveView render(assigns) returns a ~H sigil when the body ends with
 *   a literal HTML-ish string. Converts the final string into ESigil("H", ...).
 *   Scope: LiveView modules only (node.metadata.isLiveView == true).
 *
 * WHY
 * - Some code paths (e.g., HXX macro returning a processed string) leave render/1
 *   returning a plain string. LiveView requires %Phoenix.LiveView.Rendered{}.
 *   Restricting to LiveView prevents false positives in plain helpers/components/tests
 *   that legitimately return strings (keeps snapshots stable & idiomatic).
 *
 * HOW
 * - For modules with isLiveView metadata (EModule/EDefmodule):
 *   - Find EDef("render", [assigns], _, body)
 *   - If body is a final EString (direct, in EBlock or EDo) and looks HTML-ish,
 *     replace it with ESigil("H", converted, "").
 *   - Conversion delegates to TemplateHelpers for interpolation/control-tag rules.
 *
 * EXAMPLES
 * Haxe (LiveView):
 *   class TodoLive { @:liveview public static function render(assigns: Assigns) {
 *     return HXX.hxx('<div>Hello, ${assigns.name}</div>');
 *   }}
 * Elixir (after):
 *   def render(assigns) do
 *     ~H"""
 *     <div>Hello, <%= @name %></div>
 *     """
 *   end
 */
class HeexRenderStringToSigilTransforms {
    static inline function unwrapParens(n: ElixirAST): ElixirAST {
        var cur = n;
        while (Type.enumConstructor(cur.def) == "EParen") {
            switch (cur.def) {
                case EParen(inner): cur = inner;
                default:
            }
        }
        return cur;
    }
    static inline function looksLikeHtml(s:String):Bool {
        if (s == null) return false;
        var t = StringTools.trim(s);
        return t.indexOf("<") != -1 && t.indexOf(">") != -1;
    }

    static function convertInterpolations(s:String):String {
        if (s == null) return s;
        // Delegate to TemplateHelpers to keep a single source of truth, including
        // attribute-level expression rewriting and control-tag normalization.
        var res = TemplateHelpers.rewriteInterpolations(s);
        res = TemplateHelpers.rewriteControlTags(res);
        return res;
    }

    // Rewrite a single render(assigns) def inside a LiveView module
    static function rewriteRenderDef(n: ElixirAST): ElixirAST {
        return switch (n.def) {
            case EDef(name, args, guards, body) if (name == "render"):
                // Ensure first arg is `assigns`
                var hasAssigns = false;
                for (a in args) switch (a) { case PVar(p) if (p == "assigns"): hasAssigns = true; default: }
                if (!hasAssigns) return n;
                var b0 = unwrapParens(body);
                switch (b0.def) {
                    case EBlock(stmts) if (stmts.length > 0):
                        var last = unwrapParens(stmts[stmts.length - 1]);
                        switch (last.def) {
                            case EString(s) if (looksLikeHtml(s)):
                                var conv = convertInterpolations(s);
                                var newStmts = stmts.copy();
                                newStmts[newStmts.length - 1] = makeAST(ESigil("H", conv, ""));
                                makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(newStmts))), n.metadata, n.pos);
                            default: n;
                        }
                    case EDo(stmts) if (stmts.length > 0):
                        var last2 = unwrapParens(stmts[stmts.length - 1]);
                        switch (last2.def) {
                            case EString(ss) if (looksLikeHtml(ss)):
                                var conv3 = convertInterpolations(ss);
                                var out = stmts.copy();
                                out[out.length - 1] = makeAST(ESigil("H", conv3, ""));
                                makeASTWithMeta(EDef(name, args, guards, makeAST(EDo(out))), n.metadata, n.pos);
                            default: n;
                        }
                    case EString(s4) if (looksLikeHtml(s4)):
                        var sig2 = makeAST(ESigil("H", convertInterpolations(s4), ""));
                        makeASTWithMeta(EDef(name, args, guards, sig2), n.metadata, n.pos);
                    default:
                        n;
                }
            default:
                n;
        }
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                // Only operate within LiveView modules
                case EModule(name, attrs, body) if (n.metadata?.isLiveView == true):
                    var newBody = [for (b in body) rewriteRenderDef(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (n.metadata?.isLiveView == true):
                    var newDo = rewriteRenderDef(doBlock);
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
