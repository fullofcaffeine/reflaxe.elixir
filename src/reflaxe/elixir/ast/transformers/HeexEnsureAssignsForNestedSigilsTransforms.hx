package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexEnsureAssignsForNestedSigilsTransforms
 *
 * WHAT
 * - Ensures functions that contain ~H sigils but do not take an `assigns` param
 *   have a local `assigns = %{...}` binding in scope so HEEx compiles without
 *   change-tracking warnings.
 *
 * WHY
 * - Some helpers render small HEEx fragments (for example, a small icon span) inside
 *   branches. When those helpers don't take `assigns`, Phoenix requires a local
 *   `assigns` map. Additionally, accessing external variables inside ~H triggers
 *   Phoenix warnings ("variable X inside a LiveView template"), which often become
 *   hard failures when compiling with `--warnings-as-errors`. This pass:
 *   - creates a minimal assigns map from the function parameters, and
 *   - rewrites ~H embedded Elixir expressions to use assigns (`@var`) instead of
 *     capturing external variables (`var`).
 *
 * HOW
 * - For each EDef/EDefp:
 *   - If no param named `assigns` or `_assigns`, and body subtree contains
 *     ESigil("H", ...):
 *       1) Rewrite ~H content so `<% ... %>`, `<%= ... %>`, and `={...}` blocks
 *          reference function params as assigns (`@param`).
 *       2) Wrap body in a leading block:
 *          assigns = %{param: param, ...}
 *          <original body>
 *
 * EXAMPLES
 * Haxe:
 *   static function renderPost(post:Post) return hxx('<h4>{post.title}</h4>');
 * Elixir (before):
 *   defp render_post(post) do
 *     assigns = %{}
 *     ~H\"\"\"<h4><%= post.title %></h4>\"\"\"
 *   end
 * Elixir (after):
 *   defp render_post(post) do
 *     assigns = %{post: post}
 *     ~H\"\"\"<h4><%= @post.title %></h4>\"\"\"
 *   end
 */
class HeexEnsureAssignsForNestedSigilsTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) | EDefp(name, args, guards, body):
                    var hasAssigns = false;
                    for (a in args) switch (a) {
                        case PVar(p) if (p == "assigns" || p == "_assigns"): hasAssigns = true;
                        default:
                    }
                    if (hasAssigns || !containsHSigilAST(body)) {
                        n;
                    } else {
                        var paramNames = collectSimpleParamNames(args);
                        var rewrittenBody = rewriteNestedHSigilsForAssigns(body, paramNames);
                        var assignsExpr = buildAssignsMapExpr(paramNames);
                        var wrapped = makeAST(EBlock([
                            makeAST(EMatch(PVar("assigns"), assignsExpr)),
                            rewrittenBody
                        ]));
                        var def = Type.enumConstructor(n.def) == "EDef"
                            ? EDef(name, args, guards, wrapped)
                            : EDefp(name, args, guards, wrapped);
                        makeASTWithMeta(def, n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    static function collectSimpleParamNames(args: Array<EPattern>): Array<String> {
        var names: Array<String> = [];
        for (a in args) switch (a) {
            case PVar(p):
                // Ignore assigns and intentionally-unused params.
                if ((p == "assigns") || (p == "_assigns")) continue;
                if (StringTools.startsWith(p, "_")) continue;
                names.push(p);
            default:
        }
        return names;
    }

    static function buildAssignsMapExpr(paramNames: Array<String>): ElixirAST {
        if (paramNames == null || paramNames.length == 0) return makeAST(EMap([]));
        var pairs: Array<EMapPair> = [];
        for (p in paramNames) {
            pairs.push({
                key: makeAST(EAtom(p)),
                value: makeAST(EVar(p))
            });
        }
        return makeAST(EMap(pairs));
    }

    static function rewriteNestedHSigilsForAssigns(node: ElixirAST, paramNames: Array<String>): ElixirAST {
        if (paramNames == null || paramNames.length == 0) return node;
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, mods) if (type == "H" && content != null):
                    var rewritten = rewriteHeexContentParamRefs(content, paramNames);
                    if (rewritten == content) {
                        n;
                    } else {
                        makeASTWithMeta(ESigil(type, rewritten, mods), n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    static function rewriteHeexContentParamRefs(content: String, paramNames: Array<String>): String {
        if (content == null || paramNames == null || paramNames.length == 0) return content;

        var out = new StringBuf();
        var i = 0;
        while (i < content.length) {
            // EEx blocks: <%= ... %>, <% ... %>, skip <%# ... %> comments.
            if (i + 1 < content.length && content.charAt(i) == "<" && content.charAt(i + 1) == "%") {
                var close = content.indexOf("%>", i + 2);
                if (close == -1) {
                    out.add(content.substr(i));
                    break;
                }

                var prefixEnd = i + 2;
                // Handle "<%=" and "<%-" prefixes (keep as-is, but rewrite body).
                if (prefixEnd < content.length && (content.charAt(prefixEnd) == "=" || content.charAt(prefixEnd) == "-")) {
                    prefixEnd++;
                }

                var isComment = (i + 2 < content.length && content.charAt(i + 2) == "#");
                if (isComment) {
                    out.add(content.substr(i, close + 2 - i));
                } else {
                    var inner = content.substr(prefixEnd, close - prefixEnd);
                    var rewrittenInner = rewriteElixirExprParamRefs(inner, paramNames);
                    out.add(content.substr(i, prefixEnd - i));
                    out.add(rewrittenInner);
                    out.add("%>");
                }

                i = close + 2;
                continue;
            }

            // Attribute expressions: ...={ ... } (including output from TemplateHelpers rewrites).
            if (i + 1 < content.length && content.charAt(i) == "=" && content.charAt(i + 1) == "{") {
                var parsed = findMatchingBrace(content, i + 1);
                if (parsed == -1) {
                    out.add(content.charAt(i));
                    i++;
                    continue;
                }
                var inner = content.substr(i + 2, parsed - (i + 2));
                var rewrittenInner = rewriteElixirExprParamRefs(inner, paramNames);
                out.add("={");
                out.add(rewrittenInner);
                out.add("}");
                i = parsed + 1;
                continue;
            }

            out.add(content.charAt(i));
            i++;
        }

        return out.toString();
    }

    static function findMatchingBrace(s: String, openBraceIndex: Int): Int {
        var depth = 0;
        var inDouble = false;
        var inSingle = false;
        var escaped = false;
        for (i in openBraceIndex...s.length) {
            var ch = s.charAt(i);
            if (escaped) {
                escaped = false;
                continue;
            }
            if (inDouble) {
                if (ch == "\\") {
                    escaped = true;
                } else if (ch == "\"") {
                    inDouble = false;
                }
                continue;
            }
            if (inSingle) {
                if (ch == "\\") {
                    escaped = true;
                } else if (ch == "'") {
                    inSingle = false;
                }
                continue;
            }

            switch (ch) {
                case "\"": inDouble = true;
                case "'": inSingle = true;
                case "{":
                    depth++;
                case "}":
                    depth--;
                    if (depth == 0) return i;
                default:
            }
        }
        return -1;
    }

    static function rewriteElixirExprParamRefs(code: String, paramNames: Array<String>): String {
        if (code == null || code.length == 0) return code;
        if (paramNames == null || paramNames.length == 0) return code;

        // Small optimization: only do work if any param appears as a substring.
        var mightContain = false;
        for (p in paramNames) if (p != null && p.length > 0 && code.indexOf(p) != -1) { mightContain = true; break; }
        if (!mightContain) return code;

        var out = new StringBuf();
        var i = 0;
        var inDouble = false;
        var inSingle = false;
        var escaped = false;

        inline function isIdentStart(ch: String): Bool {
            if (ch == "_") return true;
            var c = ch.charCodeAt(0);
            return (c >= 97 && c <= 122) || (c >= 65 && c <= 90);
        }
        inline function isIdentChar(ch: String): Bool {
            if (ch == "_") return true;
            var c = ch.charCodeAt(0);
            return (c >= 97 && c <= 122) || (c >= 65 && c <= 90) || (c >= 48 && c <= 57);
        }
        inline function isWhitespace(ch: String): Bool {
            return ch == " " || ch == "\t" || ch == "\n" || ch == "\r";
        }
        function skipWs(idx: Int): Int {
            var j = idx;
            while (j < code.length && isWhitespace(code.charAt(j))) j++;
            return j;
        }
        function isBindingPosition(tokenEnd: Int): Bool {
            var j = skipWs(tokenEnd);
            if (j >= code.length) return false;
            var ch = code.charAt(j);
            if (ch == "=") return true;
            if (ch == "<" && j + 1 < code.length && code.charAt(j + 1) == "-") return true;
            if (ch == "-" && j + 1 < code.length && code.charAt(j + 1) == ">") return true;
            return false;
        }
        function isParamName(name: String): Bool {
            return paramNames.indexOf(name) != -1;
        }

        while (i < code.length) {
            var ch = code.charAt(i);
            if (escaped) {
                out.add(ch);
                escaped = false;
                i++;
                continue;
            }
            if (inDouble) {
                out.add(ch);
                if (ch == "\\") escaped = true;
                else if (ch == "\"") inDouble = false;
                i++;
                continue;
            }
            if (inSingle) {
                out.add(ch);
                if (ch == "\\") escaped = true;
                else if (ch == "'") inSingle = false;
                i++;
                continue;
            }

            if (ch == "\"") {
                inDouble = true;
                out.add(ch);
                i++;
                continue;
            }
            if (ch == "'") {
                inSingle = true;
                out.add(ch);
                i++;
                continue;
            }

            if (isIdentStart(ch)) {
                var start = i;
                var j = i + 1;
                while (j < code.length && isIdentChar(code.charAt(j))) j++;
                var token = code.substr(start, j - start);
                var prev = start > 0 ? code.charAt(start - 1) : "";
                var next = j < code.length ? code.charAt(j) : "";

                var shouldRewrite = isParamName(token)
                    && prev != "@"
                    && prev != ":"
                    && next != ":"
                    && !isBindingPosition(j);

                if (shouldRewrite) {
                    out.add("@");
                }
                out.add(token);
                i = j;
                continue;
            }

            out.add(ch);
            i++;
        }
        return out.toString();
    }

    static function containsHSigilAST(node: ElixirAST):Bool {
        var found = false;
        function walk(n: ElixirAST):Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case ESigil(type, _, _) if (type == "H"): found = true; return;
                case EBlock(es): for (e in es) walk(e);
                case EIf(c, t, e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(e, cs): walk(e); for (cl in cs) walk(cl.body);
                case EDo(b): for (e in b) walk(e);
                case EParen(inner): walk(inner);
                case ECall(t, _, as): if (t != null) walk(t); for (a in as) walk(a);
                case ERemoteCall(m, _, as): walk(m); for (a in as) walk(a);
                case EBinary(_, l, r): walk(l); walk(r);
                case EList(el): for (e in el) walk(e);
                case ETuple(el): for (e in el) walk(e);
                case EMap(p): for (kv in p) { walk(kv.key); walk(kv.value);} 
                case EStruct(_, fs): for (f in fs) walk(f.value);
                case EFn(cs): for (cl in cs) walk(cl.body);
                default:
            }
        }
        walk(node);
        return found;
    }
}

#end
