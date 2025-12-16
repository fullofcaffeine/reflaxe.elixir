package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.PhoenixContext;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.TemplateHelpers;
import reflaxe.elixir.ast.ElixirASTPrinter;

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

    static function extractPrintedStringLiteral(expr: ElixirAST): Null<String> {
        if (expr == null || expr.def == null) return null;
        var printed:String = null;
        try {
            printed = ElixirASTPrinter.print(expr, 0);
        } catch (_:Dynamic) {
            return null;
        }
        if (printed == null) return null;
        printed = StringTools.trim(printed);
        if (printed.length < 2 || printed.charAt(0) != '"' || printed.charAt(printed.length - 1) != '"') {
            return null;
        }

        var t = printed;
        var decoded:Array<String> = [];
        var i = 1;
        var end = t.length - 1;
        while (i < end) {
            var ch = t.charAt(i);
            if (ch == '\\' && i + 1 < end) {
                var nxt = t.charAt(i + 1);
                switch (nxt) {
                    case 'n': decoded.push("\n"); i += 2; continue;
                    case 'r': decoded.push("\r"); i += 2; continue;
                    case 't': decoded.push("\t"); i += 2; continue;
                    case '"': decoded.push('"'); i += 2; continue;
                    case '\\': decoded.push('\\'); i += 2; continue;
                    default:
                        decoded.push(nxt);
                        i += 2; continue;
                }
            } else {
                decoded.push(ch);
                i++;
            }
        }
        return decoded.join("");
    }

    static function convertInterpolations(s:String):String {
        if (s == null) return s;
        // Delegate to TemplateHelpers to keep a single source of truth, including
        // attribute-level expression rewriting and control-tag normalization.
        var res = TemplateHelpers.rewriteInterpolations(s);
        res = TemplateHelpers.rewriteControlTags(res);
        return res;
    }

    static function isLiveViewModuleNode(moduleNode: ElixirAST): Bool {
        if (moduleNode == null) return false;
        if (moduleNode.metadata?.phoenixContext == PhoenixContext.LiveView || moduleNode.metadata?.isLiveView == true) {
            return true;
        }

        var found = false;
        ASTUtils.walk(moduleNode, function(n: ElixirAST) {
            if (found) return;
            switch (n.def) {
                case EUse(moduleName, options):
                    if (moduleName == "Phoenix.LiveView") {
                        found = true;
                        return;
                    }
                    if (options != null && options.length == 1) {
                        switch (options[0].def) {
                            case EAtom(a) if (a == "live_view"):
                                found = true;
                            default:
                        }
                    }
                default:
            }
        });

        return found;
    }

    // Rewrite a single render(assigns) def inside a LiveView module
    static function rewriteRenderDef(n: ElixirAST): ElixirAST {
        return switch (n.def) {
            case EDef(name, args, guards, body) if (name == "render"):
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
                            default:
                                var printed = extractPrintedStringLiteral(last);
                                if (printed != null && looksLikeHtml(printed)) {
                                    var conv2 = convertInterpolations(printed);
                                    var newStmts2 = stmts.copy();
                                    newStmts2[newStmts2.length - 1] = makeAST(ESigil("H", conv2, ""));
                                    makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(newStmts2))), n.metadata, n.pos);
                                } else n;
                        }
                    case EDo(stmts) if (stmts.length > 0):
                        var last2 = unwrapParens(stmts[stmts.length - 1]);
                        switch (last2.def) {
                            case EString(ss) if (looksLikeHtml(ss)):
                                var conv3 = convertInterpolations(ss);
                                var out = stmts.copy();
                                out[out.length - 1] = makeAST(ESigil("H", conv3, ""));
                                makeASTWithMeta(EDef(name, args, guards, makeAST(EDo(out))), n.metadata, n.pos);
                            default:
                                var printed2 = extractPrintedStringLiteral(last2);
                                if (printed2 != null && looksLikeHtml(printed2)) {
                                    var conv4 = convertInterpolations(printed2);
                                    var out2 = stmts.copy();
                                    out2[out2.length - 1] = makeAST(ESigil("H", conv4, ""));
                                    makeASTWithMeta(EDef(name, args, guards, makeAST(EDo(out2))), n.metadata, n.pos);
                                } else n;
                        }
                    case EString(s4) if (looksLikeHtml(s4)):
                        var sig2 = makeAST(ESigil("H", convertInterpolations(s4), ""));
                        makeASTWithMeta(EDef(name, args, guards, sig2), n.metadata, n.pos);
                    default:
                        var printed3 = extractPrintedStringLiteral(b0);
                        if (printed3 != null && looksLikeHtml(printed3)) {
                            var sig3 = makeAST(ESigil("H", convertInterpolations(printed3), ""));
                            makeASTWithMeta(EDef(name, args, guards, sig3), n.metadata, n.pos);
                        } else n;
                }
            default:
                n;
        }
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        // Operate module-wide, but only rewrite EDef("render", ...) nodes with HTML-ish strings
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    if (!isLiveViewModuleNode(n)) return n;
                    var newBody = [for (b in body) ElixirASTTransformer.transformNode(b, rewriteRenderDef)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    if (!isLiveViewModuleNode(n)) return n;
                    var newDo = ElixirASTTransformer.transformNode(doBlock, rewriteRenderDef);
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
