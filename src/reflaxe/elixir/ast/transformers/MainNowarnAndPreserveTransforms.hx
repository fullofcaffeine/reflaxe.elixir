package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MainNowarnAndPreserveTransforms
 *
 * WHAT
 * - Ensures modules that define a private main/0 function are annotated with
 *   @compile {:nowarn_unused_function, [main: 0]} so the helper is preserved
 *   and not pruned by UnusedDefpPrune, keeping warnings-as-errors clean.
 *
 * WHY
 * - Snapshot suites (e.g., ecto/migration_validation) expect a defp main/0
 *   stub that logs a message via Log.trace, and an explicit compile nowarn
 *   entry for main:0. Without the attribute, UnusedDefpPrune removes it.
 *
 * HOW
 * - For EModule/EDefmodule:
 *   1) Detect presence of defp main() with arity 0 in the body.
 *   2) If present, inject or augment a compile attribute containing
 *      {:nowarn_unused_function, [main: 0]}.
 *   3) For EDefmodule, convert into EModule form to place attributes
 *      consistently at the top level (printer emits the same defmodule).
 *
 * EXAMPLES
 * Haxe:
 *   class Main { static function main() trace("..."); }
 * Elixir (after):
 *   defmodule Main do
 *     @compile {:nowarn_unused_function, [main: 0]}
 *     defp main() do
 *       Log.trace("...", ...)
 *     end
 *   end
 */
class MainNowarnAndPreserveTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    if (!hasDefpMainZero(body)) return n;
                    var newAttrs = ensureMainNowarn(attrs);
                    makeASTWithMeta(EModule(name, newAttrs, body), n.metadata, n.pos);

                case EDefmodule(name2, doBlock):
                    // Unwrap do block to scan body
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        case EDo(ss2): ss2;
                        default: [doBlock];
                    };
                    if (!hasDefpMainZero(stmts)) return n;
                    var attrs2 = ensureMainNowarn([]);
                    makeASTWithMeta(EModule(name2, attrs2, stmts), n.metadata, n.pos);

                default:
                    n;
            }
        });
    }

    static function hasDefpMainZero(body: Array<ElixirAST>): Bool {
        for (b in body) switch (b.def) {
            case EDefp(fname, args, _, _):
                if (fname == "main" && (args == null || args.length == 0)) return true;
            default:
        }
        return false;
    }

    static function ensureMainNowarn(attrs: Array<EAttribute>): Array<EAttribute> {
        // Search for an existing @compile {:nowarn_unused_function, ...}
        var idx = -1;
        for (i in 0...attrs.length) {
            var a = attrs[i];
            if (a != null && a.name == "compile") {
                switch (a.value.def) {
                    case ETuple([kind, kws]):
                        switch (kind.def) {
                            case EAtom(atom) if (atom == "nowarn_unused_function"):
                                idx = i;
                            default:
                        }
                    default:
                }
            }
        }

        if (idx >= 0) {
            // Augment existing nowarn list with main: 0 if missing
            var a = attrs[idx];
            var newVal = a.value;
            switch (a.value.def) {
                case ETuple([kind, kws]):
                    switch (kws.def) {
                        case EKeywordList(pairs):
                            var hasMain = false;
                            for (p in pairs) if (p.key == "main") { hasMain = true; break; }
                            if (!hasMain) {
                                var newPairs = pairs.copy();
                                newPairs.push({ key: "main", value: makeAST(EInteger(0)) });
                                newVal = makeAST(ETuple([kind, makeAST(EKeywordList(newPairs))]));
                            }
                        default:
                    }
                default:
            }
            var newAttrs = attrs.copy();
            newAttrs[idx] = { name: "compile", value: newVal };
            return newAttrs;
        } else {
            // Inject new compile nowarn attribute at the top
            var value = makeAST(ETuple([
                makeAST(EAtom("nowarn_unused_function")),
                makeAST(EKeywordList([{ key: "main", value: makeAST(EInteger(0)) }]))
            ]));
            var compileAttr: EAttribute = { name: "compile", value: value };
            var out = attrs.copy();
            out.unshift(compileAttr);
            return out;
        }
    }
}

#end

