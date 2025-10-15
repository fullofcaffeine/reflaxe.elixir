package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexRawUsageValidatorTransforms
 *
 * WHAT
 * - Scans ~H sigils (and ERaw ~H blocks) for Phoenix.HTML.raw(content|@content)
 *   after inlining passes. Emits compile-time warnings to prevent lingering raw usage.
 *
 * WHY
 * - Using Phoenix.HTML.raw(content) in ~H is a smell and often originates from
 *   constructing big string blocks. We want proper ~H content without raw calls.
 *
 * HOW
 * - Stateless scan over ESigil("H", content) and ERaw(code) containing ~H.
 * - Contextual variant uses CompilationContext.warning for proper positioning.
 */
class HeexRawUsageValidatorTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return validate(ast, null);
    }

    public static function contextualPass(ast: ElixirAST, ctx: reflaxe.elixir.CompilationContext): ElixirAST {
        return validate(ast, ctx);
    }

    static function validate(ast: ElixirAST, ctx: Null<reflaxe.elixir.CompilationContext>): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, _) if (type == "H"):
                    if (content.indexOf("Phoenix.HTML.raw(") != -1) {
                        if (ctx != null) ctx.warning('HEEx contains Phoenix.HTML.raw(...) — prefer inline ~H content', n.pos);
                    }
                    n;
                case ERaw(code) if (code.indexOf("~H\"") != -1 || code.indexOf("~H\"\"\"") != -1):
                    if (code.indexOf("Phoenix.HTML.raw(") != -1) {
                        if (ctx != null) ctx.warning('ERaw ~H contains Phoenix.HTML.raw(...) — prefer inline ~H content', n.pos);
                    }
                    n;
                default:
                    n;
            }
        });
    }
}

#end
