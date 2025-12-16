package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexStringReturnToSigilTransforms
 *
 * WHAT
 * - Converts functions that return plain HTML strings into ~H sigil blocks so HEEx can
 *   compile them properly. Supports simple cases where the final expression (or if-branches)
 *   are string literals (optionally parenthesized) that contain HTML-like markup.
 *
 * WHY
 * - Returning raw strings from helper functions and embedding them in ~H causes escaping, so
 *   literal tags appear in the browser. Converting these helpers to return ~H ensures the
 *   content is treated as HEEx and renders correctly without Phoenix.HTML.raw.
 *
 * HOW
 * - For EDef/EDefp bodies:
 *   - Detect EString/EParen(EString) as the final expression (and within EIf branches).
 *   - If the string content looks like HTML/HEEx (contains '<' and '>'), convert to
 *     ESigil("H", converted, "") where converted:
 *       • replaces #{...} and ${...} with <%= ... %>
 *       • rewrites assigns.* to @
 *   - Preserve metadata and parens depth.
 */
class HeexStringReturnToSigilTransforms {
    static function looksLikeHtml(s:String):Bool {
        if (s == null) return false;
        var t = StringTools.trim(s);
        // Heuristic: contains a tag-like pair and not just text
        return t.indexOf("<") != -1 && t.indexOf(">") != -1;
    }

    static function convertInterpolations(s:String):String {
        if (s == null) return s;
        // Fast-path: if no interpolation tokens are present, avoid scanning
        if (s.indexOf("${") == -1 && s.indexOf("#{") == -1) return s;
        #if hxx_instrument
        var t0 = haxe.Timer.stamp();
        var loops = 0;
        #end
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            #if hxx_instrument loops++; #end
            var j1 = s.indexOf("#{", i);
            var j2 = s.indexOf("${", i);
            var j = (j1 == -1) ? j2 : (j2 == -1 ? j1 : (j1 < j2 ? j1 : j2));
            if (j == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, j - i));
            var k = j + 2;
            var depth = 1;
            while (k < s.length && depth > 0) {
                var ch = s.charAt(k);
                if (ch == '{') depth++;
                else if (ch == '}') depth--;
                k++;
            }
            var raw = s.substr(j + 2, (k - 1) - (j + 2));
            var expr = StringTools.trim(raw);
            // Special case: ternary inside interpolation → HEEx block if
            var ternary = splitTopLevelTernary(expr);
            if (ternary != null) {
                var cond = mapAssigns(ternary.cond);
                var thenPart = StringTools.trim(ternary.thenPart);
                var elsePart = StringTools.trim(ternary.elsePart);
                var thenHtml = extractBlockHtml(thenPart);
                var elseHtml = extractBlockHtml(elsePart);
                // Fallback: if extraction failed, treat as expression
                if (thenHtml == null && elseHtml == null) {
                    parts.push('<%= ' + mapAssigns(expr) + ' %>');
                } else {
                    // Emit block HEEx to avoid quoting/attribute breakage
                    parts.push('<%= if ' + cond + ' do %>');
                    if (thenHtml != null) parts.push(thenHtml);
                    if (elseHtml != null && elseHtml != "") {
                        parts.push('<% else %>');
                        parts.push(elseHtml);
                    }
                    parts.push('<% end %>');
                }
            } else {
                parts.push('<%= ' + mapAssigns(expr) + ' %>');
            }
            i = k;
        }
        var res = parts.join("");
        // Post-process any fallback inline ternary
        res = rewriteInlineTernaryToBlock(res);
        // Keep other inline cases as-is for readability
        #if hxx_instrument
        var dt = Std.int((haxe.Timer.stamp() - t0) * 1000);
        // DISABLED: trace('[HXX-INSTR] convertInterpolations: ms=' + dt + ' loops=' + loops + ' inLen=' + (s != null ? s.length : 0) + ' outLen=' + res.length);
        #end
        return res;
    }

    // Extract a plain literal string from an interpolation wrapper like: "<%= ("...") %>"
    static function tryExtractQuotedFromInterpolation(s:String): Null<String> {
        if (s == null) return null;
        var t = StringTools.trim(s);
        if (!StringTools.startsWith(t, "<%=")) return null;
        if (!StringTools.endsWith(t, "%>")) return null;
        // strip the <%= and %>
        t = StringTools.trim(t.substr(3)); // after "<%="
        t = StringTools.trim(t.substr(0, t.length - 2)); // drop trailing "%>"
        // optional surrounding parens
        if (t.length >= 2 && t.charAt(0) == '(' && t.charAt(t.length - 1) == ')') {
            t = StringTools.trim(t.substr(1, t.length - 2));
        }
        // now expect a quoted string
        if (t.length < 2 || t.charAt(0) != '"' || t.charAt(t.length - 1) != '"') return null;
        // unescape a subset of common escapes inside the string literal
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

    // Map assigns.* to @* for HEEx idioms in expressions
    static function mapAssigns(e:String):String {
        return StringTools.replace(e, "assigns.", "@");
    }

    // Extract a top-level ternary split: cond ? then : else
    static function splitTopLevelTernary(e:String):Null<{cond:String, thenPart:String, elsePart:String}> {
        var depth = 0;
        var inS = false, inD = false;
        var q = -1, c = -1, col = -1;
        for (idx in 0...e.length) {
            var ch = e.charAt(idx);
            // handle quotes
            if (!inS && ch == '"' && !inD) { inD = true; continue; }
            else if (inD && ch == '"') { inD = false; continue; }
            if (!inD && ch == '\'' && !inS) { inS = true; continue; }
            else if (inS && ch == '\'') { inS = false; continue; }
            if (inS || inD) continue;
            // handle paren/braces just enough to avoid splitting inside
            if (ch == '(' || ch == '{' || ch == '[') depth++;
            else if (ch == ')' || ch == '}' || ch == ']') depth--;
            if (depth != 0) continue;
            if (ch == '?' && q == -1) { q = idx; }
            else if (ch == ':' && q != -1) { col = idx; break; }
        }
        if (q == -1 || col == -1) return null;
        var cond = StringTools.trim(e.substr(0, q));
        var thenPart = StringTools.trim(e.substr(q + 1, col - (q + 1)));
        var elsePart = StringTools.trim(e.substr(col + 1));
        return { cond: cond, thenPart: thenPart, elsePart: elsePart };
    }

    // If part is HXX.block('...') or a quoted string, extract inner HTML; else null
    static function extractBlockHtml(part:String):Null<String> {
        if (part == null || part == "") return "";
        // HXX.block('...') or HXX.block("...")
        var p = part;
        if (StringTools.startsWith(p, "HXX.block(")) {
            var start = p.indexOf('(') + 1;
            var end = p.lastIndexOf(')');
            if (start > 0 && end > start) {
                var inner = StringTools.trim(p.substr(start, end - start));
                return unquote(inner);
            }
        }
        // plain quoted string
        var uq = unquote(p);
        if (uq != null) return uq;
        return null;
    }

    static function unquote(s:String):Null<String> {
        if (s.length >= 2) {
            var a = s.charAt(0);
            var b = s.charAt(s.length - 1);
            if ((a == '"' && b == '"') || (a == '\'' && b == '\'')) {
                return s.substr(1, s.length - 2);
            }
        }
        return null;
    }

    // Rewrite occurrences of <%= cond ? then : else %> into block HEEx, supporting HXX.block('...') and quoted strings
    static function rewriteInlineTernaryToBlock(s:String):String {
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var start = s.indexOf("<%=", i);
            if (start == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, start - i));
            var endTag = s.indexOf("%>", start + 3);
            if (endTag == -1) { parts.push(s.substr(start)); break; }
            var inner = StringTools.trim(s.substr(start + 3, endTag - (start + 3)));
            var t = splitTopLevelTernary(inner);
            if (t != null) {
                var cond = mapAssigns(t.cond);
                var th = extractBlockHtml(StringTools.trim(t.thenPart));
                var el = extractBlockHtml(StringTools.trim(t.elsePart));
                if (th != null || el != null) {
                    parts.push('<%= if ' + cond + ' do %>');
                    if (th != null) parts.push(th);
                    if (el != null && el != "") {
                        parts.push('<% else %>');
                        parts.push(el);
                    }
                    parts.push('<% end %>');
                } else {
                    parts.push(s.substr(start, (endTag + 2) - start));
                }
            } else {
                parts.push(s.substr(start, (endTag + 2) - start));
            }
            i = endTag + 2;
        }
        return parts.join("");
    }

    // Rewrite occurrences of <%= if cond, do: "...", else: "..." %> into a block if
    static function rewriteInlineIfDoToBlock(s:String):String {
        return s;
    }

    // NOTE: Avoid regex-based inline-if rewrites; block-if is emitted structurally above.

    // Return {value, length} for first quoted token in s (single or double quotes)
    static function extractQuoted(s:String):Null<{value:String, length:Int}> {
        if (s.length == 0) return null;
        var quote = s.charAt(0);
        if (quote != '"' && quote != '\'') return null;
        var i = 1;
        while (i < s.length) {
            var ch = s.charAt(i);
            var prev = s.charAt(i - 1);
            if (ch == quote && prev != '\\') {
                var val = s.substr(1, i - 1);
                return { value: val, length: i + 1 };
            }
            i++;
        }
        return null;
    }

    // Find index of token when not inside quotes or brackets
    static function indexOfTopLevel(s:String, token:String):Int {
        var depth = 0;
        var inS = false, inD = false;
        for (i in 0...s.length - token.length + 1) {
            var ch = s.charAt(i);
            if (!inS && ch == '"' && !inD) { inD = true; continue; }
            else if (inD && ch == '"') { inD = false; continue; }
            if (!inD && ch == '\'' && !inS) { inS = true; continue; }
            else if (inS && ch == '\'') { inS = false; continue; }
            if (inS || inD) continue;
            if (ch == '(' || ch == '{' || ch == '[') depth++;
            else if (ch == ')' || ch == '}' || ch == ']') depth--;
            if (depth != 0) continue;
            if (s.substr(i, token.length) == token) return i;
        }
        return -1;
    }

    static function toHeex(node: ElixirAST): ElixirAST {
        // unwrap parens to find string
        var cur = node;
        var parens = 0;
        while (true) {
            switch (cur.def) {
                case EParen(inner): cur = inner; parens++;
                default: break;
            }
            if (Type.enumConstructor(cur.def) != "EParen") break;
        }
        switch (cur.def) {
            case EString(s) if (looksLikeHtml(s)):
                var conv = convertInterpolations(s);
                // Flatten any nested ~H sigils introduced by helper conversions
                conv = flattenNestedHeexSigil(conv);
                var rebuilt: ElixirAST = makeAST(ESigil("H", conv, ""));
                while (parens-- > 0) rebuilt = makeAST(EParen(rebuilt));
                return makeASTWithMeta(rebuilt.def, node.metadata, node.pos);
            default:
                return node;
        }
    }

    static function transformBody(ret: ElixirAST, ensureAssigns: Bool): ElixirAST {
        return ElixirASTTransformer.transformNode(ret, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenB, elseB):
                    // Do not convert arbitrary inner if-expressions to ~H to avoid producing
                    // Phoenix.LiveView.Rendered locals. Only the final return point is eligible.
                    var newThen = transformBody(thenB, ensureAssigns);
                    var newElse = elseB != null ? transformBody(elseB, ensureAssigns) : null;
                    makeASTWithMeta(EIf(cond, newThen, newElse), n.metadata, n.pos);
                case EBlock(stmts):
                    if (stmts.length == 0) return n;
                    var last = stmts[stmts.length - 1];
                    var convertedLast = last;
                    // If the last expression is an if with string branches, convert it to ~H.
                    var tryIf = tryConvertIfToHeex(last);
                    if (tryIf != null) {
                        convertedLast = tryIf;
                    } else {
                        // Try converting HXX.hxx("...") call to ~H directly when present as final expr
                        var tryHxx = tryConvertHxxCallToHeex(last);
                        if (tryHxx != null) {
                            convertedLast = tryHxx;
                        } else {
                            // If final expr is a variable bound to an HTML-like string earlier, wrap it into ~H with raw(var)
                            var tryVar = tryConvertVarToHeex(stmts, last);
                            convertedLast = tryVar != null ? tryVar : toHeex(last);
                        }
                    }
                    if (convertedLast == last) return n;
                    var newStmts = stmts.copy();
                    // If assigns is required and not provided by params, inject minimal map
                    if (ensureAssigns) newStmts.insert(newStmts.length - 1, makeAST(EMatch(PVar("assigns"), makeAST(EMap([])))));
                    newStmts[newStmts.length - 1] = convertedLast;
                    makeASTWithMeta(EBlock(newStmts), n.metadata, n.pos);
                case EParen(inner):
                    // Do not convert arbitrary parenthesized strings to ~H here to avoid
                    // turning local string bindings into Phoenix.LiveView.Rendered.
                    // Restrict ~H conversion to final returns (EBlock last expr) and
                    // top-level if-branches converted by tryConvertIfToHeex.
                    makeASTWithMeta(EParen(transformBody(inner, ensureAssigns)), n.metadata, n.pos);
                case EString(_):
                    // Avoid blanket conversion of inner string literals. They may be bound to
                    // locals and later interpolated into larger HTML strings or ~H at the call-site.
                    n;
                default:
                    n;
            }
        });
    }

    // Convert final HXX.hxx("...") call into ESigil("H", ...) when encountered
    static function tryConvertHxxCallToHeex(node: ElixirAST): Null<ElixirAST> {
        switch (node.def) {
            case ECall(mod, fnName, args) if (fnName == "hxx" && args != null && args.length >= 1):
                // HXX.hxx(template)
                var isHxx = false;
                if (mod != null) switch (mod.def) {
                    case EVar(m) if (m == "HXX"): isHxx = true;
                    case EField(_, fld) if (fld == "HXX"): isHxx = true;
                    default:
                }
                if (!isHxx) return null;
                // Collect content and normalize control tags
                var content = reflaxe.elixir.ast.TemplateHelpers.collectTemplateContent(args[0]);
                content = reflaxe.elixir.ast.transformers.HeexControlTagTransforms.rewrite(content);
                return makeASTWithMeta(ESigil("H", content, ""), node.metadata, node.pos);
            default:
                return null;
        }
    }

    // If last expression is EVar(name) and we can find a recent assignment
    //   name = "<html ...>" or name = HXX.hxx("...")
    // convert the final return into ~H with raw(name) so LiveView receives a Rendered.
    static function tryConvertVarToHeex(stmts: Array<ElixirAST>, last: ElixirAST): Null<ElixirAST> {
        switch (last.def) {
            case EVar(varName):
                // Scan backwards for the most recent assignment to varName
                for (i in (stmts.length - 2)...-1) {
                    // Haxe for-range reversed workaround
                }
                var i = stmts.length - 2;
                while (i >= 0) {
                    switch (stmts[i].def) {
                        case EBinary(Match, l, r):
                            switch (l.def) { case EVar(lhs) if (lhs == varName):
                                // Check RHS shape
                                switch (r.def) {
                                    case EString(s) if (looksLikeHtml(s)):
                                        return makeASTWithMeta(ESigil("H", '<%= Phoenix.HTML.raw(' + varName + ') %>', ""), last.metadata, last.pos);
                                    case ECall(m, f, a) if (f == "hxx"):
                                        var isHxx = false;
                                        if (m != null) switch (m.def) {
                                            case EVar(mm) if (mm == "HXX"): isHxx = true;
                                            case EField(_, fld) if (fld == "HXX"): isHxx = true;
                                            default:
                                        }
                                        if (isHxx) return makeASTWithMeta(ESigil("H", '<%= Phoenix.HTML.raw(' + varName + ') %>', ""), last.metadata, last.pos);
                                    default:
                                }
                            default: }
                        case EMatch(pat, rhs):
                            switch (pat) { case PVar(lhs2) if (lhs2 == varName):
                                switch (rhs.def) {
                                    case EString(s2) if (looksLikeHtml(s2)):
                                        return makeASTWithMeta(ESigil("H", '<%= Phoenix.HTML.raw(' + varName + ') %>', ""), last.metadata, last.pos);
                                    case ECall(m2, f2, a2) if (f2 == "hxx"):
                                        var isHxx2 = false;
                                        if (m2 != null) switch (m2.def) {
                                            case EVar(mm2) if (mm2 == "HXX"): isHxx2 = true;
                                            case EField(_, fld2) if (fld2 == "HXX"): isHxx2 = true;
                                            default:
                                        }
                                        if (isHxx2) return makeASTWithMeta(ESigil("H", '<%= Phoenix.HTML.raw(' + varName + ') %>', ""), last.metadata, last.pos);
                                    default:
                                }
                            default: }
                        default:
                    }
                    i--;
                }
                return null;
            default:
                return null;
        }
    }

    // Attempt to convert an if expression with string branches into a ~H sigil
    static function tryConvertIfToHeex(node: ElixirAST): Null<ElixirAST> {
        switch (node.def) {
            case EIf(cond, thenB, elseB):
                var thenStr:Null<String> = extractString(thenB);
                var elseStr:Null<String> = elseB != null ? extractString(elseB) : "";
                if (thenStr != null && (elseB == null || elseStr != null)) {
                    var parts:Array<String> = [];
                    // Use same mapping utility as in convertInterpolations()
                    parts.push('<%= if ' + mapAssigns(reflaxe.elixir.ast.ElixirASTPrinter.printAST(cond)) + ' do %>');
                    parts.push(reflaxe.elixir.ast.TemplateHelpers.rewriteControlTags(convertInterpolations(thenStr)));
                    if (elseB != null && elseStr != null && elseStr != "") {
                        parts.push('<% else %>');
                        parts.push(reflaxe.elixir.ast.TemplateHelpers.rewriteControlTags(convertInterpolations(elseStr)));
                    }
                    parts.push('<% end %>');
                    return makeAST(ESigil("H", parts.join(""), ""));
                }
            default:
        }
        return null;
    }

    // Replace `<%= ~H""" ... """ %>` with the inner body to avoid nested ~H inside ~H
    static function flattenNestedHeexSigil(s:String):String {
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var open = s.indexOf("<%=", i);
            if (open == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, open - i));
            var close = s.indexOf("%>", open + 3);
            if (close == -1) { parts.push(s.substr(open)); break; }
            var inner = StringTools.trim(s.substr(open + 3, close - (open + 3)));
            if (StringTools.startsWith(inner, "~H\"\"\"")) {
                var start = inner.indexOf("\"\"\"");
                if (start != -1) {
                    var bodyStart = start + 3;
                    var bodyEnd = inner.indexOf("\"\"\"", bodyStart);
                    if (bodyEnd != -1) {
                        var body = inner.substr(bodyStart, bodyEnd - bodyStart);
                        parts.push(body);
                        i = close + 2;
                        continue;
                    }
                }
            }
            parts.push(s.substr(open, (close + 2) - open));
            i = close + 2;
        }
        // Keep inline-if forms intact to match idiomatic HEEx and snapshot intent.
        // Only flatten nested ~H sigils here; do not rewrite inline-if/ternary.
        return parts.join("");
    }

    static function extractString(n: ElixirAST): Null<String> {
        return switch (n.def) {
            case EString(s): s;
            case EParen(inner): extractString(inner);
            default: null;
        }
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) | EDefp(name, args, guards, body):
                    // HEEx requires the parameter to be literally named `assigns`.
                    // We support both `assigns` and `_assigns` (previous passes may underscore it)
                    // and will rename `_assigns` → `assigns` when we actually convert to ~H.
                    var hasAssignsParam = false;
                    var hasUnderscoredAssigns = false;
                    var argsRenamed = args;
                    for (a in args) switch (a) {
                        case PVar(p) if (p == "assigns"): hasAssignsParam = true;
                        case PVar(p) if (p == "_assigns"): hasUnderscoredAssigns = true;
                        default:
                    }
                    // Only convert helpers that already take assigns/_assigns.
                    if (!hasAssignsParam && !hasUnderscoredAssigns) return n;
                    var newBody = transformBody(body, false);
                    // If no change and body itself is a string (or parens-wrapped string), convert to ~H
                    if (newBody == body) {
                        var topLevel = toHeex(body);
                        if (topLevel != body) newBody = topLevel;
                    }
                    if (newBody != body) {
                        if (!hasAssignsParam && hasUnderscoredAssigns) {
                            // Rename `_assigns` → `assigns` in the parameter list to satisfy HEEx
                            var tmp:Array<EPattern> = [];
                            for (a in args) switch (a) {
                                case PVar(p) if (p == "_assigns"): tmp.push(PVar("assigns"));
                                default: tmp.push(a);
                            }
                            argsRenamed = tmp;
                        }
                        var newDef = Type.enumConstructor(n.def) == "EDef"
                            ? EDef(name, argsRenamed, guards, newBody)
                            : EDefp(name, argsRenamed, guards, newBody);
                        makeASTWithMeta(newDef, n.metadata, n.pos);
                    } else {
                        // Fallback: LiveView requires render/1 to return a ~H sigil (%Phoenix.LiveView.Rendered{}),
                        // but some HXX expansions still leave render/1 returning a plain string.
                        //
                        // IMPORTANT: Restrict this to render/1 only (arity=1) so we do not accidentally convert
                        // Phoenix error renderers like ErrorHTML.render/2 or ErrorJSON.render/2 into HEEx.
                        if (name == "render" && args.length == 1 && (hasAssignsParam || hasUnderscoredAssigns)) {
                            if (containsHSigilAST(body)) {
                                n;
                            } else {
                                // Ensure the param name is literally `assigns` when we materialize ~H.
                                if (!hasAssignsParam && hasUnderscoredAssigns) {
                                    var tmp2:Array<EPattern> = [];
                                    for (a in args) switch (a) {
                                        case PVar(p2) if (p2 == "_assigns"): tmp2.push(PVar("assigns"));
                                        default: tmp2.push(a);
                                    }
                                    argsRenamed = tmp2;
                                }

                                // Collect the template content from the AST and emit a ~H sigil.
                                // This path intentionally does NOT require "real" HTML tags up front:
                                // render/1 must return a Rendered struct even for text-only templates.
                                var collected2 = reflaxe.elixir.ast.TemplateHelpers.collectTemplateContent(body);
                                var extracted2 = tryExtractQuotedFromInterpolation(collected2);
                                var content2 = (extracted2 != null) ? extracted2 : collected2;
                                var normalized2 = reflaxe.elixir.ast.transformers.HeexControlTagTransforms.rewrite(content2);
                                var sig2 = makeAST(ESigil("H", normalized2, ""));
                                var newDef2 = Type.enumConstructor(n.def) == "EDef"
                                    ? EDef(name, argsRenamed, guards, sig2)
                                    : EDefp(name, argsRenamed, guards, sig2);
                                makeASTWithMeta(newDef2, n.metadata, n.pos);
                            }
                        } else n;
                    }
                default:
                    n;
            }
        });
    }

    // Detects whether the given AST subtree contains ESigil("H", ...)
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

    // Detects presence of literal HTML-like strings in the subtree
    static function containsHtmlStringLiteral(node: ElixirAST):Bool {
        var found = false;
        function walk(n: ElixirAST):Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EString(s):
                    var t = StringTools.trim(s);
                    if (t.indexOf("<") != -1 && t.indexOf(">") != -1) { found = true; return; }
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
