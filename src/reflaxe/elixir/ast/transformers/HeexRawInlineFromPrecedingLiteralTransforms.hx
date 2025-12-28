package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexRawInlineFromPrecedingLiteralTransforms
 *
 * WHAT
 * - In render(assigns), when a string literal is produced immediately before a ~H block
 *   that renders it via `<%= Phoenix.HTML.raw(content) %>` or `<%= Phoenix.HTML.raw(@content) %>`,
 *   inline the literal HTML as the ~H body and drop the preceding literal statement.
 *
 * WHY
 * - Avoids using local variables inside HEEx templates (which triggers warnings-as-errors)
 *   and removes the need for temporary assigns capture. This produces idiomatic ~H markup
 *   without intermediate locals.
 *
 * HOW
 * - For EDef("render", _, _, EBlock(stmts)):
 *   - Scan for index i where stmts[i] is an EString or EParen(EString)
 *   - If stmts[i+1] is ESigil("H", content, mods) and content contains `Phoenix.HTML.raw(content)`
 *     or `Phoenix.HTML.raw(@content)`, replace stmts[i+1] body with the string literal and
 *     remove stmts[i].

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HeexRawInlineFromPrecedingLiteralTransforms {
    static function extractStringLiteral(e: ElixirAST): Null<String> {
        var cur = e;
        while (true) {
            switch (cur.def) {
                case EString(s): return s;
                case EParen(inner): cur = inner;
                default: return null;
            }
        }
        return null;
    }

    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "render"):
                    switch (body.def) {
                        case EBlock(stmts):
                            var out:Array<ElixirAST> = [];
                            var i = 0;
                            while (i < stmts.length) {
                                var s = stmts[i];
                                var inlined = false;
                                var lit = extractStringLiteral(s);
                                // Also support content = "..." assignments (EBinary or EMatch)
                                if (lit == null) switch (s.def) {
                                    case EBinary(Match, _left, rhs):
                                        lit = extractStringLiteral(rhs);
                                    case EMatch(_pat, rhs2):
                                        if (lit == null) lit = extractStringLiteral(rhs2);
                                    default:
                                }
                                if (lit != null) {
                                    // Find the next ~H that uses Phoenix.HTML.raw(content or @content)
                                    var j = i + 1;
                                    var foundIdx = -1;
                                    var parens = 0;
                                    var target: ElixirAST = null;
                                    while (j < stmts.length) {
                                        parens = 0;
                                        target = stmts[j];
                                        // unwrap up to two levels of parens
                                        for (k in 0...2) {
                                            switch (target.def) {
                                                case EParen(inner):
                                                    target = inner;
                                                    parens++;
                                                default:
                                            }
                                        }
                                        var hit = false;
                                        switch (target.def) {
                                            case ESigil(type, content, mods) if (type == "H"):
                                                var usesRawCall = (content != null) && (content.indexOf("Phoenix.HTML.raw(content)") != -1 || content.indexOf("Phoenix.HTML.raw(@content)") != -1);
                                                var usesVarDirect = (content != null) && (content.indexOf("<%= content %>") != -1 || content.indexOf("<%= @content %>") != -1);
                                                if (usesRawCall || usesVarDirect) hit = true;
                                            default:
                                        }
                                        if (hit) { foundIdx = j; break; }
                                        j++;
                                    }
                                    if (foundIdx != -1) {
                                        // Emit statements up to i-1 already; now skip s (the literal assignment) and emit rebuilt ~H
                                        var rebuilt = makeAST(ESigil("H", lit, ""));
                                        var wrapped: ElixirAST = rebuilt;
                                        var pc = 0;
                                        while (pc < parens) { wrapped = makeAST(EParen(wrapped)); pc++; }
                                        out.push(makeASTWithMeta(wrapped.def, stmts[foundIdx].metadata, stmts[foundIdx].pos));
                                        // Advance i beyond foundIdx
                                        i = foundIdx + 1;
                                        inlined = true;
                                    }
                                }
                                if (!inlined) { out.push(s); i++; }
                            }
                            makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(out))), n.metadata, n.pos);
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
