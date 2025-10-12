package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceERawTransforms
 *
 * WHAT
 * - Inside Presence modules, rewrite ERaw code that expands Reflect.fields
 *   on Presence maps from:
 *     Map.keys(expr) |> Enum.map(&Atom.to_string/1)
 *   to simply:
 *     Map.keys(expr)
 *
 * WHY
 * - Presence keys are strings; applying Atom.to_string/1 is incorrect. Since
 *   Reflect.fields is implemented via ERaw, we need a string-level normalization
 *   in addition to structural AST passes.
 *
 * HOW
 * - Limit to modules with metadata.isPresence or names matching *Web.Presence.
 * - Process ERaw nodes: scan for Map.keys( ... ) |> Enum.map(&Atom.to_string/1)
 *   with proper parenthesis balance and remove the pipeline segment.
 */
class PresenceERawTransforms {
    static inline function isPresenceModuleName(name: String): Bool {
        if (name == null) return false;
        if (name.indexOf("Web.Presence") >= 0) return true;
        var suffix = ".Presence";
        var len = name.length;
        return len >= suffix.length && name.substr(len - suffix.length) == suffix;
    }

    public static function erawPresenceKeysNormalizePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if ((n.metadata?.isPresence == true) || isPresenceModuleName(name)):
                    var newBody = [];
                    for (b in body) newBody.push(rewriteERaw(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if ((n.metadata?.isPresence == true) || isPresenceModuleName(name)):
                    makeASTWithMeta(EDefmodule(name, rewriteERaw(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteERaw(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case ERaw(code):
                    var normalized = collapsePresenceKeysPipeline(code);
                    if (normalized != code) makeASTWithMeta(ERaw(normalized), x.metadata, x.pos) else x;
                default:
                    x;
            }
        });
    }

    static function collapsePresenceKeysPipeline(code: String): String {
        var out = new StringBuf();
        var i = 0;
        while (i < code.length) {
            var idx = code.indexOf("Map.keys(", i);
            if (idx == -1) { out.add(code.substr(i)); break; }
            // copy prefix up to Map.keys(
            out.add(code.substr(i, idx - i));
            out.add("Map.keys(");
            var j = idx + "Map.keys(".length;
            // parse inner parentheses to the matching ')'
            var depth = 1;
            var inner = new StringBuf();
            while (j < code.length && depth > 0) {
                var ch = code.charAt(j);
                if (ch == '(') depth++; else if (ch == ')') depth--; 
                inner.add(ch);
                j++;
            }
            var innerStr = inner.toString();
            // Now j at position after closing ')'
            // Skip whitespace
            var k = j;
            while (k < code.length) {
                var ws = code.charAt(k);
                if (ws == ' ' || ws == '\\n' || ws == '\\t' || ws == '\\r') k++; else break;
            }
            // If followed by pipeline to Enum.map(&Atom.to_string/1), drop it
            var suffix = code.substr(k, "|> Enum.map(&Atom.to_string/1)".length);
            if (suffix == "|> Enum.map(&Atom.to_string/1)") {
                // emit Map.keys(inner-without-last-char)
                // innerStr currently includes the closing ')'; remove last char which was ')'
                // But we already wrote ")" by appending inner; Adjust accordingly: emit innerStr without final ')'
                // Simpler: we appended "Map.keys(" and innerStr which includes the ')', so keep as-is
                out.add(innerStr);
                // Skip pipeline suffix
                i = k + "|> Enum.map(&Atom.to_string/1)".length;
            } else {
                // Not followed by the exact pipeline; emit inner and continue
                out.add(innerStr);
                i = j;
            }
        }
        return out.toString();
    }
}

#end

