package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.PassFeatureScan;
import reflaxe.elixir.ast.PassPrecondition;

/**
 * Audited preconditions that let the runner skip passes that cannot apply.
 *
 * WHAT
 * - Maps exact stable pass IDs to a `PassPrecondition`: a structural fact the
 *   module must contain before the pass can change it.
 *
 * WHY
 * - Most passes leave most modules unchanged but still walk the whole tree. A
 *   declared precondition lets `ElixirASTTransformer` skip the walk when the fact
 *   is absent. See `docs/03-compiler-development/LEAN_PASS_PIPELINE.md`.
 *
 * HOW
 * - `apply()` writes the precondition onto each validated pass config. Unlisted
 *   passes have none and always run.
 * - `declarations()` validates each condition (`PassFeatureScan.validate`), and
 *   `RegistryOrderDoc` rejects IDs that no longer resolve to an effective pass.
 * - Each entry says which match arm needs the fact. Only declare a pass after
 *   reading every arm that can return a different node, and only when the pass
 *   reads nothing but the tree and writes nothing but its result.
 * - Prove each new entry with `-D reflaxe_elixir_verify_pass_preconditions` over
 *   the snapshot suite (the test Makefile enables it by default).
 *
 * EXAMPLE
 * - `WebJsonSecondArgRewrite_Ultimate` changes only
 *   `Phoenix.Controller.json(conn, data|json)`, so it declares
 *   `CallTo("Phoenix.Controller", "json")`.
 */
class PassPreconditionManifest {
	/** Writes the declared precondition onto every pass config whose ID is listed. */
	public static function apply(passes:Array<ElixirASTTransformer.PassConfig>):Void {
		var preconditions = declarations();
		for (pass in passes) {
			var precondition = preconditions.get(pass.name);
			if (precondition != null)
				pass.precondition = precondition;
		}
	}

	/** Returns the validated declarations keyed by exact pass ID. */
	public static function declarations():Map<String, PassPrecondition> {
		var preconditions = new Map<String, PassPrecondition>();
		var underscoredBinder = HasName(UnderscoredBinder);
		var underscorePrefix = HasName(StartsWith("_"));
		var numericSuffix = HasName(EndsWithDigit);

		// Phoenix controller and LiveView call rewrites: each rewrites one exact call shape.
		// Rewrites `Phoenix.Controller.json(conn, data | json)`.
		declare(preconditions, "WebJsonSecondArgRewrite_Ultimate", AllOf([
			CallTo("Phoenix.Controller", "json"),
			AnyOf([HasName(Exactly("data")), HasName(Exactly("json"))])
		]));
		// Rewrites `json(conn, data)` inside a `case` arm.
		declare(preconditions, "ControllerJsonDataArgToBinder_Final", AllOf([HasNode("ECase"), CallNamed("json"), HasName(Exactly("data"))]));
		// Renames a `{_, _binder}` case binder.
		declare(preconditions, "ControllerCaseRenameBinderIfBodyRefsBase_Final", AllOf([HasNode("ECase"), underscorePrefix]));
		// Drops `socket = Phoenix.LiveView.put_flash(socket, ...)`.
		declare(preconditions, "SocketPutFlashAssignDrop_Final", AllOf([CallTo("Phoenix.LiveView", "put_flash"), HasName(Exactly("socket"))]));
		// Inlines `_ = Map.get(map, "key")` into later camelCase references.
		declare(preconditions, "UndefinedRefInlineDiscardedMapGet_Final", AllOf([CallTo("Map", "get"), HasName(Exactly("_"))]));
		// Rewrites `.high`/`.low` on the result of `FPHelper.double_to_i64`.
		declare(preconditions, "FPHelperDoubleToI64FieldAccessRewrite",
			AllOf([AnyOf([CallNamed("double_to_i64"), CallNamed("doubleToI64")]), HasNode("EField")]));
		// Rewrites `set`/`remove`/`clear` on `root` and fluent methods on `struct`.
		declare(preconditions, "StructUpdateTransform", AnyOf([HasName(Exactly("root")), HasName(Exactly("struct"))]));
		// Collapses `\"` inside `~H` content.
		declare(preconditions, "HeexCollapseOverEscapedQuotes_Final", HasNode("ESigil"));

		// Binder hygiene: each pass renames or drops only binders with the named shape.
		// Names ending in a digit (`value2`), renamed to their base.
		declare(preconditions, "NumericSuffixVarNormalize", numericSuffix);
		declare(preconditions, "DropUnusedSimpleAliasToUnderscore", numericSuffix);
		// Names starting with `_` or ending in a digit, aligned with their base.
		declare(preconditions, "LocalVarReferenceFix", AnyOf([underscorePrefix, numericSuffix]));
		declare(preconditions, "RefDeclAlignment", AnyOf([underscorePrefix, numericSuffix]));
		// Promotes or repairs `_name` binders (longer than `_`).
		for (passName in [
			"FinalUnderscoreRepair",
			"LocalUnderscoreUsedPromotion",
			"LocalUnderscoreUsedPromotion_Final",
			"LocalUnderscoreGenericPromotion",
			"LocalUnderscoreGenericPromotion_UltraFinal",
			"UnderscoreLocalPromotion",
			"LocalUnderscoreBinderPromotionWhenUsed_Final",
			"LocalUnderscoreReferenceFallback",
			"LocalUnderscoreBinderPromote",
			"DropUnusedPureUnderscoreAssign_AbsoluteFinal"
		])
			declare(preconditions, passName, underscoredBinder);
		// Renames a `_name` payload binder in a `case` clause.
		for (passName in [
			"UnderscoreBinderAlignByBodyUse_Final",
			"CaseSuccessVarUnifier",
			"CaseSuccessVarUnifier_Replay_Final",
			"SuccessVarAbsoluteReplaceUndefined",
			"SuccessVarAbsoluteReplaceUndefined_Replay_Final"
		])
			declare(preconditions, passName, AllOf([HasNode("ECase"), underscoredBinder]));
		// Renames an unused `{:ok, binder}` payload when the binder is `_`, `_x`, `g`, or `gN`.
		for (passName in [
			"SuccessBinderAlignByBodyUse",
			"SuccessBinderAlignByBodyUse_Final",
			"SuccessBinderAlignByBodyUse_Replay_Final"
		])
			declare(preconditions, passName, AllOf([HasNode("ECase"), AnyOf([underscorePrefix, HasName(StartsWith("g"))])]));
		// Underscores unused `g` and `this*` locals.
		declare(preconditions, "UnusedLocalAssignUnderscoreFinal", AnyOf([HasName(Exactly("g")), HasName(StartsWith("this"))]));
		// Promotes `_name` binders, or drops `x = []` before an empty-list `reduce_while`.
		declare(preconditions, "UnderscorePromoteByUse_Late", AnyOf([underscorePrefix, AllOf([CallNamed("reduce_while"), HasNode("EList")])]));
		// Renames camelCase locals, including a lone camelCase identifier inside `ERaw`.
		declare(preconditions, "LocalVarNameNormalize", AnyOf([HasName(HasUppercase), HasNode("ERaw")]));
		// `{:error, x}` arms whose body uses `reason` (as a variable or inside `"#{reason}"`).
		declare(preconditions, "ResultErrorBinderLateNormalization", AllOf([HasNode("ECase"), AnyOf([HasName(Exactly("reason")), HasNode("EString")])]));
		declare(preconditions, "ErrorReasonAliasInjection", AllOf([HasNode("ECase"), AnyOf([HasName(Exactly("reason")), HasNode("EString")])]));
		// camelCase names renamed to snake_case.
		for (passName in [
			"VarNameNormalization",
			"LocalCamelToSnakeDecl",
			"LocalCamelToSnakeDecl_AfterEventBridge",
			"LocalCamelToSnakeDecl_Final"
		])
			declare(preconditions, passName, HasName(HasUppercase));
		// `ok_value` -> `value` and `_g` -> `g`, also inside `ERaw` text.
		for (passName in [
			"OkValueGlobalCleanup_AbsoluteLast",
			"OkValueGlobalCleanup_AbsoluteFinal",
			"OkValueGlobalCleanup_Replay_Ultimate"
		])
			declare(preconditions, passName, AnyOf([HasName(Exactly("ok_value")), HasName(Exactly("_g")), HasNode("ERaw")]));
		// References aligned with a statement-level `_name = ...` match.
		declare(preconditions, "AlignBaseRefToUnderscoredBinder_Final", AllOf([HasNode("EBinary"), underscoredBinder]));
		// Ecto query variable renames, or rewrites anchored on a canonical `query` variable.
		declare(preconditions, "EctoQueryVarConsistency", AnyOf([
			underscorePrefix,
			HasName(Exactly("query")),
			HasNode("ERaw"),
			CallTo("Ecto.Queryable", "to_query"),
			CallTo("Ecto.Query", "from")
		]));
		// `fn` bodies that compare `.id` with `==`/`!=`.
		declare(preconditions, "ListUpdateAndFilterFix", AllOf([HasNode("EFn"), HasNode("EField"), HasNode("EBinary")]));
		// `Enum.join` over a list built by an earlier `Enum.each`.
		declare(preconditions, "JoinArgBlockScopedFix", AllOf([CallTo("Enum", "join"), CallTo("Enum", "each")]));
		// `v.to_iso8601()` where `v = DateTime.utc_now()`.
		declare(preconditions, "DateTimeMethodRewrite", AllOf([CallTo("DateTime", "utc_now"), CallNamed("to_iso8601")]));

		// HEEx: each pass reads or adds template structure only when a template exists.
		// Converts string returns of functions that take `assigns` to `~H`.
		declare(preconditions, "HeexStringReturnToSigil", AnyOf([HasName(Exactly("assigns")), HasName(Exactly("_assigns"))]));
		// Underscores unused `:let` binders inside `~H`/`~h` content.
		declare(preconditions, "HeexLetUnusedBinderUnderscore", HasNode("ESigil"));
		// Adds `use Phoenix.Component` when `~H` appears in a sigil or in `ERaw` text.
		declare(preconditions, "PhoenixComponentImport", AnyOf([HasNode("ESigil"), HasNode("ERaw")]));
		// Adds or removes the CoreComponents import based on `<.component>` uses in `~H`.
		declare(preconditions, "LiveViewCoreComponentsImport", HasNode("ESigil"));
		return preconditions;
	}

	static function declare(preconditions:Map<String, PassPrecondition>, passName:String, precondition:PassPrecondition):Void {
		if (preconditions.exists(passName))
			throw 'Pass precondition declared more than once: $passName';
		PassFeatureScan.validate(passName, precondition);
		preconditions.set(passName, precondition);
	}
}
#end
