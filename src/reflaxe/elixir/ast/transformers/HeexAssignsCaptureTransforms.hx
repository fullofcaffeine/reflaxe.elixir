package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * HeexAssignsCaptureTransforms
 *
 * WHAT
 * - As a robustness sweep for render(assigns), replace ~H content that renders
 *   Phoenix.HTML.raw(content) with the previously assigned string literal
 *   content. Drops the intermediate local, eliminating HEEx warnings about
 *   accessing local variables in templates.
 *
 * WHY
 * - LiveView requires assigns for template variables. Some builders emit a
 *   pattern of:
 *     content = "...html...";
 *     ~H"""<%= Phoenix.HTML.raw(content) %>"""
 *   This triggers warnings. Inlining the literal html into ~H resolves it
 *   without introducing app-specific logic.
 *
 * HOW
 * - Within EDef("render", _, _, EBlock(stmts)):
 *   1) Locate assignment to variable named "content" where RHS is a string
 *      literal (allow optional parentheses).
 *   2) Locate ESigil("H", s, _) where s contains "Phoenix.HTML.raw(content)".
 *   3) Replace ESigil content with the literal html and remove the assignment.
 *
 * EXAMPLES
 * Elixir (before):
 *   content = "<b>Hi</b>"
 *   ~H"""
 *   <%= Phoenix.HTML.raw(content) %>
 *   """
 * Elixir (after):
 *   ~H"""
 *   <%= Phoenix.HTML.raw(@content) %>
 *   """
 */
class HeexAssignsCaptureTransforms {
    static function extractStringLiteral(e: ElixirAST): Null<String> {
        var cur = e;
        var depth = 0;
        while (true) {
            switch (cur.def) {
                case EString(s): return s;
                case ESigil(type, content, _mods) if (type == "H"): return content;
                case EParen(inner): cur = inner; depth++;
                default: return null;
            }
        }
        return null;
    }

    static function findHeexSigil(stmts: Array<ElixirAST>): { idx:Int, parens:Int } {
        for (i in 0...stmts.length) {
            var parens = 0;
            var node = stmts[i];
            var found = false;
            // unwrap up to two levels of parens
            for (k in 0...3) {
                switch (node.def) {
                    case ESigil(type, content, modifiers) if (type == "H" && content.indexOf("Phoenix.HTML.raw(content)") != -1):
                        found = true; break;
                    case ERaw(code) if (code.indexOf("~H\"") != -1 && code.indexOf("Phoenix.HTML.raw(content)") != -1):
                        found = true; break;
                    case EParen(inner): node = inner; parens++; continue;
                    default:
                }
                break;
            }
            if (found) return { idx: i, parens: parens };
        }
        return { idx: -1, parens: 0 };
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body) if (name == "render"):
                    switch (body.def) {
                        case EBlock(stmts):
                            var html: Null<String> = null;
                            var assignIdx = -1;
                            for (i in 0...stmts.length) {
                                switch (stmts[i].def) {
                                    case EMatch(PVar(varName), rhs) if (varName == "content"):
                                        var lit = extractStringLiteral(rhs);
                                        if (lit != null) { html = lit; assignIdx = i; }
                                    default:
                                }
                            }
                            var heex = findHeexSigil(stmts);
                            if (heex.idx == -1) return node;
                            // DISABLED: trace('[HeexAssignsCapture] Found candidate in render/1: assignIdx=' + assignIdx + ', heexIdx=' + heex.idx + ', hasHtml=' + (html != null));
                            var newStmts = [];
                            for (i in 0...stmts.length) {
                                // Drop the content assignment if we have an html replacement
                                if (i == assignIdx && html != null) continue;
                                if (i == heex.idx) {
                                    // Inline the html into ~H content, removing the content/temp indirection
                                    var node = stmts[i];
                                    var parens = heex.parens;
                                    // unwrap to ESigil
                                    while (parens > 0) {
                                        switch (node.def) {
                                            case EParen(inner): node = inner; parens--; default:
                                        }
                                    }
                                    switch (node.def) {
                                        case ESigil(type, content, modifiers) if (type == "H"):
                                            var newContent = (html != null) ? html : content;
                                            var rebuilt: ElixirAST = makeAST(ESigil("H", newContent, modifiers));
                                            // rewrap to original depth
                                            for (p in 0...heex.parens) rebuilt = makeAST(EParen(rebuilt));
                                            newStmts.push(makeASTWithMeta(rebuilt.def, stmts[i].metadata, stmts[i].pos));
                                        case ERaw(code):
                                            var code2 = code;
                                            if (html != null) code2 = code.split("<%= Phoenix.HTML.raw(content) %>").join(html);
                                            // If this ERaw wraps a ~H sigil, convert to ESigil so later passes (strip .to_string, etc.) apply
                                            var idx = code2.indexOf('~H"""');
                                            if (idx != -1) {
                                                var start = idx + 4; // after ~H"""
                                                var endIdx = code2.indexOf('"""', start);
                                                if (endIdx != -1) {
                                                    var sigilContent = cleanSigil(code2.substr(start, endIdx - start));
                                                    var rebuilt2: ElixirAST = makeAST(ESigil("H", sigilContent, ""));
                                                    for (p in 0...heex.parens) rebuilt2 = makeAST(EParen(rebuilt2));
                                                    newStmts.push(makeASTWithMeta(rebuilt2.def, stmts[i].metadata, stmts[i].pos));
                                                    break;
                                                }
                                            }
                                            var fallbackNode: ElixirAST = makeAST(ERaw(code2));
                                            for (p in 0...heex.parens) fallbackNode = makeAST(EParen(fallbackNode));
                                            newStmts.push(makeASTWithMeta(fallbackNode.def, stmts[i].metadata, stmts[i].pos));
                                        default:
                                            newStmts.push(stmts[i]);
                                    }
                                } else {
                                    newStmts.push(stmts[i]);
                                }
                            }
                            return makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(newStmts))), node.metadata, node.pos);
                        default:
                            node;
                    }
                default:
                    node;
            }
        });
    }

    static function cleanSigil(s: String): String {
        var lines = s.split("\n");
        var out = [];
        for (ln in lines) {
            var t = StringTools.replace(ln, "\r", "");
            t = StringTools.trim(t);
            if (t == '"' || t == "'") continue;
            out.push(ln);
        }
        return out.join("\n");
    }
}

#end
