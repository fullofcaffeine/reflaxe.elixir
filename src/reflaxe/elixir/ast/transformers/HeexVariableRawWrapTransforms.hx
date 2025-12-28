package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexVariableRawWrapTransforms
 *
 * WHAT
 * - Inside ~H sigils, wrap interpolations of variables that were previously
 *   bound to HEEx fragments (ESigil("H", ...)) or HTML-like strings with
 *   Phoenix.HTML.raw(var) so the content renders as intended.
 *
 * WHY
 * - Embedding a %Phoenix.LiveView.Rendered{} into a string via <%= var %> fails,
 *   and embedding HTML-ish strings gets escaped. Wrapping with raw(...) is the
 *   idiomatic fix when composing templates.
 *
 * HOW
 * - For each function (EDef/EDefp), collect variable names from bindings of the form:
 *     name = ~H"..." or name = "<tag ...>"
 * - Then, traverse ESigil("H", content) and rewrite occurrences of
 *     <%= name %>
 *   to
 *     <%= Phoenix.HTML.raw(name) %>
 *   when name is in the collected set.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HeexVariableRawWrapTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var vars = collectHeexLikeBindings(body);
                    makeASTWithMeta(EDef(name, args, guards, rewriteHeex(body, vars)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    var vars2 = collectHeexLikeBindings(body);
                    makeASTWithMeta(EDefp(name, args, guards, rewriteHeex(body, vars2)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectHeexLikeBindings(body: ElixirAST): haxe.ds.StringMap<Bool> {
        var s = new haxe.ds.StringMap<Bool>();
        function add(name:String):Void { if (!s.exists(name)) s.set(name, true); }
        function rhsHasHeexLike(n: ElixirAST):Bool {
            var found = false;
            function scan(x: ElixirAST):Void {
                if (found || x == null || x.def == null) return;
                switch (x.def) {
                    case ESigil(type, _, _) if (type == "H"): found = true; return;
                    case EString(str): if (looksLikeHtml(str)) { found = true; return; }
                    case EBlock(es): for (e in es) scan(e);
                    case EIf(c,t,e): scan(t); if (e != null) scan(e);
                    case ECase(e, cs): for (cl in cs) scan(cl.body);
                    case EDo(es): for (e in es) scan(e);
                    case EParen(inner): scan(inner);
                    default:
                }
            }
            scan(n);
            return found;
        }
        function walk(n: ElixirAST):Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(PVar(v), rhs):
                    if (rhsHasHeexLike(rhs)) add(v);
                case EBlock(es): for (e in es) walk(e);
                case EIf(c,t,e): walk(t); if (e != null) walk(e);
                case ECase(e, cs): for (cl in cs) walk(cl.body);
                case EDo(es): for (e in es) walk(e);
                default:
            }
        }
        walk(body);
        return s;
    }

    static inline function looksLikeHtml(s:String):Bool {
        if (s == null) return false;
        var t = StringTools.trim(s);
        return t.indexOf("<") != -1 && t.indexOf(">") != -1;
    }

    static function rewriteHeex(body: ElixirAST, vars: haxe.ds.StringMap<Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = rewriteInterpolations(content, vars);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function rewriteInterpolations(content:String, vars:haxe.ds.StringMap<Bool>):String {
        if (content == null || content.indexOf("<%=") == -1) return content;
        var parts:Array<String> = [];
        var i = 0;
        while (i < content.length) {
            var start = content.indexOf("<%=", i);
            if (start == -1) { parts.push(content.substr(i)); break; }
            parts.push(content.substr(i, start - i));
            var endTag = content.indexOf("%>", start + 3);
            if (endTag == -1) { parts.push(content.substr(start)); break; }
            var inner = StringTools.trim(content.substr(start + 3, endTag - (start + 3)));
            // Simple var name only
            var m = ~/^[A-Za-z_][A-Za-z0-9_]*$/;
            if (m.match(inner)) {
                var name = inner;
                if (vars.exists(name)) {
                    parts.push('<%= Phoenix.HTML.raw(' + name + ') %>');
                } else {
                    parts.push(content.substr(start, (endTag + 2) - start));
                }
            } else {
                parts.push(content.substr(start, (endTag + 2) - start));
            }
            i = endTag + 2;
        }
        return parts.join("");
    }
}

#end
