package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

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
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        #end
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
                // Ensure HXX control tags remain balanced across boundaries
                rewriteControlTags(l + r);
                
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
                    var out = new StringBuf();
                    out.add('<%= if ' + condStr + ' do %>');
                    out.add(thenStr);
                    if (elseStr != null && elseStr != "") {
                        out.add('<% else %>');
                        out.add(elseStr);
                    }
                    out.add('<% end %>');
                    out.toString();
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
        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        #if sys
        Sys.println('[HXX] collectTemplateContent elapsed_ms=' + Std.int(__elapsed));
        #else
        trace('[HXX] collectTemplateContent elapsed_ms=' + Std.int(__elapsed));
        #end
        #end
        return __result;
    }

    /**
     * Convert #{...} and ${...} interpolations into HEEx <%= ... %> and map assigns.* → @*
     * Also rewrites inline ternary to block HEEx when then/else are string or HXX.block.
     */
    public static function rewriteInterpolations(s:String):String {
        if (s == null) return s;
        // Fast-path: if there are no interpolation/control markers, return as-is
        if (s.indexOf("${") == -1 && s.indexOf("#{") == -1 && s.indexOf('<for {') == -1) {
            return s;
        }
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        var __bytes = s.length;
        var __iters = 0;
        #end
        // First, convert attribute-level ${...} into HEEx attribute expressions: attr={...}
        s = rewriteAttributeInterpolations(s);
        // Then, convert attribute-level <%= ... %> into HEEx attribute expressions: attr={...}
        s = rewriteAttributeEexInterpolations(s);
        // Normalize custom control tags first (so inner text gets rewritten next)
        s = rewriteForBlocks(s);
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            #if hxx_instrument_sys __iters++; #end
            var j1 = s.indexOf("#{", i);
            var j2 = s.indexOf("${", i);
            var j = (j1 == -1) ? j2 : (j2 == -1 ? j1 : (j1 < j2 ? j1 : j2));
            if (j == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, j - i));
            var k = j + 2;
            var depth = 1;
            while (k < s.length && depth > 0) {
                var ch = s.charAt(k);
                if (ch == '{') depth++;
                else if (ch == '}') depth--;
                k++;
            }
            var inner = s.substr(j + 2, (k - 1) - (j + 2));
            var expr = StringTools.trim(inner);
            // Guard: disallow injecting HTML as string via interpolation of a string literal starting with '<'
            if (expr.length >= 2 && expr.charAt(0) == '"' && expr.charAt(1) == '<') {
                #if macro
                haxe.macro.Context.error('HXX: injecting HTML via string inside interpolation is not allowed. Use HXX.block(\'...\') or inline markup.', haxe.macro.Context.currentPos());
                #else
                throw 'HXX: injecting HTML via string inside interpolation is not allowed. Use HXX.block(\'...\') or inline markup.';
                #end
            }
            // Try to split top-level ternary
            var tern = splitTopLevelTernary(expr);
            if (tern != null) {
                var cond = StringTools.replace(tern.cond, "assigns.", "@");
                var th = extractBlockHtml(StringTools.trim(tern.thenPart));
                var el = extractBlockHtml(StringTools.trim(tern.elsePart));
                if (th != null || el != null) {
                    // Prefer inline-if in body when both branches are HTML strings
                    var thenQ = (th != null) ? toQuoted(th) : '""';
                    var elseQ = (el != null && el != "") ? toQuoted(el) : '""';
                    out.add('<%= if ' + cond + ', do: ' + thenQ + ', else: ' + elseQ + ' %>');
                } else {
                    out.add('<%= ' + StringTools.replace(expr, "assigns.", "@") + ' %>');
                }
            } else {
                out.add('<%= ' + StringTools.replace(expr, "assigns.", "@") + ' %>');
            }
            i = k;
        }
        // Return as-is; attribute contexts are normalized elsewhere.
        var __res = out.toString();
        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        #if macro
        haxe.macro.Context.warning('[HXX] rewriteInterpolations bytes=' + __bytes + ' iters=' + __iters + ' elapsed_ms=' + Std.int(__elapsed), haxe.macro.Context.currentPos());
        #elseif sys
        Sys.println('[HXX] rewriteInterpolations bytes=' + __bytes + ' iters=' + __iters + ' elapsed_ms=' + Std.int(__elapsed));
        #end
        #end
        return __res;
    }

    /**
     * Rewrite <for {pattern in expr}> ... </for> to HEEx for-blocks.
     * Supports simple patterns like `todo in list` or `item in some_call()`.
     */
    public static function rewriteForBlocks(src:String):String {
        var out = new StringBuf();
        var i = 0;
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        #end
        #if hxx_instrument
        var localIters = 0;
        #end
        while (i < src.length) {
            #if hxx_instrument localIters++; #end
            var start = src.indexOf('<for {', i);
            if (start == -1) { out.add(src.substr(i)); break; }
            out.add(src.substr(i, start - i));
            var headEnd = src.indexOf('}>', start);
            if (headEnd == -1) { out.add(src.substr(start)); break; }
            var headInner = src.substr(start + 6, headEnd - (start + 6)); // between { and }
            var closeTag = src.indexOf('</for>', headEnd + 2);
            if (closeTag == -1) { out.add(src.substr(start)); break; }
            var body = src.substr(headEnd + 2, closeTag - (headEnd + 2));
            var parts = headInner.split(' in ');
            if (parts.length != 2) {
                // Fallback: keep original; do not break template
                out.add(src.substr(start, (closeTag + 6) - start));
                i = closeTag + 6;
                continue;
            }
            var pat = StringTools.trim(parts[0]);
            var iter = StringTools.trim(parts[1]);
            // Map assigns.* to @* in iterator expression
            iter = StringTools.replace(iter, 'assigns.', '@');
            out.add('<%= for ' + pat + ' <- ' + iter + ' do %>');
            // Recursively allow nested for/if inside body
            out.add(rewriteForBlocks(body));
            out.add('<% end %>');
            i = closeTag + 6;
        }
        #if hxx_instrument
        trace('[HXX-INSTR] forBlocks: iters=' + localIters + ' len=' + (src != null ? src.length : 0));
        #end
        var __s = out.toString();
        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        #if macro
        haxe.macro.Context.warning('[HXX] rewriteForBlocks bytes=' + (src != null ? src.length : 0) + ' iters=' + ( #if hxx_instrument localIters #else 0 #end ) + ' elapsed_ms=' + Std.int(__elapsed), haxe.macro.Context.currentPos());
        #elseif sys
        Sys.println('[HXX] rewriteForBlocks bytes=' + (src != null ? src.length : 0) + ' iters=' + ( #if hxx_instrument localIters #else 0 #end ) + ' elapsed_ms=' + Std.int(__elapsed));
        #end
        #end
        return __s;
    }

    // Convert attribute values written as <%= ... %> (and conditional blocks) into HEEx { ... }
    static function rewriteAttributeEexInterpolations(s:String):String {
        // Fast-path: regex-based attribute EEx → HEEx conversion (single pass), avoiding heavy scanning
        if (s == null || s.indexOf("<%") == -1) return s;
        // name=<%= expr %>  → name={expr}
        var eexAttr = ~/=\s*<%=\s*([^%]+?)\s*%>/g;
        var result = eexAttr.replace(s, '={$1}');
        // name=<% if cond do %>then<% else %>else<% end %> → name={if cond, do: "then", else: "else"}
        var eexIf = ~/=\s*<%\s*if\s+(.+?)\s+do\s*%>([^<]*)<%\s*else\s*%>([^<]*)<%\s*end\s*%>/g;
        result = eexIf.map(result, function (re) {
            var cond = StringTools.trim(re.matched(1));
            var th = StringTools.trim(re.matched(2));
            var el = StringTools.trim(re.matched(3));
            if (!(StringTools.startsWith(th, '"') && StringTools.endsWith(th, '"')) && !(StringTools.startsWith(th, "'") && StringTools.endsWith(th, "'"))) th = '"' + th + '"';
            if (!(StringTools.startsWith(el, '"') && StringTools.endsWith(el, '"')) && !(StringTools.startsWith(el, "'") && StringTools.endsWith(el, "'"))) el = '"' + el + '"';
            return '={if ' + cond + ', do: ' + th + ', else: ' + el + '}';
        });
        return result;
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
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var prev = i;
            var j = s.indexOf("${", i);
            if (j == -1) { out.add(s.substr(i)); break; }
            // Attempt to detect an attribute assignment immediately preceding ${
            // Find the nearest '=' before j without encountering '>'
            var k = j - 1;
            var seenGt = false;
            while (k >= i) {
                var ch = s.charAt(k);
                if (ch == '>') { seenGt = true; break; }
                if (ch == '=') break;
                k--;
            }
            if (k < i || seenGt || s.charAt(k) != '=') {
                // Not an attr context; copy chunk up to j and continue generic handling later
                out.add(s.substr(i, (j - i)));
                // Copy marker to let generic pass handle it
                out.add("${");
                i = j + 2;
                continue;
            }
            // Find attribute name by scanning backwards from k-1
            var nameEnd = k - 1;
            while (nameEnd >= i && ~/^\s$/.match(s.charAt(nameEnd))) nameEnd--;
            var nameStart = nameEnd;
            while (nameStart >= i && ~/^[A-Za-z0-9_:\-]$/.match(s.charAt(nameStart))) nameStart--;
            nameStart++;
            if (nameStart > nameEnd) {
                // Fallback: not a valid attribute name, treat as generic
                out.add(s.substr(i, (j - i)));
                out.add("${");
                i = j + 2;
                continue;
            }
            var attrName = s.substr(nameStart, (nameEnd - nameStart + 1));
            // Copy prefix up to attribute name start
            out.add(s.substr(i, (nameStart - i)));
            out.add(attrName);
            out.add("=");
            // Skip whitespace and optional opening quote after '='
            var vpos = k + 1;
            while (vpos < s.length && ~/^\s$/.match(s.charAt(vpos))) vpos++;
            var quote: Null<String> = null;
            if (vpos < s.length && (s.charAt(vpos) == '"' || s.charAt(vpos) == '\'')) {
                quote = s.charAt(vpos);
                vpos++;
            }
            // We expect vpos == j (start of ${); otherwise, treat as generic
            if (vpos != j) {
                // Not a plain attr=${...}; emit original sequence and continue
                out.add(s.substr(k + 1, (j - (k + 1))));
                out.add("${");
                i = j + 2;
                continue;
            }
            // Parse balanced braces for ${...}
            var p = j + 2;
            var depth = 1;
            while (p < s.length && depth > 0) {
                var c = s.charAt(p);
                if (c == '{') depth++; else if (c == '}') depth--; p++;
            }
            var inner = s.substr(j + 2, (p - 1) - (j + 2));
            var expr = StringTools.trim(inner);
            // Map assigns.* → @*
            expr = StringTools.replace(expr, "assigns.", "@");
            // Ternary to inline-if for attribute context
            var tern = splitTopLevelTernary(expr);
            if (tern != null) {
                var cond = StringTools.replace(StringTools.trim(tern.cond), "assigns.", "@");
                var th = StringTools.trim(tern.thenPart);
                var el = StringTools.trim(tern.elsePart);
                expr = 'if ' + cond + ', do: ' + th + ', else: ' + el;
            }
            out.add('{');
            out.add(expr);
            out.add('}');
            // Skip closing quote if present
            if (quote != null) {
                var qpos = p;
                // Advance until we see the matching quote or tag end; be conservative
                if (qpos < s.length && s.charAt(qpos) == quote) {
                    p = qpos + 1;
                }
            }
            // Advance index
            i = p;
            if (i <= prev) i = prev + 1;
        }
        return out.toString();
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
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var start = s.indexOf("<%=", i);
            if (start == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, start - i));
            var endTag = s.indexOf("%>", start + 3);
            if (endTag == -1) { out.add(s.substr(start)); break; }
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
                    out.add('<%= if ' + StringTools.replace(cond, "assigns.", "@") + ' do %>');
                    out.add(doPart);
                    if (elsePart != null && elsePart != "") { out.add('<% else %>'); out.add(elsePart); }
                    out.add('<% end %>');
                } else {
                    out.add(s.substr(start, (endTag + 2) - start));
                }
            } else {
                out.add(s.substr(start, (endTag + 2) - start));
            }
            i = endTag + 2;
        }
        return out.toString();
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
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var idx = s.indexOf("<if", i);
            if (idx == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, idx - i));
            var j = idx + 3; // after '<if'
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '{') { out.add("<if"); i = idx + 3; continue; }
            var braceStart = j; j++;
            var braceDepth = 1;
            while (j < s.length && braceDepth > 0) {
                var ch = s.charAt(j);
                if (ch == '{') braceDepth++; else if (ch == '}') braceDepth--; j++;
            }
            if (braceDepth != 0) { out.add(s.substr(idx)); break; }
            var braceEnd = j - 1;
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '>') { out.add(s.substr(idx, j - idx)); i = j; continue; }
            var openEnd = j + 1;
            var cond = StringTools.trim(s.substr(braceStart + 1, braceEnd - (braceStart + 1)));
            cond = StringTools.replace(cond, "assigns.", "@");
            // find matching </if>
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
            if (depth != 0) { out.add(s.substr(idx)); break; }
            var closeIdx = k - 5;
            var thenStart = openEnd;
            var thenEnd = elsePos != -1 ? elsePos : closeIdx;
            var elseStart = elsePos != -1 ? (elsePos + 6) : -1;
            var elseEnd = closeIdx;
            var thenHtml = s.substr(thenStart, thenEnd - thenStart);
            var elseHtml = elseStart != -1 ? s.substr(elseStart, elseEnd - elseStart) : null;
            out.add('<%= if ' + cond + ' do %>');
            out.add(thenHtml);
            if (elseHtml != null && StringTools.trim(elseHtml) != "") { out.add('<% else %>'); out.add(elseHtml); }
            out.add('<% end %>');
            var afterClose = s.indexOf('>', closeIdx + 1);
            i = (afterClose == -1) ? s.length : afterClose + 1;
        }
        return out.toString();
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
                trace('[HXX] Checking module: $moduleName against "HXX"');
                #end
                #end
                moduleName == "HXX";
            default: 
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Not a TTypeExpr, expr type: ${expr.expr}');
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
