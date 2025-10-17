package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.emptyMetadata;
using StringTools;

/**
 * HeexFragmentBuilder
 *
 * WHAT
 * - Parses ~H string content into a lightweight, typed AST composed of EFragment, EAttribute,
 *   and ElixirAST expression nodes (EAssign, EField, EAccess, EBinary, EString, etc.).
 *
 * WHY
 * - Provide a deterministic, typed representation of HEEx attribute expressions to enable
 *   robust lints and analysis (e.g., assigns field/type checks) without relying on
 *   string rewrites.
 *
 * HOW
 * - Scans the HEEx content and builds a tree of tags using a simple, robust parser:
 *   • Supports nested tags and Phoenix component tags (e.g., <.button ...>)
 *   • Attributes: key="literal" or key={expr}
 *   • Exprs: Supports @assigns access, field access, bracket access, literals,
 *            and common binary operators (||, &&, ==, !=, <=, >=, <, >)
 *   • Inline attribute if: {if cond, do: "..."[, else: "..."]}
 * - On unrecognized constructs, falls back to ERaw to preserve the original expression string.
 *
 * EXAMPLES
 * Haxe:
 *   @:heex '<div class={@active ? "on" : "off"} phx-click={@click}></div>'
 * EFragments (typed):
 *   EFragment("div", [
 *     {name: "class", value: EIf(EBinary(Equal, EAssign("active"), EBoolean(true)), EString("on"), EString("off"))},
 *     {name: "phx-click", value: EAssign("click")}
 *   ], [])
 */
class HeexFragmentBuilder {
    // Public API ------------------------------------------------------------
    public static function build(content: String): Array<ElixirAST> {
        if (content == null || content.length == 0) return [];
        var p = new Parser(content);
        return p.parseNodes();
    }
}

private class Parser {
    final s: String;
    var i: Int = 0;

    public function new(s: String) {
        this.s = s;
        this.i = 0;
    }

    // Top-level: parse sequence of nodes until end
    public function parseNodes(): Array<ElixirAST> {
        var out: Array<ElixirAST> = [];
        while (!eof()) {
            skipWs();
            if (eof()) break;
            if (peek() == '<') {
                var node = parseElement();
                if (node != null) out.push(node);
                else advance(1); // avoid infinite loop
            } else {
                // Text node: collect until next '<'
                var start = i;
                var lt = s.indexOf('<', i);
                var end = lt == -1 ? s.length : lt;
                var txt = s.substr(start, end - start);
                i = end;
                if (txt.trim().length > 0) out.push(makeAST(EString(txt)));
            }
        }
        return out;
    }

    // <tag ...> ... </tag> or self-closing <tag .../>
    function parseElement(): Null<ElixirAST> {
        var start = i;
        if (!consume('<')) return null;
        // Closing tag -> caller should handle
        if (peek() == '/') { i = start; return null; }
        var tag = parseTagName();
        if (tag == null) { i = start; return null; }
        var attrs = parseAttributes();
        skipWs();
        var selfClosing = false;
        if (peek() == '/') { selfClosing = true; advance(1); }
        if (!consume('>')) { i = start; return null; }

        var children: Array<ElixirAST> = [];
        if (!selfClosing) {
            // Parse children until closing tag
            while (!eof()) {
                skipWs();
                if (peek() == '<' && peek2() == '/') {
                    // </tag>
                    advance(2);
                    var close = parseTagName();
                    skipWs();
                    consume('>');
                    break;
                } else if (peek() == '<') {
                    var child = parseElement();
                    if (child != null) children.push(child) else advance(1);
                } else {
                    // text or raw eex
                    var tstart = i;
                    var lt = s.indexOf('<', i);
                    var end = lt == -1 ? s.length : lt;
                    var txt = s.substr(tstart, end - tstart);
                    i = end;
                    if (txt.trim().length > 0) children.push(makeAST(EString(txt)));
                }
            }
        }
        return makeAST(EFragment(tag, attrs, children));
    }

    function parseTagName(): Null<String> {
        skipWs();
        var start = i;
        while (!eof()) {
            var ch = peek();
            if (isTagChar(ch)) advance(1) else break;
        }
        return i > start ? s.substr(start, i - start) : null;
    }

    function isTagChar(ch: String): Bool {
        if (ch == null || ch.length == 0) return false;
        var c = ch.charCodeAt(0);
        // letters, digits, underscore, dash, dot (to support Phoenix <.component>)
        return (c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code)
            || (c >= '0'.code && c <= '9'.code) || ch == '_' || ch == '-' || ch == '.' || ch == ':';
    }

    function parseAttributes(): Array<EAttribute> {
        var attrs: Array<EAttribute> = [];
        while (!eof()) {
            skipWs();
            var c = peek();
            if (c == '>' || c == '/' || c == null) break;
            var name = parseAttrName();
            if (name == null) break;
            skipWs();
            var valueAst: ElixirAST = null;
            if (consume('=')) {
                skipWs();
                var q = peek();
                if (q == '"' || q == '\'') {
                    valueAst = makeAST(EString(parseQuotedString()));
                } else if (q == '{') {
                    advance(1); // consume {
                    var exprStart = i;
                    var depth = 1;
                    while (!eof() && depth > 0) {
                        var ch = peek();
                        if (ch == '{') depth++; else if (ch == '}') depth--; advance(1);
                    }
                    var expr = s.substr(exprStart, (i - 1) - exprStart);
                    valueAst = parseAttrExpr(expr);
                } else {
                    // Bareword value until ws or tag end
                    var vs = i;
                    while (!eof()) { var ch2 = peek(); if (isWs(ch2) || ch2 == '>' || ch2 == '/') break; advance(1); }
                    valueAst = makeAST(EString(s.substr(vs, i - vs)));
                }
            } else {
                // Boolean attribute
                valueAst = makeAST(EBoolean(true));
            }
            attrs.push({name: name, value: valueAst});
        }
        return attrs;
    }

    function parseAttrName(): Null<String> {
        skipWs();
        var start = i;
        while (!eof()) {
            var ch = peek();
            if (isIdentChar(ch) || ch == ':' || ch == '-' ) advance(1); else break;
        }
        return i > start ? s.substr(start, i - start) : null;
    }

    // ---------------- Expression parsing (attribute { ... }) -----------------
    function parseAttrExpr(expr: String): ElixirAST {
        var ep = new ExprParser(expr);
        return ep.parse();
    }

    // --------------------- Low-level helpers --------------------------------
    inline function eof(): Bool return i >= s.length;
    inline function peek(): String return i < s.length ? s.charAt(i) : null;
    inline function peek2(): String return i + 1 < s.length ? s.charAt(i + 1) : null;
    inline function advance(n:Int): Void i += n;
    function consume(ch: String): Bool { if (peek() == ch) { i++; return true; } return false; }
    function skipWs(): Void { while (!eof() && isWs(peek())) i++; }
    static inline function isWs(ch: String): Bool return ch != null && ~/^\s$/.match(ch);
    static inline function isIdentStart(ch: String): Bool {
        if (ch == null || ch.length == 0) return false;
        var c = ch.charCodeAt(0);
        return (c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code) || ch == '_';
    }
    static inline function isIdentChar(ch: String): Bool {
        if (ch == null || ch.length == 0) return false;
        var c = ch.charCodeAt(0);
        return isIdentStart(ch) || (c >= '0'.code && c <= '9'.code);
    }

    function parseQuotedString(): String {
        var q = peek();
        if (q != '"' && q != '\'') return "";
        advance(1);
        var start = i;
        while (!eof() && peek() != q) advance(1);
        var val = s.substr(start, i - start);
        if (peek() == q) advance(1);
        return val;
    }
}

private class ExprParser {
    final s: String;
    var i: Int = 0;

    public function new(s: String) {
        this.s = s.trim();
        this.i = 0;
    }

    public function parse(): ElixirAST {
        // Special-case inline if: if cond, do: "then"[, else: "else"]
        if (StringTools.startsWith(s, "if ")) {
            return parseInlineIf();
        }
        return parseBinary();
    }

    function parseInlineIf(): ElixirAST {
        // Format expected (from TemplateHelpers): if <cond>, do: "..."[, else: "..."]
        // Consume 'if '
        i = 3;
        skipWs();
        var condStart = i;
        var commaDo = indexOfTopLevel(", do:", i);
        if (commaDo == -1) return makeAST(ERaw(s));
        var condStr = StringTools.trim(s.substr(condStart, commaDo - condStart));
        i = commaDo + 5;
        skipWs();
        var thenStr = parseQuoted();
        if (thenStr == null) return makeAST(ERaw(s));
        skipWs();
        var elseExpr: Null<ElixirAST> = null;
        var commaElse = indexOfTopLevel(", else:", i);
        if (commaElse != -1) {
            i = commaElse + 7;
            skipWs();
            var elseStr = parseQuoted();
            if (elseStr != null) elseExpr = makeAST(EString(elseStr));
        }
        var condAst = new ExprParser(condStr).parse();
        return makeAST(EIf(condAst, makeAST(EString(thenStr)), elseExpr));
    }

    function parseQuoted(): Null<String> {
        skipWs();
        if (peek() != '"' && peek() != '\'') return null;
        var q = peek(); advance(1);
        var start = i;
        while (!eof() && peek() != q) advance(1);
        var str = s.substr(start, i - start);
        if (!eof()) advance(1);
        return str;
    }

    // Pratt-style parser for simple precedence
    function parseBinary(minPrec: Int = 0): ElixirAST {
        var left = parsePrimary();
        while (true) {
            skipWs();
            var op = peekOp();
            if (op == null) break;
            var prec = precedence(op);
            if (prec < minPrec) break;
            // consume op
            advance(op.length);
            var right = parseBinary(prec + 1);
            var bin = toBinary(op, left, right);
            left = makeAST(bin);
        }
        return left;
    }

    function parsePrimary(): ElixirAST {
        skipWs();
        var ch = peek();
        if (ch == '"' || ch == '\'') {
            var q = parseQuoted();
            return makeAST(EString(q));
        }
        // numbers
        if (isDigit(ch)) {
            var n = parseNumber();
            return makeAST(EInteger(n));
        }
        // booleans/nil
        if (startsWith("true")) { advance(4); return makeAST(EBoolean(true)); }
        if (startsWith("false")) { advance(5); return makeAST(EBoolean(false)); }
        if (startsWith("nil")) { advance(3); return makeAST(ENil); }
        // @assigns
        if (ch == '@') {
            advance(1);
            var name = parseIdent();
            var base: ElixirAST = makeAST(EAssign(name));
            return parsePostfix(base);
        }
        // identifier
        if (isIdentStart(ch)) {
            var name = parseIdent();
            var base: ElixirAST = makeAST(EVar(name));
            return parsePostfix(base);
        }
        // fallback raw
        return makeAST(ERaw(remaining()));
    }

    function parsePostfix(base: ElixirAST): ElixirAST {
        while (true) {
            skipWs();
            if (peek() == '.') {
                advance(1);
                var field = parseIdent();
                base = makeAST(EField(base, field));
                continue;
            }
            if (peek() == '[') {
                advance(1);
                // simple index: string or identifier or @assigns
                skipWs();
                var idxAst: ElixirAST = null;
                if (peek() == '"' || peek() == '\'') idxAst = makeAST(EString(parseQuoted()));
                else if (peek() == '@') { advance(1); idxAst = makeAST(EAssign(parseIdent())); }
                else if (isIdentStart(peek())) idxAst = makeAST(EVar(parseIdent()));
                else {
                    // allow nested expr inside index
                    var start = i;
                    while (!eof() && peek() != ']') advance(1);
                    idxAst = makeAST(ERaw(s.substr(start, i - start)));
                }
                if (peek() == ']') advance(1);
                base = makeAST(EAccess(base, idxAst));
                continue;
            }
            break;
        }
        return base;
    }

    function peekOp(): Null<String> {
        skipWs();
        // check multi-char first
        var ops = ["&&", "||", "<=", ">=", "==", "!="];
        for (o in ops) if (startsWith(o)) return o;
        // single-char
        var c = peek();
        if (c == '<' || c == '>' ) return c;
        return null;
    }

    function toBinary(op: String, l: ElixirAST, r: ElixirAST): ElixirASTDef {
        return switch (op) {
            case "&&": EBinary(AndAlso, l, r);
            case "||": EBinary(OrElse, l, r);
            case "==": EBinary(Equal, l, r);
            case "!=": EBinary(NotEqual, l, r);
            case "<=": EBinary(LessEqual, l, r);
            case ">=": EBinary(GreaterEqual, l, r);
            case "<": EBinary(Less, l, r);
            case ">": EBinary(Greater, l, r);
            default: EBinary(Equal, l, r); // should not happen; keep parsable
        }
    }

    function precedence(op: String): Int {
        return switch (op) {
            case "&&": 3;
            case "||": 3;
            case "==", "!=", "<", ">", "<=", ">=": 2;
            default: 1;
        }
    }

    // --------------------- Helpers ---------------------
    inline function eof(): Bool return i >= s.length;
    inline function peek(): String return i < s.length ? s.charAt(i) : null;
    inline function advance(n:Int): Void i += n;
    function skipWs(): Void { while (!eof() && isWs(peek())) i++; }
    static inline function isWs(ch: String): Bool return ch != null && ~/^\s$/.match(ch);
    static inline function isDigit(ch: String): Bool {
        if (ch == null || ch.length == 0) return false; var c = ch.charCodeAt(0);
        return (c >= '0'.code && c <= '9'.code);
    }
    static inline function isIdentStart(ch: String): Bool {
        if (ch == null || ch.length == 0) return false; var c = ch.charCodeAt(0);
        return (c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code) || ch == '_';
    }
    function parseIdent(): String {
        var start = i;
        if (!isIdentStart(peek())) return "";
        advance(1);
        while (!eof()) {
            var ch = peek();
            var c = ch.charCodeAt(0);
            if ((c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code) || (c >= '0'.code && c <= '9'.code) || ch == '_' ) {
                advance(1);
            } else break;
        }
        return s.substr(start, i - start);
    }
    function parseNumber(): Int {
        var start = i; while (!eof() && isDigit(peek())) advance(1);
        return Std.parseInt(s.substr(start, i - start));
    }
    inline function startsWith(t: String): Bool return s.substr(i, t.length) == t;
    inline function remaining(): String return i < s.length ? s.substr(i) : "";
    function indexOfTopLevel(token: String, startAt: Int): Int {
        var depth = 0;
        var inS = false, inD = false;
        var i = startAt;
        while (i <= this.s.length - token.length) {
            var ch = this.s.charAt(i);
            if (!inS && ch == '"' && !inD) { inD = true; i++; continue; }
            else if (inD && ch == '"') { inD = false; i++; continue; }
            if (!inD && ch == '\'' && !inS) { inS = true; i++; continue; }
            else if (inS && ch == '\'') { inS = false; i++; continue; }
            if (inS || inD) { i++; continue; }
            if (ch == '(' || ch == '{' || ch == '[') { depth++; i++; continue; }
            else if (ch == ')' || ch == '}' || ch == ']') { depth--; i++; continue; }
            if (depth == 0 && this.s.substr(i, token.length) == token) return i;
            i++;
        }
        return -1;
    }
}

#end
