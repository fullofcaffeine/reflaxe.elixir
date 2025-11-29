package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IdiomaticEnumReplayTransforms
 *
 * WHAT
 * - Re-applies the idiomatic enum transformation to any tuple that still looks
 *   like an enum constructor (e.g., {:module_ref, "TodoApp.Repo"}).
 *
 * WHY
 * - Some pipelines (fast_boot/minimal passes) may emit raw tuples before the
 *   idiomatic conversion runs, leaving OTP child specs as tagged tuples that
 *   supervisors cannot understand. Replaying the conversion ensures final
 *   output matches OTP expectations (module refs, {mod, args}, {mod, config},
 *   or full specs) without touching generated .ex files.
 *
 * HOW
 * - Walk the AST; for every node, delegate to the shared
 *   applyIdiomaticEnumTransformation utility. It is a no-op for non‑enum
 *   tuples and already-converted shapes, but fixes lingering tagged tuples.
 *
 * EXAMPLES
 *   {:module_ref, "TodoApp.Repo"}       -> TodoApp.Repo
 *   {:module_with_args, "M", [a]}      -> {M, [a]}
 *   {:module_with_config, "M", kw}     -> {M, kw}
 *   {:full_spec, %{id: "M", ...}}      -> %{id: "M", ...}
 */
class IdiomaticEnumReplayTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        inline function otpEnumTag(node: ElixirAST): Null<String> {
            return switch (node.def) {
                case ETuple(elements) if (elements.length > 0):
                    switch (elements[0].def) {
                        case EAtom(name): name;
                        default: null;
                    }
                default: null;
            };
        }

        inline function isOtpSpecTag(tag: String): Bool {
            return tag == "module_ref" || tag == "module_with_args" || tag == "module_with_config" || tag == "full_spec";
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            var tag = otpEnumTag(n);
            if (tag != null && isOtpSpecTag(tag)) {
                return reflaxe.elixir.ast.ElixirAST.applyIdiomaticEnumTransformation(n);
            }
            return n;
        });
    }
}

#end
