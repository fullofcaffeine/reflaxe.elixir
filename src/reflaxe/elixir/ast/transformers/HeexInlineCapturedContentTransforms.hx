package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexInlineCapturedContentTransforms
 *
 * WHAT
 * - Converts the pattern where render/1 builds a string in any local variable,
 *   optionally assigns it into assigns, and then renders
 *   `~H"""<%= Phoenix.HTML.raw(var | @var) %>"""` into a proper `~H` with the
 *   literal HTML body.
 *
 * WHY
 * - `Phoenix.HTML.raw(@content)` only marks a string as safe HTML; it does not
 *   evaluate inner HEEx/EEx directives. The correct approach is to inline the
 *   literal into the ~H sigil so LiveView compiles it as a template.
 *
 * HOW
 * - In EDef("render", _, _, EBlock/EDo(stmts))
 *   1) Find the ~H that includes Phoenix.HTML.raw(var) or Phoenix.HTML.raw(@var) and capture `var`.
 *   2) Find the last assignment `var = "..."` (allow EParen wrapping) and extract the literal.
 *   3) Optionally detect `assigns = Phoenix.Component.assign(assigns, %{... var ...})` and drop it.
 *   4) Replace the ~H content with the literal html and drop (2) and (3).
 *
 * EXAMPLES
 * Before:
 *   html = "<div><%= @count %></div>"
 *   assigns = Phoenix.Component.assign(assigns, %{content: html})
 *   ~H"""
 *   <%= Phoenix.HTML.raw(@html) %>
 *   """
 * After:
 *   ~H"""
 *   <div><%= @count %></div>
 *   """
 */
class HeexInlineCapturedContentTransforms {
    static function extractStringLiteral(e: ElixirAST): Null<String> {
        var cur = e;
        var guard = 0;
        while (cur != null && guard++ < 4) {
            switch (cur.def) {
                case EString(s): return s;
                case EParen(inner): cur = inner;
                case ERaw(code):
                    // Attempt to extract a plain string literal from raw code like: ("...") or "..."
                    var s = code;
                    if (s == null) return null;
                    s = StringTools.trim(s);
                    // unwrap one level of parentheses
                    if (s.length >= 2 && s.charAt(0) == '(' && s.charAt(s.length - 1) == ')') {
                        s = StringTools.trim(s.substr(1, s.length - 2));
                    }
                    if (s.length < 2 || s.charAt(0) != '"' || s.charAt(s.length - 1) != '"') return null;
                    // decode common escapes inside the string literal
                    var out = new StringBuf();
                    var i = 1;
                    var end = s.length - 1;
                    while (i < end) {
                        var ch = s.charAt(i);
                        if (ch == '\\' && i + 1 < end) {
                            var nxt = s.charAt(i + 1);
                            switch (nxt) {
                                case 'n': out.add("\n"); i += 2; continue;
                                case 'r': out.add("\r"); i += 2; continue;
                                case 't': out.add("\t"); i += 2; continue;
                                case '"': out.add('"'); i += 2; continue;
                                case '\\': out.add('\\'); i += 2; continue;
                                default:
                                    // keep unknown escape as-is (drop backslash)
                                    out.add(nxt);
                                    i += 2; continue;
                            }
                        } else {
                            out.add(ch);
                            i++;
                        }
                    }
                    return out.toString();
                default: return null;
            }
        }
        return null;
    }

    // Helper: extract var name from Phoenix.HTML.raw(var|@var)
    static function extractRawVarName(s: String): Null<String> {
        if (s == null) return null;
        var needle = "Phoenix.HTML.raw(";
        var idx = s.indexOf(needle);
        if (idx == -1) return null;
        var i = idx + needle.length;
        while (i < s.length && ~/^\s$/.match(s.charAt(i))) i++;
        if (i < s.length && s.charAt(i) == '@') i++;
        var start = i;
        while (i < s.length && ~/^[A-Za-z0-9_]$/.match(s.charAt(i))) i++;
        if (i == start) return null;
        var v = s.substr(start, i - start);
        while (i < s.length && ~/^\s$/.match(s.charAt(i))) i++;
        if (i >= s.length || s.charAt(i) != ')') return null;
        return v;
    }

    // Helper: locate ~H using Phoenix.HTML.raw(var|@var)
    static function findHeexSigilIndexAndVar(stmts: Array<ElixirAST>): { idx:Int, parens:Int, varName:Null<String> } {
        for (i in 0...stmts.length) {
            var node = stmts[i];
            var par = 0;
            while (true) {
                switch (node.def) {
                    case EParen(inner): node = inner; par++; continue;
                    default:
                }
                break;
            }
            switch (node.def) {
                case ESigil(type, content, _mods) if (type == "H"):
                    var vn = extractRawVarName(content);
                    if (vn != null) return { idx: i, parens: par, varName: vn };
                case ERaw(code) if (code.indexOf("~H\"") != -1 || code.indexOf("~H\"\"\"") != -1):
                    var vn2 = extractRawVarName(code);
                    if (vn2 != null) return { idx: i, parens: par, varName: vn2 };
                default:
            }
        }
        return { idx: -1, parens: 0, varName: null };
    }

    // Helper: find last string assignment to varName
    static function findLastStringAssign(stmts:Array<ElixirAST>, varName:String): { idx:Int, html:Null<String> } {
        var foundIdx = -1; var html: Null<String> = null;
        for (i in 0...stmts.length) {
            switch (stmts[i].def) {
                case EMatch(PVar(vn), rhs) if (vn == varName):
                    #if debug_heex_inline
                    trace('[HeexInlineCapturedContent] match PVar(' + vn + ') at ' + i + ', rhs=' + Type.enumConstructor(rhs.def));
                    #end
                    var lit = extractStringLiteral(rhs);
                    if (lit != null) { foundIdx = i; html = lit; }
                case EBinary(Match, {def:EVar(vn2)}, rhs2) if (vn2 == varName):
                    #if debug_heex_inline
                    trace('[HeexInlineCapturedContent] binary match EVar(' + vn2 + ') at ' + i);
                    #end
                    var lit2 = extractStringLiteral(rhs2);
                    if (lit2 != null) { foundIdx = i; html = lit2; }
                case EBinary(Match, left, rhs3):
                    #if debug_heex_inline
                    trace('[HeexInlineCapturedContent] binary match (other left=' + Type.enumConstructor(left.def) + ') at ' + i);
                    #end
                default:
                    #if debug_heex_inline
                    // trace other nodes sparingly
                    #end
            }
        }
        return { idx: foundIdx, html: html };
    }

    // Helper: detect assigns capture of varName
    static function isAssignsCaptureOfVar(node: ElixirAST, varName:String): Bool {
        return switch (node.def) {
            case EMatch(PVar(lhs), { def: ERemoteCall({def: EVar(mod)}, "assign", [first, second]) }) if (lhs == "assigns" && mod == "Phoenix.Component"):
                switch (second.def) {
                    case EMap(pairs):
                        for (p in pairs) switch (p.value.def) {
                            case EVar(v) if (v == varName): return true;
                            case EParen(innerv):
                                switch (innerv.def) {
                                    case EVar(v2) if (v2 == varName): return true;
                                    default:
                                }
                            default:
                        }
                        false;
                    default:
                        false;
                }
            case EBinary(Match, {def:EVar(lhs2)}, { def: ERemoteCall({def: EVar(mod2)}, "assign", [first2, second2]) }) if (lhs2 == "assigns" && mod2 == "Phoenix.Component"):
                switch (second2.def) {
                    case EMap(pairs2):
                        for (p2 in pairs2) switch (p2.value.def) {
                            case EVar(v3) if (v3 == varName): return true;
                            case EParen(inner3):
                                switch (inner3.def) {
                                    case EVar(v4) if (v4 == varName): return true;
                                    default:
                                }
                            default:
                        }
                        false;
                    default:
                        false;
                }
            default:
                false;
        }
    }

    // Helper: convert #{...}/${...} to <%= ... %> and assigns.* to @*
    static function convertInterpolations(s:String):String {
        var out = new StringBuf();
        var i2 = 0;
        while (i2 < s.length) {
            var j1 = s.indexOf("#{", i2);
            var j2 = s.indexOf("${", i2);
            var j = (j1 == -1) ? j2 : (j2 == -1 ? j1 : (j1 < j2 ? j1 : j2));
            if (j == -1) { out.add(s.substr(i2)); break; }
            out.add(s.substr(i2, j - i2));
            var k = j + 2;
            var depth = 1;
            while (k < s.length && depth > 0) {
                var ch = s.charAt(k);
                if (ch == '{') depth++;
                else if (ch == '}') depth--;
                k++;
            }
            var expr = s.substr(j + 2, (k - 1) - (j + 2));
            expr = StringTools.trim(expr);
            expr = StringTools.replace(expr, "assigns.", "@");
            out.add('<%= ' + expr + ' %>');
            i2 = k;
        }
        return out.toString();
    }

    // Core: inline in statements array
    static function inlineCaptured(stmts:Array<ElixirAST>): { changed:Bool, out:Array<ElixirAST> } {
        var sig = findHeexSigilIndexAndVar(stmts);
        #if debug_heex_inline
        trace('[HeexInlineCapturedContent] scan: sig.idx=' + sig.idx + ', var=' + sig.varName + ', parens=' + sig.parens);
        #end
        if (sig.idx == -1 || sig.varName == null) return { changed:false, out: stmts };
        var assign = findLastStringAssign(stmts, sig.varName);
        #if debug_heex_inline
        trace('[HeexInlineCapturedContent] assign: idx=' + assign.idx + ', hasHtml=' + (assign.html != null));
        #end
        if (assign.html == null) return { changed:false, out: stmts };
        var html = convertInterpolations(assign.html);
        var assignsIdx = -1;
        for (i in 0...stmts.length) if (isAssignsCaptureOfVar(stmts[i], sig.varName)) { assignsIdx = i; break; }
        #if debug_heex_inline
        trace('[HeexInlineCapturedContent] assigns capture idx=' + assignsIdx);
        #end
        var out: Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
            if (i == assign.idx) continue;
            if (i == assignsIdx) continue;
            if (i == sig.idx) {
                var rebuilt: ElixirAST = makeAST(ESigil("H", html, ""));
                var p = 0;
                while (p < sig.parens) { rebuilt = makeAST(EParen(rebuilt)); p++; }
                out.push(makeASTWithMeta(rebuilt.def, stmts[i].metadata, stmts[i].pos));
            } else {
                out.push(stmts[i]);
            }
        }
        return { changed:true, out: out };
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "render"):
                    #if sys
                    Sys.println('[HeexInlineCapturedContent] Scanning render/1');
                    #else
                    trace('[HeexInlineCapturedContent] Scanning render/1');
                    #end
                    switch (body.def) {
                        case EBlock(stmts):
                            var r1 = inlineCaptured(stmts);
                            #if debug_heex_inline
                            if (r1.changed) trace('[HeexInlineCapturedContent] Inlined EBlock in render/1'); else trace('[HeexInlineCapturedContent] No-op EBlock');
                            #end
                            if (r1.changed) makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(r1.out))), n.metadata, n.pos) else n;
                        case EDo(stmts):
                            var r2 = inlineCaptured(stmts);
                            #if debug_heex_inline
                            if (r2.changed) trace('[HeexInlineCapturedContent] Inlined EDo in render/1'); else trace('[HeexInlineCapturedContent] No-op EDo');
                            #end
                            if (r2.changed) makeASTWithMeta(EDef(name, args, guards, makeAST(EDo(r2.out))), n.metadata, n.pos) else n;
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
