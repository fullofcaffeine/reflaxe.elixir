package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexInlineRawForHeexVarsInStringsTransforms
 *
 * WHAT
 * - Before converting string returns to ~H, rewrite occurrences of
 *   "#{var}" inside EString where `var` is known to be bound from ~H or
 *   HTML string earlier in the same function, into
 *   "#{Phoenix.HTML.raw(var)}".
 *
 * WHY
 * - Prevents String.Chars conversion errors when interpolating a
 *   %Phoenix.LiveView.Rendered{} into a string. Also ensures HTML-like
 *   strings render unescaped when later transformed to ~H.
 *
 * HOW
 * - For each EDef/EDefp:
 *   - Collect variable names: name = ~H"..." or name = "<...>" (html-like)
 *   - Traverse and update EString nodes: replace all #{name} with
 *     #{Phoenix.HTML.raw(name)}.
 */
class HeexInlineRawForHeexVarsInStringsTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var vars = collectVars(body);
                    makeASTWithMeta(EDef(name, args, guards, rewriteStrings(body, vars)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    var vars2 = collectVars(body);
                    makeASTWithMeta(EDefp(name, args, guards, rewriteStrings(body, vars2)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectVars(body: ElixirAST): haxe.ds.StringMap<Bool> {
        var s = new haxe.ds.StringMap<Bool>();
        function add(name:String):Void { if (!s.exists(name)) s.set(name, true); }
        function looksLikeHtml(str:String):Bool {
            if (str == null) return false; var t = StringTools.trim(str);
            return t.indexOf("<") != -1 && t.indexOf(">") != -1;
        }
        function rhsHasHeexLike(n: ElixirAST):Bool {
            var found = false;
            function scan(x: ElixirAST):Void {
                if (found || x == null || x.def == null) return;
                switch (x.def) {
                    case ESigil(type, _, _) if (type == "H"): found = true; return;
                    case EString(s) if (looksLikeHtml(s)): found = true; return;
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

    static function rewriteStrings(body: ElixirAST, vars:haxe.ds.StringMap<Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EString(s) if (s != null && s.indexOf("#") != -1):
                    var updated = s;
                    for (k in vars.keys()) {
                        updated = updated.split("#{" + k + "}").join("#{Phoenix.HTML.raw(" + k + ")}");
                    }
                    if (updated != s) makeASTWithMeta(EString(updated), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }
}

#end
