package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HygieneConsolidatedTransforms
 *
 * WHAT
 * - A consolidation pass that orchestrates core hygiene steps in a single, ordered sweep:
 *   1) Underscore unused def/defp parameters safely (no body rewrites)
 *   2) Fallback rename references to underscored locals when only underscored decl exists
 *   3) Promote used _var → var when safe (declaration-side underscoring removed if referenced)
 *   4) Align references and declarations to a canonical local spelling
 *   5) Case arm binder hygiene: underscore unused binders then promote _name → name by use
 *
 * WHY
 * - Multiple late/ultra-final hygiene passes were overlapping and order-sensitive. Consolidating
 *   common steps into a single pass improves predictability and reduces redundant traversals.
 *
 * HOW
 * - Sequentially applies existing focused transforms in a curated order to the AST, returning
 *   the result of each stage to the next. This pass does not introduce new rename logic; it
 *   delegates to proven shape-based transforms.
 *
 * LIMITATIONS
 * - Does not remove existing hygiene passes yet; it complements them. Once stable, redundant
 *   passes can be disabled in the registry.
 */
class HygieneConsolidatedTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        var r = ast;
        // 1) def/defp params underscore for unused
        r = DefParamUnusedUnderscoreSafeTransforms.pass(r);
        // 1.1) def/defp params: promote underscored binders when the trimmed
        // name is actually referenced in the body (prevents _id-after-use warnings)
        r = DefParamUnderscorePromoteTransforms.promotePass(r);
        // 2) fallback rename refs name -> _name when only underscored variant declared
        r = LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass(r);
        // 3) remove underscore from used locals
        r = UnderscoreVarTransforms.removeUnderscoreFromUsedLocalsPass(r);
        // 4) align declarations and references to canonical names
        r = RefDeclAlignmentTransforms.alignLocalsPass(r);
        // 5) case arm hygiene
        r = ClauseUnusedBinderUnderscoreTransforms.clauseUnusedBinderUnderscorePass(r);
        r = CaseUnderscoreBinderPromoteByUseTransforms.transformPass(r);
        return r;
    }
}

#end
