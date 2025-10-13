package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
using StringTools;

/**
 * ReduceERawAliasCanonicalizeTransforms
 *
 * WHAT
 * - Canonicalize accumulator and binder aliasing inside ERaw snippets that contain
 *   reduce bodies of the form: `Enum.reduce(..., fn binder, acc -> ... end)`.
 *   Specifically:
 *   - Drop trivial binder alias `alias = binder`
 *   - Rewrite `alias = Enum.concat(alias, list)` → `acc = Enum.concat(acc, list)`
 *   - Substitute occurrences of binder alias within `list` to the binder param
 *
 * WHY
 * - Some pipelines emit reduce bodies as ERaw strings. AST-based passes cannot see inside ERaw,
 *   leaving non-canonical aliasing that triggers warnings-as-errors. This pass performs targeted,
 *   shape-based canonicalization without app-specific heuristics.
 *
 * HOW
 * - Search ERaw for occurrences of `Enum.reduce( ... fn <binder>, <acc> ->` blocks. For each block:
 *   - Identify simple alias lines `<x> = <binder>` and record `<x>` as the binder alias (optional).
 *   - Replace self-append alias rebinds `<y> = Enum.concat(<y>, <list>)` with `acc = Enum.concat(acc, <list>)`.
 *   - If a binder alias was found, replace occurrences of it inside `<list>` with `<binder>`.
 */
class ReduceERawAliasCanonicalizeTransforms {
    static var RE_BLOCK:EReg = ~/Enum\.reduce\([\s\S]*?fn\s+([a-zA-Z_][\w!?]*)\s*,\s*([a-zA-Z_][\w!?]*)\s*->\s*([\s\S]*?)end\)/g;
    static var RE_BINDER_ALIAS:EReg = ~/^\s*([a-zA-Z_][\w!?]*)\s*=\s*([a-zA-Z_][\w!?]*)\s*$/m;
    static var RE_SELF_APPEND:EReg = ~/^\s*([a-zA-Z_][\w!?]*)\s*=\s*Enum\.concat\(\s*\1\s*,\s*([\s\S]*?)\)\s*$/m;

    static function canonicalizeBlock(body:String, binder:String, acc:String): String {
        var out = body;
        // Detect binder alias
        var binderAlias:Null<String> = null;
        var m = RE_BINDER_ALIAS.match(out);
        if (m && RE_BINDER_ALIAS.matched(2) == binder) {
            binderAlias = RE_BINDER_ALIAS.matched(1);
            // Drop the alias line entirely
            out = StringTools.replace(out, RE_BINDER_ALIAS.matched(0) + "\n", "");
        }
        // Rewrite self-append assignments to target acc
        while (RE_SELF_APPEND.match(out)) {
            var full = RE_SELF_APPEND.matched(0);
            var listPart = RE_SELF_APPEND.matched(2);
            if (binderAlias != null) {
                // Replace binder alias references inside list with binder
                listPart = listPart.split(binderAlias).join(binder);
            }
            var repl = acc + " = Enum.concat(" + acc + ", " + listPart + ")";
            out = out.replace(full, repl);
        }
        return out;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERaw(code):
                    var out = code;
                    if (out != null && out.indexOf("Enum.reduce") != -1) {
                        // Process all reduce blocks
                        var cursor = 0;
                        var rebuilt = new StringBuf();
                        while (RE_BLOCK.matchSub(out, cursor)) {
                            var start = RE_BLOCK.matchedPos().pos;
                            var len = RE_BLOCK.matchedPos().len;
                            var before = out.substr(cursor, start - cursor);
                            rebuilt.add(before);
                            var binder = RE_BLOCK.matched(1);
                            var acc = RE_BLOCK.matched(2);
                            var body = RE_BLOCK.matched(3);
                            #if debug_reduce_unify
                            Sys.println('[ReduceERawAliasCanonicalize] found reduce block binder=' + binder + ', acc=' + acc);
                            #end
                            var canon = canonicalizeBlock(body, binder, acc);
                            // Reconstruct reduce block with canonicalized body
                            var block = RE_BLOCK.matched(0);
                            var blockCanon = block.replace(body, canon);
                            rebuilt.add(blockCanon);
                            cursor = start + len;
                        }
                        rebuilt.add(out.substr(cursor));
                        var newCode = rebuilt.toString();
                        if (newCode != out) return makeASTWithMeta(ERaw(newCode), n.metadata, n.pos) else n;
                    }
                    n;
                default:
                    n;
            }
        });
    }
}

#end
