package reflaxe.elixir.macros.heex_tsx;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * HeexTsxParser
 *
 * WHAT
 * - Macro-time parser for TSX-mode HEEx templates.
 * - Converts a markup string into a structured AST (`phoenix.hxx.ast.HeexNode` / `HeexAttr`)
 *   with embedded `${ ... }` expressions parsed as real Haxe `Expr` nodes.
 *
 * WHY
 * - Enables Coconut/tink-style authoring:
 *   - `<for ${item in assigns.items}>...</for>`
 *   - `<if ${cond}>...</if><else>...</else>`
 *   - fragment roots: `<>...</>`
 * - Avoids string-rewrite heuristics and keeps embedded expressions type-checked by Haxe.
 *
 * HOW
 * - Single-pass recursive descent over the template string.
 * - Embedded expressions are parsed with `Context.parseInlineString` using best-effort sub-positions.
 * - The output is an `Expr` that constructs the template AST (compile-time only), later lowered by
 *   the backend when it sees `HeexTemplate.root_ast(node)`.
 */
class HeexTsxParser {
    public static function parseRoot(template: String, templatePos: Position): Expr {
        var parser = new Parser(template, templatePos);
        var nodes = parser.parseNodesUntil(null);
        if (!parser.eof()) {
            parser.failHere("Unexpected trailing input in template");
        }
        // Root normalization: if multiple children, wrap in Fragment.
        if (nodes.length == 1) return nodes[0];
        return parser.mkFragment(nodes, templatePos);
    }
}

private class Parser {
    final src: String;
    final basePos: Position;
    var i: Int = 0;

    public function new(src: String, basePos: Position) {
        this.src = src == null ? "" : src;
        this.basePos = basePos;
    }

    public inline function eof(): Bool return i >= src.length;

    inline function ch(at: Int): String return src.charAt(at);

    inline function startsWith(s: String): Bool {
        if (s == null) return false;
        if (i + s.length > src.length) return false;
        return src.substr(i, s.length) == s;
    }

    inline function skipWs(): Void {
        while (!eof()) {
            var c = ch(i);
            if (c == " " || c == "\t" || c == "\n" || c == "\r") i++ else break;
        }
    }

    function makeSubPos(startOffset: Int, endOffset: Int): Position {
        var info = Context.getPosInfos(basePos);
        var min = info.min + (startOffset < 0 ? 0 : startOffset);
        var max = info.min + (endOffset < startOffset ? startOffset : endOffset);
        if (max > info.max) max = info.max;
        if (min > info.max) min = info.max;
        return Context.makePosition({ file: info.file, min: min, max: max });
    }

    public function failHere(msg: String): Void {
        Context.error(msg, makeSubPos(i, i + 1));
    }

    function expect(s: String, msg: String): Void {
        if (!startsWith(s)) failHere(msg);
        i += s.length;
    }

    function readUntil(stop: (Int) -> Bool): String {
        var start = i;
        while (!eof() && !stop(i)) i++;
        return src.substr(start, i - start);
    }

    function readName(): String {
        skipWs();
        if (eof()) failHere("Expected name");
        var start = i;
        while (!eof()) {
            var c = ch(i);
            var ok = (c >= "a" && c <= "z")
                || (c >= "A" && c <= "Z")
                || (c >= "0" && c <= "9")
                || c == "_" || c == "-" || c == ":" || c == "."; // include . for Phoenix components
            if (!ok) break;
            i++;
        }
        if (i == start) failHere("Expected name");
        return src.substr(start, i - start);
    }

    function parseBalanced(open: String, close: String): { text: String, start: Int, end: Int } {
        // (legacy helper retained for future non-curly delimiters)
        expect(open, 'Expected "' + open + '"');
        var start = i;
        var depth = 1;
        while (!eof()) {
            var c = ch(i);
            if (c == open) depth++;
            if (c == close) {
                depth--;
                if (depth == 0) {
                    var end = i;
                    i++; // consume close
                    return { text: src.substr(start, end - start), start: start, end: end + 1 };
                }
            }
            i++;
        }
        failHere('Missing closing "' + close + '"');
        return { text: "", start: start, end: start };
    }

    function readCurlyContent(): { text: String, start: Int, end: Int } {
        // assumes current i is positioned *after* the opening '{' (or after '${')
        var start = i;
        var depth = 1;
        while (!eof()) {
            var c = ch(i);
            if (c == "{") {
                depth++;
                i++;
                continue;
            }
            if (c == "}") {
                depth--;
                if (depth == 0) {
                    var end = i;
                    i++; // consume closing }
                    return { text: src.substr(start, end - start), start: start, end: end + 1 };
                }
                i++;
                continue;
            }
            i++;
        }
        failHere("Missing closing '}'");
        return { text: "", start: start, end: start };
    }

    function parseExprInBraces(allowEmpty: Bool): Expr {
        // Supports `${ ... }` and `{ ... }`
        skipWs();
        var startOffset = i;
        var exprText = null;
        var innerStart = -1;
        var innerEnd = -1;
        if (startsWith("${")) {
            i += 2; // consume ${
            innerStart = i;
            var balanced = readCurlyContent();
            exprText = balanced.text;
            innerEnd = balanced.end;
        } else if (startsWith("{")) {
            i += 1; // consume {
            innerStart = i;
            var balanced2 = readCurlyContent();
            exprText = balanced2.text;
            innerEnd = balanced2.end;
        } else {
            failHere("Expected ${ ... } expression");
        }
        if (exprText == null) exprText = "";
        if (!allowEmpty && StringTools.trim(exprText).length == 0) {
            Context.error("Expected expression", makeSubPos(startOffset, innerEnd));
        }
        var pos = makeSubPos(innerStart, innerEnd);
        try {
            return Context.parseInlineString(exprText, pos);
        } catch (e: haxe.macro.Error) {
            throw e;
        } catch (e: Dynamic) {
            Context.error(Std.string(e), pos);
        }
        return macro null;
    }

    function mkArray(exprs: Array<Expr>, pos: Position): Expr {
        return { expr: EArrayDecl(exprs), pos: pos };
    }

    function mkText(s: String, pos: Position): Expr {
        return macro @:pos(pos) phoenix.hxx.ast.HeexNode.Text($v{s});
    }

    function mkExprText(e: Expr, pos: Position): Expr {
        return macro @:pos(pos) phoenix.hxx.ast.HeexNode.ExprText($e);
    }

    public function mkFragment(children: Array<Expr>, pos: Position): Expr {
        return macro @:pos(pos) phoenix.hxx.ast.HeexNode.Fragment(${mkArray(children, pos)});
    }

    function mkElement(name: String, attrs: Array<Expr>, children: Array<Expr>, pos: Position): Expr {
        return macro @:pos(pos) phoenix.hxx.ast.HeexNode.Element($v{name}, ${mkArray(attrs, pos)}, ${mkArray(children, pos)});
    }

    function mkIf(cond: Expr, thenNode: Expr, elseNode: Null<Expr>, pos: Position): Expr {
        return macro @:pos(pos) phoenix.hxx.ast.HeexNode.If($cond, $thenNode, ${elseNode == null ? (macro null) : elseNode});
    }

    function mkFor(items: Expr, binderName: String, body: Expr, pos: Position): Expr {
        var arg: FunctionArg = { name: binderName, type: null, opt: false, value: null, meta: null };
        // Use an explicit return so the typer never interprets this as a statement-only function body.
        var returnedBody: Expr = { expr: EReturn(body), pos: pos };
        var fn: Function = { args: [arg], ret: null, expr: returnedBody, params: [] };
        var fnExpr: Expr = { expr: EFunction(FArrow, fn), pos: pos };
        return macro @:pos(pos) phoenix.hxx.ast.HeexNode.For($items, $fnExpr);
    }

    function mkAttrStatic(name: String, value: String, pos: Position): Expr {
        return macro @:pos(pos) phoenix.hxx.ast.HeexAttr.Static($v{name}, $v{value});
    }

    function mkAttrBool(name: String, pos: Position): Expr {
        return macro @:pos(pos) phoenix.hxx.ast.HeexAttr.Bool($v{name});
    }

    function mkAttrExpr(name: String, value: Expr, pos: Position): Expr {
        return macro @:pos(pos) phoenix.hxx.ast.HeexAttr.Expr($v{name}, $value);
    }

    inline function mkConstStringExpr(s: String, pos: Position): Expr {
        return { expr: EConst(CString(s, null)), pos: pos };
    }

    function mkConcatExpr(parts: Array<Expr>, pos: Position): Expr {
        if (parts == null || parts.length == 0) return mkConstStringExpr("", pos);
        if (parts.length == 1) return parts[0];
        var acc = parts[0];
        for (idx in 1...parts.length) {
            acc = { expr: EBinop(OpAdd, acc, parts[idx]), pos: pos };
        }
        return acc;
    }

    function parseTextNodesUntilTag(): Array<Expr> {
        var out: Array<Expr> = [];
        var textStart = i;
        while (!eof()) {
            if (startsWith("<")) break;
            if (startsWith("${")) break;
            i++;
        }
        var lit = src.substr(textStart, i - textStart);
        if (lit.length > 0) out.push(mkText(lit, makeSubPos(textStart, i)));

        while (startsWith("${")) {
            var exprStart = i;
            var expr = parseExprInBraces(false);
            out.push(mkExprText(expr, makeSubPos(exprStart, i)));
            // collect following literal segment
            var segStart = i;
            while (!eof()) {
                if (startsWith("<") || startsWith("${")) break;
                i++;
            }
            var seg = src.substr(segStart, i - segStart);
            if (seg.length > 0) out.push(mkText(seg, makeSubPos(segStart, i)));
        }

        return out;
    }

    public function parseNodesUntil(closing: Null<String>): Array<Expr> {
        var nodes: Array<Expr> = [];
        while (!eof()) {
            // Stop early for callers that want to delimit on a raw token.
            // (Used by <if>/<else> parsing.)
            //
            // NOTE: This is intentionally minimal and only used internally via parseNodesUntilStop.
            if (startsWith("<!--")) {
                var cStart = i;
                var end = src.indexOf("-->", i + 4);
                if (end == -1) Context.error("Unclosed HTML comment", makeSubPos(cStart, src.length));
                i = end + 3;
                continue;
            }

            if (startsWith("</>")) {
                if (closing == "fragment") {
                    i += 3;
                    return nodes;
                }
                failHere("Unexpected </> fragment close");
            }

            if (startsWith("</")) {
                if (closing == null) failHere("Unexpected closing tag");
                var closeStart = i;
                i += 2;
                var name = readName();
                skipWs();
                expect(">", "Expected '>' after closing tag");
                if (name != closing) {
                    Context.error('Mismatched closing tag: expected </' + closing + '> but found </' + name + '>', makeSubPos(closeStart, i));
                }
                return nodes;
            }

            if (startsWith("<")) {
                nodes.push(parseTagNode());
                continue;
            }

            // Text (with ${...} splices)
            var textNodes = parseTextNodesUntilTag();
            for (n in textNodes) nodes.push(n);
        }
        if (closing != null) {
            Context.error("Unclosed <" + closing + "> tag", makeSubPos(i, i));
        }
        return nodes;
    }

    function parseNodesUntilStop(shouldStop: () -> Bool): Array<Expr> {
        var out: Array<Expr> = [];
        while (!eof() && !shouldStop()) {
            if (startsWith("<!--")) {
                var cStart = i;
                var end = src.indexOf("-->", i + 4);
                if (end == -1) Context.error("Unclosed HTML comment", makeSubPos(cStart, src.length));
                i = end + 3;
                continue;
            }

            // Stop-based parsing is only used inside <if>. We must not consume the delimiters.
            if (startsWith("<else>") || startsWith("</else>") || startsWith("</if>")) break;

            if (startsWith("</>") || startsWith("</")) {
                break;
            }

            if (startsWith("<")) {
                out.push(parseTagNode());
                continue;
            }

            var texts = parseTextNodesUntilTag();
            for (t in texts) out.push(t);
        }
        return out;
    }

    function parseTagNode(): Expr {
        var tagStart = i;
        expect("<", "Expected '<' to start a tag");

        if (startsWith(">")) {
            i++; // consume '>'
            var fragChildren = parseNodesUntil("fragment");
            return mkFragment(fragChildren, makeSubPos(tagStart, i));
        }

        var name = readName();

        if (name == "if") {
            skipWs();
            var cond = parseExprInBraces(false);
            skipWs();
            expect(">", "Expected '>' after <if ${...}>");

            var thenNodes = parseNodesUntilStop(() -> startsWith("<else>") || startsWith("</if>"));
            var elseNodes: Null<Array<Expr>> = null;
            if (startsWith("<else>")) {
                i += 6;
                elseNodes = parseNodesUntilStop(() -> startsWith("</else>") || startsWith("</if>"));
                if (startsWith("</else>")) {
                    i += 7;
                }
            }
            skipWs();
            expect("</if>", "Expected </if> to close <if>");

            var thenNode: Expr = thenNodes.length == 1 ? thenNodes[0] : mkFragment(thenNodes, makeSubPos(tagStart, i));
            var elseNode: Null<Expr> = null;
            if (elseNodes != null) {
                elseNode = elseNodes.length == 1 ? elseNodes[0] : mkFragment(elseNodes, makeSubPos(tagStart, i));
            }
            return mkIf(cond, thenNode, elseNode, makeSubPos(tagStart, i));
        }

        if (name == "for") {
            skipWs();
            var headExpr = parseExprInBraces(false);
            skipWs();
            expect(">", "Expected '>' after <for ${...}>");

            var binderName = switch (headExpr.expr) {
                case EBinop(OpIn, left, _):
                    switch (left.expr) {
                        case EConst(CIdent(id)):
                            id;
                        default:
                            Context.error("TSX <for>: binder must be an identifier (e.g. <for ${item in items}>)", left.pos);
                    }
                default:
                    Context.error("TSX <for>: expected `binder in iterable` (e.g. <for ${item in items}>)", headExpr.pos);
            };
            var itemsExpr = switch (headExpr.expr) {
                case EBinop(OpIn, _, right):
                    right;
                default:
                    headExpr;
            };

            var bodyNodes = parseNodesUntil("for");
            var body: Expr = bodyNodes.length == 1 ? bodyNodes[0] : mkFragment(bodyNodes, makeSubPos(tagStart, i));
            return mkFor(itemsExpr, binderName, body, makeSubPos(tagStart, i));
        }

        // Regular element: attributes + children
        var attrs: Array<Expr> = [];
        var selfClosing = false;
        while (!eof()) {
            skipWs();
            if (startsWith("/>")) {
                selfClosing = true;
                i += 2;
                break;
            }
            if (startsWith(">")) {
                i += 1;
                break;
            }
            var attrStart = i;
            var attrName = readName();
            skipWs();
            if (startsWith("=")) {
                i++;
                skipWs();
                if (startsWith("\"") || startsWith("'")) {
                    var quote = ch(i);
                    i++;
                    var valueStart = i;
                    var literalStart = i;
                    var parts: Array<Expr> = [];
                    var hasSplice = false;
                    while (!eof() && ch(i) != quote) {
                        if (startsWith("${")) {
                            hasSplice = true;
                            if (i > literalStart) {
                                parts.push(mkConstStringExpr(src.substr(literalStart, i - literalStart), makeSubPos(literalStart, i)));
                            }
                            var exprStart = i;
                            var expr = parseExprInBraces(false);
                            parts.push({ expr: EParenthesis(expr), pos: makeSubPos(exprStart, i) });
                            literalStart = i;
                            continue;
                        }
                        i++;
                    }
                    if (eof()) Context.error("Unclosed attribute string", makeSubPos(valueStart, i));
                    if (i > literalStart) {
                        parts.push(mkConstStringExpr(src.substr(literalStart, i - literalStart), makeSubPos(literalStart, i)));
                    }
                    var endQuoteOffset = i;
                    i++; // consume quote
                    if (!hasSplice) {
                        attrs.push(mkAttrStatic(attrName, src.substr(valueStart, endQuoteOffset - valueStart), makeSubPos(attrStart, i)));
                    } else {
                        attrs.push(mkAttrExpr(attrName, mkConcatExpr(parts, makeSubPos(valueStart, endQuoteOffset)), makeSubPos(attrStart, i)));
                    }
                } else if (startsWith("${") || startsWith("{")) {
                    var expr = parseExprInBraces(false);
                    attrs.push(mkAttrExpr(attrName, expr, makeSubPos(attrStart, i)));
                } else {
                    var token = readUntil((at) -> {
                        var c = src.charAt(at);
                        c == " " || c == "\t" || c == "\n" || c == "\r" || c == ">" || (c == "/" && at + 1 < src.length && src.charAt(at + 1) == ">");
                    });
                    attrs.push(mkAttrStatic(attrName, token, makeSubPos(attrStart, i)));
                }
            } else {
                attrs.push(mkAttrBool(attrName, makeSubPos(attrStart, i)));
            }
        }

        if (selfClosing) {
            return mkElement(name, attrs, [], makeSubPos(tagStart, i));
        }

        var children = parseNodesUntil(name);
        return mkElement(name, attrs, children, makeSubPos(tagStart, i));
    }
}

#end
