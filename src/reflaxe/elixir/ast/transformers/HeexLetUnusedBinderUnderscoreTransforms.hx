package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexLetUnusedBinderUnderscoreTransforms
 *
 * WHAT
 * - Automatically prefixes unused HEEx `:let` binders with `_` inside `~H` sigils.
 *
 * WHY
 * - In Phoenix, `:let` introduces a pattern binder (e.g. `:let={f}`) which becomes a real
 *   variable in the generated anonymous function. If the bound variable is unused inside
 *   the slot body, Elixir emits an "unused variable" warning.
 * - HXX authoring should not require manual underscore prefixes in templates; the compiler
 *   can determine unused binders and keep the generated Elixir warning-free.
 *
 * HOW
 * - For each `~H` sigil string, parse a lightweight HEEx fragment tree via `HeexFragmentBuilder`.
 * - For any fragment whose attributes include a `:let={var}` binder:
 *   - Scan the subtree for references to `var`, honoring nested `:let` shadowing.
 *   - If unused, rewrite the binder to `_{var}` in the `~H` string using attribute span
 *     metadata captured by the HEEx parser.
 * - Refresh `metadata.heexAST` after rewriting so downstream linters see the updated binder.
 *
 * EXAMPLES
 * HXX (input):
 *   <.form :let={f} for={@changeset}><span>OK</span></.form>
 * Elixir (output):
 *   ~H"""<.form :let={_f} for={@changeset}><span>OK</span></.form>"""
 */
class HeexLetUnusedBinderUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H" || type == "h"):
                    rewriteSigil(n, type, content, modifiers);
                default:
                    n;
            };
        });
    }

    static function rewriteSigil(original: ElixirAST, sigilType: String, content: String, modifiers: String): ElixirAST {
        if (content == null || content.length == 0) return original;

        var nodes: Array<ElixirAST> = null;
        try nodes = reflaxe.elixir.ast.builders.HeexFragmentBuilder.build(content) catch (_:Dynamic) nodes = null;
        if (nodes == null || nodes.length == 0) return original;

        var edits: Array<{ start: Int, end: Int, replacement: String }> = [];
        for (node in nodes) collectEditsFromNode(node, edits);
        if (edits.length == 0) return original;

        edits.sort(function(a, b): Int return b.start - a.start);

        var nextContent = content;
        for (e in edits) {
            if (e == null) continue;
            if (e.start < 0 || e.end < e.start || e.end > nextContent.length) continue;
            nextContent = nextContent.substr(0, e.start) + e.replacement + nextContent.substr(e.end);
        }
        if (nextContent == content) return original;

        var nextMeta = original.metadata;
        if (nextMeta != null) {
            nextMeta.heexAST = reflaxe.elixir.ast.builders.HeexAnalysisASTBuilder.build(nextContent);
        }

        return makeASTWithMeta(ESigil(sigilType, nextContent, modifiers), nextMeta, original.pos);
    }

    static function collectEditsFromNode(node: ElixirAST, edits: Array<{ start: Int, end: Int, replacement: String }>): Void {
        if (node == null || node.def == null) return;

        switch (node.def) {
            case EFragment(_tag, attributes, children):
                maybeAddLetBinderEdit(attributes, children, edits);
                if (children != null) for (c in children) collectEditsFromNode(c, edits);
            default:
        }
    }

    static function maybeAddLetBinderEdit(attributes: Array<EAttribute>, children: Array<ElixirAST>, edits: Array<{ start: Int, end: Int, replacement: String }>): Void {
        if (attributes == null || attributes.length == 0) return;

        var letAttr: Null<EAttribute> = null;
        for (a in attributes) {
            if (a != null && a.name == ":let") {
                letAttr = a;
                break;
            }
        }
        if (letAttr == null || letAttr.value == null) return;

        var varName: Null<String> = switch (letAttr.value.def) {
            case EVar(name):
                name;
            default:
                null;
        };
        if (varName == null || varName.length == 0) return;
        if (varName == "_" || varName.charAt(0) == "_") return;

        if (children != null && isVarUsedInHeexNodes(varName, children)) return;

        var spanStart = letAttr.value.metadata != null ? letAttr.value.metadata.heexAttrValueSpanStart : null;
        var spanEnd = letAttr.value.metadata != null ? letAttr.value.metadata.heexAttrValueSpanEnd : null;
        if (spanStart == null || spanEnd == null) return;
        if (spanStart < 0 || spanEnd <= spanStart) return;

        // Narrow the span to the actual variable token (trim whitespace).
        var start = spanStart;
        var end = spanEnd;

        // We can't access the sigil content directly from here, so rely on the parser guarantee:
        // for `:let={var}`, the attribute expression is exactly the var name (possibly with whitespace).
        edits.push({
            start: start,
            end: end,
            replacement: "_" + varName
        });
    }

    static function isVarUsedInHeexNodes(varName: String, nodes: Array<ElixirAST>): Bool {
        if (varName == null || varName.length == 0) return false;
        if (nodes == null) return false;

        for (n in nodes) {
            if (n == null || n.def == null) continue;
            if (isVarUsedInHeexNode(varName, n)) return true;
        }
        return false;
    }

    static function isVarUsedInHeexNode(varName: String, node: ElixirAST): Bool {
        if (node == null || node.def == null) return false;

        return switch (node.def) {
            case EFragment(_tag, attributes, children):
                // Shadowing: if this fragment binds the same var via :let, the outer var is out of scope.
                if (bindsLetVarName(attributes, varName)) {
                    false;
                } else {
                    if (attributes != null) {
                        for (a in attributes) {
                            if (a == null || a.value == null) continue;
                            if (a.name == ":let") continue;
                            if (exprContainsVar(varName, a.value)) return true;
                        }
                    }
                    if (children != null) {
                        for (c in children) if (isVarUsedInHeexNode(varName, c)) return true;
                    }
                    false;
                }
            default:
                exprContainsVar(varName, node);
        };
    }

    static function bindsLetVarName(attributes: Array<EAttribute>, varName: String): Bool {
        if (attributes == null || attributes.length == 0) return false;
        for (a in attributes) {
            if (a == null || a.name != ":let" || a.value == null) continue;
            switch (a.value.def) {
                case EVar(name) if (name == varName):
                    return true;
                default:
            }
        }
        return false;
    }

    static function exprContainsVar(varName: String, expr: ElixirAST): Bool {
        if (expr == null || expr.def == null) return false;

        var found = false;

        function walk(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case EVar(name):
                    if (name == varName) found = true;
                case ERaw(code):
                    if (code != null && containsElixirVarToken(code, varName)) found = true;
                case EFragment(_tag, attributes, children):
                    // Do not traverse into fragments here; callers handle scoping.
                default:
                    ElixirASTTransformer.iterateAST(e, walk);
            }
        }

        walk(expr);
        return found;
    }

    static function containsElixirVarToken(code: String, varName: String): Bool {
        if (code == null || varName == null || varName.length == 0) return false;

        var i = 0;
        while (i < code.length) {
            var idx = code.indexOf(varName, i);
            if (idx == -1) return false;

            var before = idx - 1;
            if (before >= 0 && isIdentChar(code.charCodeAt(before))) {
                i = idx + varName.length;
                continue;
            }

            var after = idx + varName.length;
            if (after < code.length && isIdentChar(code.charCodeAt(after))) {
                i = idx + varName.length;
                continue;
            }

            return true;
        }

        return false;
    }

    static inline function isIdentChar(code: Int): Bool {
        return (code >= "A".code && code <= "Z".code)
            || (code >= "a".code && code <= "z".code)
            || (code >= "0".code && code <= "9".code)
            || code == "_".code;
    }
}

#end
