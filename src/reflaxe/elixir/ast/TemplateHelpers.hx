package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
#if (macro && hxx_instrument_sys)
import reflaxe.elixir.macros.MacroTimingHelper;
#end

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * TemplateHelpers: HXX Template Processing Utilities
 * 
 * WHY: Centralize HXX → HEEx template transformation logic
 * - Separate template concerns from main AST builder
 * - Provide reusable template utilities
 * - Encapsulate HXX-specific patterns
 * 
 * WHAT: Template content collection and transformation
 * - Extract template strings and embedded expressions
 * - Process template arguments
 * - Detect HXX module usage
 * 
 * HOW: Pattern matching on AST nodes to extract template content
 * - Collect string literals for template body
 * - Process embedded <%= %> expressions
 * - Handle template function arguments
 */
class TemplateHelpers {
    
    /**
     * Render an ElixirAST expression into a HEEx-safe Elixir expression string.
     * - Converts assigns.* access to @* for idiomatic HEEx
     * - Handles common expression nodes (vars, fields, calls, literals, binaries, if)
     */
    static function renderExpr(ast: ElixirAST): String {
        return switch (ast.def) {
            case EString(s): '"' + s + '"';
            case EInteger(i): Std.string(i);
            case EFloat(f): Std.string(f);
            case EBoolean(b): b ? "true" : "false";
            case ENil: "nil";
            case EAtom(a):
                // a is ElixirAtom; use its string form with preceding :
                ':' + Std.string(a);
            case EVar(name):
                name;
            case EField(obj, field):
                var base = renderExpr(obj);
                // If base starts with "assigns.", convert to HEEx assigns shorthand
                if (StringTools.startsWith(base, "assigns.")) {
                    '@' + base.substr("assigns.".length) + '.' + field;
                } else if (base == "assigns") {
                    '@' + field;
                } else {
                    base + '.' + field;
                }
            case EAccess(target, key):
                var t = renderExpr(target);
                var k = renderExpr(key);
                // Keep standard access syntax target[key]
                t + "[" + k + "]";
            case ECall(module, func, args):
                var callStr = if (module != null) {
                    switch (module.def) {
                        case EVar(m): m + "." + func;
                        case EField(_, _): renderExpr(module) + "." + func;
                        default: func;
                    }
                } else {
                    func;
                };
                if (args.length > 0) {
                    var argStrs = [];
                    for (arg in args) argStrs.push(renderExpr(arg));
                    callStr + "(" + argStrs.join(", ") + ")";
                } else {
                    callStr + "()";
                }
            case EBinary(op, left, right):
                var l = renderExpr(left);
                var r = renderExpr(right);
                var opStr = switch (op) {
                    case Add: "+";
                    case Subtract: "-";
                    case Multiply: "*";
                    case Divide: "/";
                    case Remainder: "rem";
                    case Power: "**";
                    case Equal: "==";
                    case NotEqual: "!=";
                    case StrictEqual: "===";
                    case StrictNotEqual: "!==";
                    case Less: "<";
                    case Greater: ">";
                    case LessEqual: "<=";
                    case GreaterEqual: ">=";
                    case And: "and";
                    case Or: "or";
                    case AndAlso: "&&";
                    case OrElse: "||";
                    case BitwiseAnd: "&&&";
                    case BitwiseOr: "|||";
                    case BitwiseXor: "^^^";
                    case ShiftLeft: "<<<";
                    case ShiftRight: ">>>";
                    case Concat: "++";
                    case ListSubtract: "--";
                    case StringConcat: "<>";
                    case In: "in";
                    case Match: "=";
                    case Pipe: "|>";
                    case TypeCheck: "::";
                    case When: "when";
                };
                '(' + l + ' ' + opStr + ' ' + r + ')';
            case EIf(condition, thenBranch, elseBranch):
                var c = renderExpr(condition);
                var t = renderExpr(thenBranch);
                var e = elseBranch != null ? renderExpr(elseBranch) : "nil";
                'if ' + c + ', do: ' + t + ', else: ' + e;
            case EParen(inner):
                '(' + renderExpr(inner) + ')';
            default:
                // Fallback: delegate to AST printer for a best-effort representation
                ElixirASTPrinter.print(ast, 0);
        };
    }
    
    /**
     * Collect template content from an ElixirAST node
     * 
     * Processes various AST patterns to extract template strings,
     * handling embedded expressions and string interpolation.
     */
    public static function collectTemplateContent(ast: ElixirAST): String {
        #if (macro && hxx_instrument_sys)
        return MacroTimingHelper.time("TemplateHelpers.collectTemplateContent", () -> collectTemplateContentInternal(ast));
        #else
        return collectTemplateContentInternal(ast);
        #end
    }

    static function collectTemplateContentInternal(ast: ElixirAST): String {
        var __result = switch(ast.def) {
            case EString(s): 
                // Simple string - process interpolations and HXX control tags into HEEx-safe content
                var processed = rewriteInterpolations(s);
                processed = rewriteControlTags(processed);
                processed;
                
            case EBinary(StringConcat, left, right):
                // String concatenation - collect both sides
                var l = collectTemplateContent(left);
                var r = collectTemplateContent(right);
                // Haxe string interpolation turns templates into concatenation, so attribute-level
                // EEx/inspect wrappers can straddle boundaries (e.g. `attr=` in one chunk and
                // `<%= if ... %>` in the next). Re-run interpolation + control-tag rewrites on
                // the joined string so attribute normalization is applied to the full shape.
                var combined = l + r;
                combined = rewriteInterpolations(combined);
                combined = rewriteControlTags(combined);
                combined;
                
            case EIf(condition, thenBranch, elseBranch):
                // Prefer inline-if when then/else are simple HTML strings (including HXX.block)
                var condStr = renderExpr(condition);
                if (StringTools.startsWith(condStr, "assigns.")) condStr = '@' + condStr.substr("assigns.".length);
                // Try to extract simple HTML bodies from branches
                var thenSimple: Null<String> = extractSimpleHtml(thenBranch);
                var elseSimple: Null<String> = (elseBranch != null) ? extractSimpleHtml(elseBranch) : "";
                if (thenSimple != null && elseSimple != null) {
                    '<%= if ' + condStr + ', do: ' + toQuoted(thenSimple) + ', else: ' + toQuoted(elseSimple) + ' %>';
                } else {
                    // Fallback to block-if
                    var thenStr = collectTemplateContent(thenBranch);
                    var elseStr = elseBranch != null ? collectTemplateContent(elseBranch) : "";
                    var parts = [];
                    parts.push('<%= if ' + condStr + ' do %>');
                    parts.push(thenStr);
                    if (elseStr != null && elseStr != "") {
                        parts.push('<% else %>');
                        parts.push(elseStr);
                    }
                    parts.push('<% end %>');
                    parts.join("");
                }

            case ECall(module, func, args):
                // Special handling for nested HXX helpers: HXX.block('...') or hxx.HXX.block('...')
                var isHxxModule = false;
                if (module != null) switch (module.def) {
                    case EVar(m): isHxxModule = (m == "HXX");
                    case EField(_, fld): isHxxModule = (fld == "HXX");
                    default:
                }
                if (isHxxModule && (func == "block" || func == "hxx") && args.length >= 1) {
                    var inner = collectTemplateContent(args[0]);
                    return rewriteControlTags(inner);
                }
                // Generic call rendering with block-arg wrapping for validity in template interpolation
                var callStr = (function() {
                    var callHead = if (module != null) {
                        switch (module.def) {
                            case EVar(m): m + "." + func;
                            case EField(_, _): renderExpr(module) + "." + func;
                            default: func;
                        }
                    } else func;
                    function renderArgForTemplate(a: ElixirAST): String {
                        return switch (a.def) {
                            case EIf(_, _, _):
                                // `if cond, do: ..., else: ...` must be parenthesized when used as an argument,
                                // otherwise the commas are parsed as additional function arguments.
                                '(' + renderExpr(a) + ')';
                            case EBlock(sts) if (sts != null && sts.length > 1):
                                // Wrap multi-statement blocks as IIFE to form a single expression
                                '(fn -> ' + StringTools.rtrim(ElixirASTPrinter.print(a, 0)) + ' end).()';
                            case EParen(inner) if (switch (inner.def) { case EBlock(es) if (es.length > 1): true; default: false; }):
                                '(fn -> ' + StringTools.rtrim(ElixirASTPrinter.print(inner, 0)) + ' end).()';
                            default:
                                renderExpr(a);
                        }
                    }
                    var parts = [];
                    for (a in args) parts.push(renderArgForTemplate(a));
                    return callHead + '(' + parts.join(', ') + ')';
                })();
                if (StringTools.startsWith(callStr, "assigns.")) callStr = '@' + callStr.substr("assigns.".length);
                '<%= ' + callStr + ' %>';

            case ERemoteCall(module, func, args):
                // Render remote calls similarly to ECall, with arg block wrapping
                var head = renderExpr(module) + "." + func;
                function renderArg2(a: ElixirAST): String {
                    return switch (a.def) {
                        case EIf(_, _, _):
                            '(' + renderExpr(a) + ')';
                        case EBlock(sts) if (sts != null && sts.length > 1):
                            '(fn -> ' + StringTools.rtrim(ElixirASTPrinter.print(a, 0)) + ' end).()';
                        case EParen(inner) if (switch (inner.def) { case EBlock(es) if (es.length > 1): true; default: false; }):
                            '(fn -> ' + StringTools.rtrim(ElixirASTPrinter.print(inner, 0)) + ' end).()';
                        default:
                            renderExpr(a);
                    }
                }
                var argList2 = [];
                for (a in args) argList2.push(renderArg2(a));
                var full = head + '(' + argList2.join(', ') + ')';
                if (StringTools.startsWith(full, "assigns.")) full = '@' + full.substr("assigns.".length);
                '<%= ' + full + ' %>';

            case EVar(_)
                | EField(_, _)
                | EInteger(_)
                | EFloat(_)
                | EBoolean(_)
                | ENil
                | EAtom(_)
                | EBinary(_, _, _)
                | EParen(_):
                // Expression inside template – render as HEEx interpolation
                var exprStr = renderExpr(ast);
                // Map assigns.* to @* for HEEx idioms
                if (StringTools.startsWith(exprStr, "assigns.")) {
                    exprStr = '@' + exprStr.substr("assigns.".length);
                }
                '<%= ' + exprStr + ' %>';
                
            default:
                // Fallback: embed expression in interpolation using generic renderer
                var exprAny = renderExpr(ast);
                if (StringTools.startsWith(exprAny, "assigns.")) exprAny = '@' + exprAny.substr("assigns.".length);
                '<%= ' + exprAny + ' %>';
        };
        return __result;
    }

    /**
     * Convert #{...} and ${...} interpolations into HEEx <%= ... %> and map assigns.* → @*
     * Also rewrites inline ternary to block HEEx when then/else are string or HXX.block.
     */
    public static function rewriteInterpolations(s:String):String {
        #if (macro && hxx_instrument_sys)
        return MacroTimingHelper.time("TemplateHelpers.rewriteInterpolations", () -> rewriteInterpolationsInternal(s));
        #else
        return rewriteInterpolationsInternal(s);
        #end
    }

	    static function rewriteInterpolationsInternal(s:String):String {
	        if (s == null) return s;
	        // Fix up stray trailing quotes after brace-style attribute expressions (`attr={expr}"`),
	        // which can occur when string concatenations are nested and the closing quote lands in
	        // a later chunk after the `<%=` marker has already been rewritten away.
	        s = rewriteAttributeBraceTrailingQuotes(s);
	        // NOTE: Even when there are no explicit `${...}` / `#{...}` markers, Haxe string interpolation
	        // inside an HXX template (e.g. `value=${assigns.query}`) becomes string concatenation and
	        // we may have already emitted `<%= ... %>` fragments (via collectTemplateContent).
	        // We still need to run attribute-level rewrites so `attr=<%= expr %>` becomes `attr={expr}`.
        if (s.indexOf("${") == -1 && s.indexOf("#{") == -1 && s.indexOf("<for {") == -1 && s.indexOf("<%") == -1) {
            return s;
        }
        s = rewriteAttributeInterpolations(s);
        s = rewriteAttributeEexInterpolations(s);
        s = rewriteForBlocks(s);
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var j1 = s.indexOf("#{", i);
            var j2 = s.indexOf("${", i);
            var j = (j1 == -1) ? j2 : (j2 == -1 ? j1 : (j1 < j2 ? j1 : j2));
            if (j == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, j - i));
            var k = j + 2;
            var depth = 1;
            while (k < s.length && depth > 0) {
                var ch = s.charAt(k);
                if (ch == "{") depth++; else if (ch == "}") depth--;
                k++;
            }
            var inner = s.substr(j + 2, (k - 1) - (j + 2));
            var expr = StringTools.trim(inner);
            if (expr.length >= 2 && expr.charAt(0) == '"' && expr.charAt(1) == '<') {
                #if macro
                haxe.macro.Context.error("HXX: injecting HTML via string inside interpolation is not allowed. Use HXX.block('...') or inline markup.", haxe.macro.Context.currentPos());
                #else
                throw "HXX: injecting HTML via string inside interpolation is not allowed. Use HXX.block('...') or inline markup.";
                #end
            }
            var tern = splitTopLevelTernary(expr);
            if (tern != null) {
                var cond = StringTools.replace(tern.cond, "assigns.", "@");
                var th = extractBlockHtml(StringTools.trim(tern.thenPart));
                var el = extractBlockHtml(StringTools.trim(tern.elsePart));
                if (th != null || el != null) {
                    var thenQ = (th != null) ? toQuoted(th) : '""';
                    var elseQ = (el != null && el != "") ? toQuoted(el) : '""';
                    parts.push('<%= if ' + cond + ', do: ' + thenQ + ', else: ' + elseQ + ' %>');
                } else {
                    parts.push('<%= ' + StringTools.replace(expr, "assigns.", "@") + ' %>');
                }
            } else {
                parts.push('<%= ' + StringTools.replace(expr, "assigns.", "@") + ' %>');
            }
            i = k;
        }
        return parts.join("");
    }

    /**
     * Rewrite <for {pattern in expr}> ... </for> to HEEx for-blocks.
     * Supports simple patterns like `todo in list` or `item in some_call()`.
     */
    public static function rewriteForBlocks(src:String):String {
        #if (macro && hxx_instrument_sys)
        return MacroTimingHelper.time("TemplateHelpers.rewriteForBlocks", () -> rewriteForBlocksInternal(src));
        #else
        return rewriteForBlocksInternal(src);
        #end
    }

    static function rewriteForBlocksInternal(src:String):String {
        if (src == null || src.indexOf("<for {") == -1) return src;
        // Similar to <if>, the iterator expression can be produced by Haxe string
        // interpolation and arrive as a single EEx interpolation, e.g.:
        //   <for {item in <%= assigns.items %>}> ... </for>
        // Unwrap it so the generated HEEx is valid.
        function unwrapSingleEexInterpolation(expr:String):String {
            if (expr == null) return expr;
            var trimmed = StringTools.trim(expr);
            var single = ~/^<%=\s*(.*?)\s*%>$/s;
            if (single.match(trimmed)) {
                return StringTools.trim(single.matched(1));
            }
            return expr;
        }
        var chunks:Array<String> = [];
        var i = 0;
        while (i < src.length) {
            var start = src.indexOf("<for {", i);
            if (start == -1) { chunks.push(src.substr(i)); break; }
            chunks.push(src.substr(i, start - i));
            var headEnd = src.indexOf("}>", start);
            if (headEnd == -1) { chunks.push(src.substr(start)); break; }
            var headInner = src.substr(start + 6, headEnd - (start + 6));
            var closeTag = src.indexOf("</for>", headEnd + 2);
            if (closeTag == -1) { chunks.push(src.substr(start)); break; }
            var body = src.substr(headEnd + 2, closeTag - (headEnd + 2));
            var binding = headInner.split(" in ");
            if (binding.length != 2) {
                chunks.push(src.substr(start, (closeTag + 6) - start));
                i = closeTag + 6;
                continue;
            }
            var pattern = StringTools.trim(binding[0]);
            var iterator = StringTools.trim(binding[1]);
            iterator = unwrapSingleEexInterpolation(iterator);
            iterator = StringTools.replace(iterator, "assigns.", "@");
            iterator = ~/\bnull\b/g.replace(iterator, "nil");
            var lenProp = ~/(@?[A-Za-z0-9_\.]+)\.length\b/g;
            iterator = lenProp.map(iterator, function (re) {
                return 'length(' + re.matched(1) + ')';
            });
            // In HEEx, comprehensions must be output with `<%=` so the rendered
            // iodata is included in the template (plain `<%` triggers warnings
            // and results in no output).
            chunks.push("<%= for " + pattern + " <- " + iterator + " do %>");
            chunks.push(rewriteForBlocksInternal(body));
            chunks.push("<% end %>");
            i = closeTag + 6;
        }
        return chunks.join("");
    }

    // Convert attribute values written as <%= ... %> (and conditional blocks) into HEEx { ... }
	    static function rewriteAttributeEexInterpolations(s:String):String {
	        if (s == null || s.indexOf("<%") == -1) return s;
        // Normalize common wrappers introduced by Haxe string interpolation so boolean
        // attributes remain booleans (e.g. selected/checked/disabled).
        function normalizeAttrExpr(expr:String):String {
            var e = StringTools.trim(expr);
            // Unwrap (fn -> ... end).()
            var iife = ~/^\(fn\s*->\s*(.*?)\s*end\)\.\(\)\s*$/s;
            if (iife.match(e)) e = StringTools.trim(iife.matched(1));
            // Unwrap inspect(...)
            var inspectWrap = ~/^(?:Kernel\.)?inspect\((.*)\)\s*$/s;
            if (inspectWrap.match(e)) e = StringTools.trim(inspectWrap.matched(1));
            // Unwrap to_string(...)
            var toStringWrap = ~/^(?:Kernel\.)?to_string\((.*)\)\s*$/s;
            if (toStringWrap.match(e)) e = StringTools.trim(toStringWrap.matched(1));
            // Unwrap Abstract-to-string helpers emitted as `<Module>_Impl_.to_string(value)`
            // when the attribute ultimately wants the raw value (HEEx `{expr}`), not a binary.
            var implToStringWrap = ~/^[A-Za-z0-9_\.]+_Impl_\.to_string\((.*)\)\s*$/s;
            if (implToStringWrap.match(e)) e = StringTools.trim(implToStringWrap.matched(1));
            return e;
        }

        function isQuoted(v:String):Bool {
            var t = StringTools.trim(v);
            return (StringTools.startsWith(t, "\"") && StringTools.endsWith(t, "\"")) || (StringTools.startsWith(t, "'") && StringTools.endsWith(t, "'"));
        }

        function quoteWrap(v:String):String {
            var t = StringTools.trim(v);
            if (t == "") return "\"\"";
            if (isQuoted(t)) return t;
            if (t == "nil" || t == "null") return "nil";
            if (t == "true" || t == "false") return t;
            return "\"" + t + "\"";
        }

        function branchToExpr(raw:String):String {
            var t = StringTools.trim(raw);
            var single = ~/^<%=\s*(.*?)\s*%>$/s;
            if (single.match(t)) {
                return normalizeAttrExpr(single.matched(1));
            }
            return quoteWrap(t);
        }

        // Scan rather than regex so nested `%{}` and multi-tag if blocks don't break.
        var parts:Array<String> = [];
        var i = 0;
	        while (i < s.length) {
	            var j = s.indexOf("<%", i);
	            if (j == -1) { parts.push(s.substr(i)); break; }

            // Determine if this <% ... %> is directly after an '=' in an attribute context,
            // without crossing a tag close '>'.
            var k = j - 1;
            var seenGt = false;
            while (k >= i) {
                var ch = s.charAt(k);
                if (ch == '>') { seenGt = true; break; }
                if (ch == '=') break;
                k--;
            }

            if (k < i || seenGt || s.charAt(k) != '=') {
                // Not an attribute context; copy and continue past this EEx opener.
                parts.push(s.substr(i, j - i));
                parts.push("<%");
                i = j + 2;
                continue;
            }

            // We're in an attribute value context. Copy prefix up to '='
            parts.push(s.substr(i, (k - i) + 1));

            // Optional opening quote after '='
            var vpos = k + 1;
            while (vpos < s.length && ~/^\s$/.match(s.charAt(vpos))) vpos++;
            var quote: Null<String> = null;
            if (vpos < s.length && (s.charAt(vpos) == '"' || s.charAt(vpos) == '\'')) { quote = s.charAt(vpos); vpos++; }

            // Expect vpos == j
            if (vpos != j) {
                // Unexpected; emit as-is.
                parts.push(s.substr(k + 1, j - (k + 1)));
                parts.push("<%");
                i = j + 2;
                continue;
            }

            // Only handle <%= ... %> in attribute contexts.
            if (j + 3 > s.length || s.charAt(j + 2) != '=') {
                parts.push(s.substr(k + 1, j - (k + 1)));
                parts.push("<%");
                i = j + 2;
                continue;
            }

            var end = s.indexOf("%>", j + 3);
            if (end == -1) { parts.push(s.substr(i)); break; }
            var expr = normalizeAttrExpr(s.substr(j + 3, end - (j + 3)));

            // Special handling: <%= if cond do %>then<% else %>else<% end %>
            // This is a common shape from Haxe ternary in string interpolation.
            if (StringTools.startsWith(expr, "if ") && StringTools.endsWith(expr, " do")) {
                var condStr = StringTools.trim(expr.substr(3, expr.length - 3 - 3)); // between "if " and " do"
                var thenStartPos = end + 2;
                var elseMarkerPos = s.indexOf("<% else %>", thenStartPos);
                var endMarkerPos = s.indexOf("<% end %>", thenStartPos);
                if (endMarkerPos == -1) { parts.push(s.substr(i)); break; }
                var thenEndPos = (elseMarkerPos != -1 && elseMarkerPos < endMarkerPos) ? elseMarkerPos : endMarkerPos;
                var thenContentRaw = StringTools.trim(s.substr(thenStartPos, thenEndPos - thenStartPos));
                var elseContentRaw: Null<String> = (elseMarkerPos != -1 && elseMarkerPos < endMarkerPos)
                    ? StringTools.trim(s.substr(elseMarkerPos + 10, endMarkerPos - (elseMarkerPos + 10)))
                    : null;

                var thenExpr = branchToExpr(thenContentRaw);
                var elseExpr: Null<String> = elseContentRaw != null ? branchToExpr(elseContentRaw) : null;

                parts.push("{");
                parts.push("if " + condStr + ", do: " + thenExpr + (elseExpr != null ? ", else: " + elseExpr : ""));
                parts.push("}");

                var postEndPos = endMarkerPos + 9;
                if (postEndPos < s.length && (s.charAt(postEndPos) == '"' || s.charAt(postEndPos) == '\'')) {
                    if (quote == null || s.charAt(postEndPos) == quote) postEndPos++;
                }
                i = postEndPos;
                continue;
            }

	            // Simple attribute expression: name=<%= expr %>  → name={expr}
	            parts.push("{");
	            parts.push(expr);
	            parts.push("}");

		            var nextPos = end + 2;
	            // Skip closing quote if the attribute value was quoted, even if the opening quote was already removed.
	            // Also tolerate a small amount of whitespace between `%>` and the closing quote.
	            var qpos = nextPos;
	            while (qpos < s.length && ~/^\s$/.match(s.charAt(qpos))) qpos++;
	            if (qpos < s.length && (s.charAt(qpos) == '"' || s.charAt(qpos) == '\'')) {
	                if (quote == null || s.charAt(qpos) == quote) qpos++;
	            }
	            nextPos = qpos;
	            i = nextPos;
	        }

	        return parts.join("");
	    }

	    /**
	     * rewriteAttributeBraceTrailingQuotes
	     *
	     * WHY
	     * - Haxe string interpolation inside HXX templates is lowered into nested string concatenations.
	     * - We may rewrite an attribute value to `{expr}` in an inner concat node, but the closing quote
	     *   from `attr="${expr}"` can live in the *next* concat chunk.
	     * - When the outer concat is reprocessed there is no remaining `<%` marker to trigger the
	     *   attribute rewrite, leaving output like: `attr={expr}"`.
	     *
	     * WHAT
	     * - Removes a trailing quote immediately after a brace-style attribute expression when it looks
	     *   like an attribute terminator (whitespace, `>`, or `/`) follows.
	     *
	     * HOW
	     * - For each `}` followed by a quote, confirm we are inside a tag attribute value by finding the
	     *   nearest `=` to the left without crossing a `>`, and ensuring the attribute value starts with `{`.
	     */
	    static function rewriteAttributeBraceTrailingQuotes(s:String):String {
	        if (s == null) return s;
	        if (s.indexOf("}\"") == -1 && s.indexOf("}'") == -1) return s;

	        inline function isWhitespace(ch:String):Bool {
	            return ~/^\s$/.match(ch);
	        }
	        inline function isAttrTerminator(ch:String):Bool {
	            return ch == ">" || ch == "/" || isWhitespace(ch);
	        }

	        var parts:Array<String> = [];
	        var i = 0;
	        while (i < s.length) {
	            var j = s.indexOf("}", i);
	            if (j == -1) { parts.push(s.substr(i)); break; }

	            // Not followed by a quote → passthrough
	            if (j + 1 >= s.length || (s.charAt(j + 1) != '"' && s.charAt(j + 1) != '\'')) {
	                parts.push(s.substr(i, (j - i) + 1));
	                i = j + 1;
	                continue;
	            }

	            // Check attribute context: find nearest '=' without crossing '>'
	            var k = j - 1;
	            var seenGt = false;
	            while (k >= i) {
	                var ch = s.charAt(k);
	                if (ch == ">") { seenGt = true; break; }
	                if (ch == "=") break;
	                k--;
	            }
	            if (k < i || seenGt || s.charAt(k) != "=") {
	                parts.push(s.substr(i, (j - i) + 1));
	                i = j + 1;
	                continue;
	            }

	            // Confirm the attribute value starts with '{' after '='
	            var vpos = k + 1;
	            while (vpos < s.length && isWhitespace(s.charAt(vpos))) vpos++;
	            if (vpos >= s.length || s.charAt(vpos) != "{") {
	                parts.push(s.substr(i, (j - i) + 1));
	                i = j + 1;
	                continue;
	            }

	            // Only drop quote if it is actually terminating the attribute
	            var afterQuotePos = j + 2;
	            if (afterQuotePos >= s.length || isAttrTerminator(s.charAt(afterQuotePos))) {
	                parts.push(s.substr(i, (j - i) + 1)); // include '}'
	                i = j + 2; // skip quote
	                continue;
	            }

	            // Otherwise keep as-is
	            parts.push(s.substr(i, (j - i) + 1));
	            i = j + 1;
	        }

	        return parts.join("");
	    }

	    public static inline function toQuoted(s:String): String {
	        var t = StringTools.trim(s);
        // If already quoted, keep as-is; otherwise wrap with quotes without escaping inner quotes
        if ((StringTools.startsWith(t, '"') && StringTools.endsWith(t, '"')) || (StringTools.startsWith(t, "'") && StringTools.endsWith(t, "'"))) {
            return t;
        }
        return '"' + t + '"';
    }

    /**
     * Rewrite attribute values written as ${...} into HEEx attribute expressions { ... }.
     * - Handles: attr=${expr} or attr="${expr}" → attr={expr}
     * - Maps assigns.* → @*
     * - For top-level ternary cond ? a : b → {if cond, do: a, else: b}
     */
    static function rewriteAttributeInterpolations(s:String):String {
        if (s == null) return s;
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var j = s.indexOf("${", i);
            if (j == -1) { parts.push(s.substr(i)); break; }
            var k = j - 1;
            var seenGt = false;
            while (k >= i) {
                var ch = s.charAt(k);
                if (ch == '>') { seenGt = true; break; }
                if (ch == '=') break;
                k--;
            }
            if (k < i || seenGt || s.charAt(k) != '='.charAt(0)) {
                parts.push(s.substr(i, (j - i)));
                parts.push("${");
                i = j + 2;
                continue;
            }
            var nameEnd = k - 1;
            while (nameEnd >= i && ~/^\s$/.match(s.charAt(nameEnd))) nameEnd--;
            var nameStart = nameEnd;
            while (nameStart >= i && ~/^[A-Za-z0-9_:\-]$/.match(s.charAt(nameStart))) nameStart--;
            nameStart++;
            if (nameStart > nameEnd) {
                parts.push(s.substr(i, (j - i)));
                parts.push("${");
                i = j + 2;
                continue;
            }
            var attrName = s.substr(nameStart, (nameEnd - nameStart + 1));
            parts.push(s.substr(i, (nameStart - i)));
            parts.push(attrName);
            parts.push("=");
            var vpos = k + 1;
            while (vpos < s.length && ~/^\s$/.match(s.charAt(vpos))) vpos++;
            var quote: Null<String> = null;
            if (vpos < s.length && (s.charAt(vpos) == "\"" || s.charAt(vpos) == "'")) {
                quote = s.charAt(vpos);
                vpos++;
            }
            if (vpos != j) {
                parts.push(s.substr(k + 1, (j - (k + 1))));
                parts.push("${");
                i = j + 2;
                continue;
            }
            var p = j + 2;
            var depth = 1;
            while (p < s.length && depth > 0) {
                var c = s.charAt(p);
                if (c == '{') depth++; else if (c == '}') depth--; p++;
            }
            var inner = s.substr(j + 2, (p - 1) - (j + 2));
            var expr = StringTools.trim(inner);
            expr = StringTools.replace(expr, "assigns.", "@");
            var tern = splitTopLevelTernary(expr);
            if (tern != null) {
                var cond = StringTools.replace(StringTools.trim(tern.cond), "assigns.", "@");
                var th = StringTools.trim(tern.thenPart);
                var el = StringTools.trim(tern.elsePart);
                expr = 'if ' + cond + ', do: ' + th + ', else: ' + el;
            }
            parts.push("{");
            parts.push(expr);
            parts.push("}");
            if (quote != null) {
                var qpos = p;
                if (qpos < s.length && s.charAt(qpos) == quote) {
                    p = qpos + 1;
                }
            }
            i = p;
        }
        return parts.join("");
    }

    static function extractBlockHtml(part:String):Null<String> {
        if (part == null || part == "") return "";
        var p = part;
        if (StringTools.startsWith(p, "HXX.block(")) {
            var start = p.indexOf('(') + 1;
            var end = p.lastIndexOf(')');
            if (start > 0 && end > start) {
                var inner = StringTools.trim(p.substr(start, end - start));
                return unquote(inner);
            }
        }
        var uq = unquote(p);
        if (uq != null) return uq;
        return null;
    }

    // Extracts simple HTML from an AST branch when it's either HXX.block('...') or a string literal
    static function extractSimpleHtml(branch: ElixirAST): Null<String> {
        return switch (branch.def) {
            case ECall(module, func, args):
                var isHxx = false;
                if (module != null) switch (module.def) {
                    case EVar(m): isHxx = (m == "HXX");
                    case EField(_, fld): isHxx = (fld == "HXX");
                    default:
                }
                if (isHxx && (func == "block" || func == "hxx") && args.length >= 1) {
                    var inner = collectTemplateContent(args[0]);
                    // Ensure no nested EEx in inner
                    if (inner.indexOf("<%") == -1) inner else null;
                } else null;
            case EString(s):
                var uq = unquote(s);
                uq != null ? uq : s;
            default:
                null;
        }
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

    static function splitTopLevelTernary(e:String):Null<{cond:String, thenPart:String, elsePart:String}> {
        var depth = 0;
        var inS = false, inD = false;
        var q = -1, col = -1;
        for (idx in 0...e.length) {
            var ch = e.charAt(idx);
            if (!inS && ch == '"' && !inD) { inD = true; continue; }
            else if (inD && ch == '"') { inD = false; continue; }
            if (!inD && ch == '\'' && !inS) { inS = true; continue; }
            else if (inS && ch == '\'') { inS = false; continue; }
            if (inS || inD) continue;
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

    static function rewriteInlineIfDoToBlock(s:String):String {
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var start = s.indexOf("<%=", i);
            if (start == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, start - i));
            var endTag = s.indexOf("%>", start + 3);
            if (endTag == -1) { parts.push(s.substr(start)); break; }
            var inner = StringTools.trim(s.substr(start + 3, endTag - (start + 3)));
            if (StringTools.startsWith(inner, "if ")) {
                var rest = StringTools.trim(inner.substr(3));
                var idxDo = indexOfTopLevel(rest, ", do:");
                var cond:String = null;
                var doPart:String = null;
                var elsePart:String = null;
                if (idxDo != -1) {
                    cond = StringTools.trim(rest.substr(0, idxDo));
                    var afterDo = StringTools.trim(rest.substr(idxDo + 5));
                    var qv = extractQuoted(afterDo);
                    if (qv != null) {
                        doPart = qv.value;
                        var rem = StringTools.trim(afterDo.substr(qv.length));
                        if (StringTools.startsWith(rem, ",")) rem = StringTools.trim(rem.substr(1));
                        if (StringTools.startsWith(rem, "else:")) {
                            var afterElse = StringTools.trim(rem.substr(5));
                            var qv2 = extractQuoted(afterElse);
                            if (qv2 != null) elsePart = qv2.value;
                        }
                    }
                }
                if (cond != null && doPart != null) {
                    parts.push('<%= if ' + StringTools.replace(cond, "assigns.", "@") + ' do %>');
                    parts.push(doPart);
                    if (elsePart != null && elsePart != "") { parts.push('<% else %>'); parts.push(elsePart); }
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

    static function extractQuoted(s:String):Null<{value:String, length:Int}> {
        if (s.length == 0) return null;
        var quote = s.charAt(0);
        if (quote != '"' && quote != '\'') return null;
        var i = 1;
        while (i < s.length) {
            var ch = s.charAt(i);
            if (ch == quote) {
                var val = s.substr(1, i - 1);
                return { value: val, length: i + 1 };
            }
            i++;
        }
        return null;
    }

    /**
     * Structured rewrite of <if {cond}> ... (<else> ...)? </if> into block HEEx.
     * Handles nesting and maps assigns.* to @*.
     */
    public static function rewriteControlTags(s:String):String {
        if (s == null || s.indexOf("<if") == -1) return s;
        // If the condition inside `{ ... }` is produced by Haxe string interpolation
        // it may arrive wrapped as a single EEx interpolation, e.g.:
        //   <if {<%= assigns.show_form %>}> ... </if>
        // Unwrap it so the generated HEEx is valid:
        //   <%= if @show_form do %> ... <% end %>
        function unwrapSingleEexInterpolation(expr:String):String {
            if (expr == null) return expr;
            var trimmed = StringTools.trim(expr);
            var single = ~/^<%=\s*(.*?)\s*%>$/s;
            if (single.match(trimmed)) {
                return StringTools.trim(single.matched(1));
            }
            return expr;
        }
        function normalizeControlExpr(expr:String):String {
            if (expr == null) return expr;
            var out = expr;
            out = StringTools.replace(out, "assigns.", "@");
            // Allow common Haxe-ish syntax inside control tags.
            // - `null` (Haxe) → `nil` (Elixir)
            // - `x.length` (Haxe Array/List) → `length(x)` (Elixir)
            out = ~/\bnull\b/g.replace(out, "nil");
            var lenProp = ~/(@?[A-Za-z0-9_\.]+)\.length\b/g;
            out = lenProp.map(out, function (re) {
                return 'length(' + re.matched(1) + ')';
            });
            return out;
        }
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var idx = s.indexOf("<if", i);
            if (idx == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, idx - i));
            var j = idx + 3; // after '<if'
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '{') { parts.push("<if"); i = idx + 3; continue; }
            var braceStart = j; j++;
            var braceDepth = 1;
            while (j < s.length && braceDepth > 0) {
                var ch = s.charAt(j);
                if (ch == '{') braceDepth++; else if (ch == '}') braceDepth--; j++;
            }
            if (braceDepth != 0) { parts.push(s.substr(idx)); break; }
            var braceEnd = j - 1;
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '>') { parts.push(s.substr(idx, j - idx)); i = j; continue; }
            var openEnd = j + 1;
            var cond = StringTools.trim(s.substr(braceStart + 1, braceEnd - (braceStart + 1)));
            cond = unwrapSingleEexInterpolation(cond);
            cond = normalizeControlExpr(cond);
            var k = openEnd;
            var depth = 1;
            var elsePos = -1;
            while (k < s.length && depth > 0) {
                var nextIf = s.indexOf("<if", k);
                var nextElse = s.indexOf("<else>", k);
                var nextClose = s.indexOf("</if>", k);
                var next = -1;
                var tag = 0;
                if (nextIf != -1) { next = nextIf; tag = 1; }
                if (nextElse != -1 && (next == -1 || nextElse < next)) { next = nextElse; tag = 2; }
                if (nextClose != -1 && (next == -1 || nextClose < next)) { next = nextClose; tag = 3; }
                if (next == -1) break;
                if (tag == 1) { depth++; k = next + 3; }
                else if (tag == 2 && depth == 1 && elsePos == -1) { elsePos = next; k = next + 6; }
                else if (tag == 3) { depth--; k = next + 5; }
                else k = next + 1;
            }
            if (depth != 0) { parts.push(s.substr(idx)); break; }
            var closeIdx = k - 5;
            var thenStart = openEnd;
            var thenEnd = elsePos != -1 ? elsePos : closeIdx;
            var elseStart = elsePos != -1 ? (elsePos + 6) : -1;
            var elseEnd = closeIdx;
            var thenHtml = s.substr(thenStart, thenEnd - thenStart);
            var elseHtml = elseStart != -1 ? s.substr(elseStart, elseEnd - elseStart) : null;
            // Rewrite nested <if>/<else> blocks inside the branches.
            thenHtml = rewriteControlTags(thenHtml);
            if (elseHtml != null) elseHtml = rewriteControlTags(elseHtml);
            parts.push('<%= if ' + cond + ' do %>');
            parts.push(thenHtml);
            if (elseHtml != null && StringTools.trim(elseHtml) != "") { parts.push('<% else %>'); parts.push(elseHtml); }
            parts.push('<% end %>');
            var afterClose = s.indexOf('>', closeIdx + 1);
            i = (afterClose == -1) ? s.length : afterClose + 1;
        }
        return parts.join("\n");
    }

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
    
    /**
     * Collect template argument for function calls within templates
     */
    public static function collectTemplateArgument(ast: ElixirAST): String {
        return switch(ast.def) {
            case EString(s): '"' + s + '"';
            case EVar(name): name;
            case EAtom(a): ":" + a;
            case EInteger(i): Std.string(i);
            case EFloat(f): Std.string(f);
            case EBoolean(b): b ? "true" : "false";
            case ENil: "nil";
            case EField(obj, field):
                switch(obj.def) {
                    case EVar(v): v + "." + field;
                    default: "[complex]." + field;
                }
            default: "[complex arg]";
        };
    }
    
    /**
     * Check if an expression is an HXX module access
     * 
     * Detects patterns like HXX.hxx() or hxx.HXX.hxx()
     */
    public static function isHXXModule(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TTypeExpr(m):
                // Check if this is the HXX module
                var moduleName = moduleTypeToString(m);
                #if debug_hxx_transformation
                #if debug_ast_builder
                // DISABLED: trace('[HXX] Checking module: $moduleName against "HXX"');
                #end
                #end
                moduleName == "HXX";
            default: 
                #if debug_hxx_transformation
                #if debug_ast_builder
                // DISABLED: trace('[HXX] Not a TTypeExpr, expr type: ${expr.expr}');
                #end
                #end
                false;
        };
    }
    
    /**
     * Convert a ModuleType to string representation
     * Helper function for isHXXModule
     */
    static function moduleTypeToString(m: ModuleType): String {
        return switch (m) {
            case TClassDecl(c):
                var cls = c.get();
                if (cls.pack.length > 0) {
                    cls.pack.join(".") + "." + cls.name;
                } else {
                    cls.name;
                }
            case TEnumDecl(e):
                var enm = e.get();
                if (enm.pack.length > 0) {
                    enm.pack.join(".") + "." + enm.name;
                } else {
                    enm.name;
                }
            case TAbstract(a):
                var abs = a.get();
                if (abs.pack.length > 0) {
                    abs.pack.join(".") + "." + abs.name;
                } else {
                    abs.name;
                }
            case TTypeDecl(t):
                var typ = t.get();
                if (typ.pack.length > 0) {
                    typ.pack.join(".") + "." + typ.name;
                } else {
                    typ.name;
                }
        };
    }
}

#end
