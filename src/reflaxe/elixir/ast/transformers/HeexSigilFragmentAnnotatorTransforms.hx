package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * HeexSigilFragmentAnnotatorTransforms
 *
 * WHAT
 * - Parses simple ~H string content into lightweight fragment metadata (HeexFragmentMeta)
 *   and attaches it to node.metadata.heexFragments for analysis passes (linters, validators).
 *
 * WHY
 * - Transitional step toward full EFragment AST for attributes; enables structured
 *   checks without re‑emitting code from fragments.
 *
 * HOW
 * - Runs on ESigil("H", content); uses conservative parsing:
 *   • Detects top-level tags: <tag ...> ... </tag>
 *   • Parses attributes as either key="..." or key={...}
 *   • Captures childrenText best-effort (without nested DOM fidelity)
 * - Attaches array of HeexFragmentMeta to metadata.heexFragments; returns node unchanged.
 */
class HeexSigilFragmentAnnotatorTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return annotate(ast);
    }

    static function annotate(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var frags = parseFragments(content);
                    if (frags != null && frags.length > 0) {
                        var meta2 = n.metadata;
                        meta2.heexFragments = frags;
                        makeASTWithMeta(n.def, meta2, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }

    static function parseFragments(s: String): Array<reflaxe.elixir.ast.HeexFragmentMeta> {
        var out: Array<reflaxe.elixir.ast.HeexFragmentMeta> = [];
        var i = 0;
        while (i < s.length) {
            var lt = s.indexOf('<', i);
            if (lt == -1) break;
            // Skip closing tags
            if (lt + 1 < s.length && s.charAt(lt + 1) == '/') { i = lt + 2; continue; }
            // Read tag name
            var j = lt + 1;
            while (j < s.length && ~/^[A-Za-z0-9_\.-]$/.match(s.charAt(j))) j++;
            if (j == lt + 1) { i = lt + 1; continue; }
            var tag = s.substr(lt + 1, j - (lt + 1));
            // Read attributes up to '>'
            var k = j;
            var attrs: Array<reflaxe.elixir.ast.HeexAttributeMeta> = [];
            while (k < s.length && s.charAt(k) != '>' && s.charAt(k) != '/') {
                // Skip whitespace
                while (k < s.length && ~/^\s$/.match(s.charAt(k))) k++;
                // Parse name
                var ns = k;
                while (k < s.length && ~/^[A-Za-z0-9_:\-]$/.match(s.charAt(k))) k++;
                if (k == ns) break;
                var name = s.substr(ns, k - ns);
                // Skip whitespace
                while (k < s.length && ~/^\s$/.match(s.charAt(k))) k++;
                if (k < s.length && s.charAt(k) == '=') {
                    k++;
                    while (k < s.length && ~/^\s$/.match(s.charAt(k))) k++;
                    if (k < s.length && (s.charAt(k) == '"' || s.charAt(k) == '\'')) {
                        var q = s.charAt(k); k++;
                        var valStart = k;
                        while (k < s.length && s.charAt(k) != q) k++;
                        var lit = s.substr(valStart, k - valStart);
                        attrs.push({ name: name, valueExpr: lit, isDynamic: false });
                        if (k < s.length) k++;
                    } else if (k < s.length && s.charAt(k) == '{') {
                        var depth = 1; var valStart2 = k + 1; k++;
                        while (k < s.length && depth > 0) { var ch = s.charAt(k); if (ch == '{') depth++; else if (ch == '}') depth--; k++; }
                        var expr = s.substr(valStart2, (k - 1) - valStart2);
                        attrs.push({ name: name, valueExpr: StringTools.trim(expr), isDynamic: true });
                    }
                }
                // Continue
            }
            // Move to end of tag
            while (k < s.length && s.charAt(k) != '>') k++;
            if (k < s.length && s.charAt(k) == '>') k++;
            // Best-effort: capture children text until next '<'
            var nextLt = s.indexOf('<', k);
            var childrenText = nextLt == -1 ? s.substr(k) : s.substr(k, nextLt - k);
            out.push({ tag: tag, attributes: attrs, childrenText: StringTools.trim(childrenText) });
            i = k;
        }
        return out;
    }
}

#end
