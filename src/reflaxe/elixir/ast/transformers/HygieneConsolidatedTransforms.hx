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
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] DefParamUnusedUnderscoreSafe start'); #else trace('[HygieneTrace] DefParamUnusedUnderscoreSafe start'); #end
        #end
        r = DefParamUnusedUnderscoreSafeTransforms.pass(r);
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] DefParamUnusedUnderscoreSafe end'); #else trace('[HygieneTrace] DefParamUnusedUnderscoreSafe end'); #end
        #end
        // 1.1) def/defp params: promote underscored binders when the trimmed
        // name is actually referenced in the body (prevents _id-after-use warnings)
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] DefParamUnderscorePromote start'); #else trace('[HygieneTrace] DefParamUnderscorePromote start'); #end
        #end
        r = DefParamUnderscorePromoteTransforms.promotePass(r);
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] DefParamUnderscorePromote end'); #else trace('[HygieneTrace] DefParamUnderscorePromote end'); #end
        #end
        // 2) fallback rename refs name -> _name when only underscored variant declared
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] LocalUnderscoreReferenceFallback start'); #else trace('[HygieneTrace] LocalUnderscoreReferenceFallback start'); #end
        #end
        r = LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass(r);
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] LocalUnderscoreReferenceFallback end'); #else trace('[HygieneTrace] LocalUnderscoreReferenceFallback end'); #end
        #end
        // 3) remove underscore from used locals
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] UnderscoreVarRemove start'); #else trace('[HygieneTrace] UnderscoreVarRemove start'); #end
        #end
        r = UnderscoreVarTransforms.removeUnderscoreFromUsedLocalsPass(r);
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] UnderscoreVarRemove end'); #else trace('[HygieneTrace] UnderscoreVarRemove end'); #end
        #end
        // 4) align declarations and references to canonical names
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] RefDeclAlignment start'); #else trace('[HygieneTrace] RefDeclAlignment start'); #end
        #end
        r = RefDeclAlignmentTransforms.alignLocalsPass(r);
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] RefDeclAlignment end'); #else trace('[HygieneTrace] RefDeclAlignment end'); #end
        #end
        // 5) case arm hygiene
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] ClauseUnusedBinderUnderscore start'); #else trace('[HygieneTrace] ClauseUnusedBinderUnderscore start'); #end
        #end
        r = ClauseUnusedBinderUnderscoreTransforms.clauseUnusedBinderUnderscorePass(r);
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] ClauseUnusedBinderUnderscore end'); #else trace('[HygieneTrace] ClauseUnusedBinderUnderscore end'); #end
        #end
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] CaseUnderscoreBinderPromoteByUse start'); #else trace('[HygieneTrace] CaseUnderscoreBinderPromoteByUse start'); #end
        #end
        r = CaseUnderscoreBinderPromoteByUseTransforms.transformPass(r);
        #if hxx_hygiene_trace
        #if sys Sys.println('[HygieneTrace] CaseUnderscoreBinderPromoteByUse end'); #else trace('[HygieneTrace] CaseUnderscoreBinderPromoteByUse end'); #end
        #end
        return r;
    }
}

#end
