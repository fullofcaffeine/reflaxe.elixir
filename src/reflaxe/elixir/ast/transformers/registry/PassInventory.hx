package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

using StringTools;

typedef PassPhaseContract = {
	var id:String;
	var title:String;
	var inputInvariant:String;
	var outputInvariant:String;
	var downstreamDependency:String;
	var representativeTests:Array<String>;
}

typedef PassScopeContract = {
	var id:String;
	var title:String;
	var applicability:String;
	var representativeTests:Array<String>;
}

/**
 * Authoritative phase and ownership vocabulary for registry introspection.
 *
 * This metadata does not gate pass execution. It describes the current global
 * registry so later scoping work can be measured against an output-preserving
 * baseline instead of changing behavior while the inventory is being built.
 */
class PassInventory {
	public static function phaseContracts():Array<PassPhaseContract> {
		return [
			{
				id: "bootstrap",
				title: "Bootstrap normalization",
				inputInvariant: "Builder output after initial receiver-effect lowering.",
				outputInvariant: "Early returns, source binders, inline-expansion artifacts, and local names have stable AST carriers.",
				downstreamDependency: "Framework annotation and core lowering passes consume these normalized binders and expression containers.",
				representativeTests: ["core/basic_syntax", "regression/inline_if_g_variables"]
			},
			{
				id: "framework-annotations",
				title: "Framework annotations",
				inputInvariant: "Module metadata and normalized authored definitions are available.",
				outputInvariant: "Phoenix, LiveView, Ecto, OTP, and ExUnit module/callback scaffolding is represented in ElixirAST.",
				downstreamDependency: "Guard, interpolation, and core passes assume generated callback heads and framework module forms already exist.",
				representativeTests: [
					"phoenix/router",
					"liveview/golden_liveview_fixture",
					"ecto/changeset",
					"exunit/exunit_comprehensive"
				]
			},
			{
				id: "guards-interpolation",
				title: "Guards and interpolation",
				inputInvariant: "Case clauses and framework callbacks have their target-level heads.",
				outputInvariant: "Guard binders, list patterns, complex expression containers, and interpolation bodies are target-valid.",
				downstreamDependency: "Core control-flow and collection lowering relies on valid clause binders and expression-position blocks.",
				representativeTests: ["core/string_interpolation_test", "regression/guard_condition_grouping"]
			},
			{
				id: "core-lowering",
				title: "Core semantic lowering",
				inputInvariant: "Target-valid guards and expression containers are available.",
				outputInvariant: "Imperative state, loops, collections, pattern matches, stdlib calls, and framework call shapes have Elixir carriers.",
				downstreamDependency: "HEEx conversion and late hygiene consume these stable target expressions and receiver/reducer bindings.",
				representativeTests: ["core/basic_syntax", "stdlib/stdlib_externs", "regression/non_void_tail_values"]
			},
			{
				id: "hxx-heex",
				title: "HXX and HEEx lowering",
				inputInvariant: "Core expressions and framework callback signatures are stable.",
				outputInvariant: "Typed HXX content is represented as valid HEEx sigils with assigns, imports, components, and control tags normalized.",
				downstreamDependency: "Late hygiene must preserve sigil contents while repairing only target binders and warning-producing shells.",
				representativeTests: ["phoenix/hxx_inline_markup_basic", "liveview/golden_liveview_fixture"]
			},
			{
				id: "final-hygiene",
				title: "Final hygiene",
				inputInvariant: "Semantic and template lowering is complete.",
				outputInvariant: "Unused binders, temporary aliases, reducer sentinels, and warning-producing assignments are normalized without changing result carriers.",
				downstreamDependency: "Absolute-final repairs assume no new broad semantic lowering will occur.",
				representativeTests: [
					"regression/function_result_invariants",
					"ecto/changeset",
					"liveview/golden_liveview_fixture"
				]
			},
			{
				id: "absolute-final",
				title: "Absolute-final repairs",
				inputInvariant: "Only narrowly scoped late repair and warning suppression remains.",
				outputInvariant: "The pre-print AST is target-valid, warning-clean, and retains every authored non-Void result carrier.",
				downstreamDependency: "The printer is the next stage; it must not repair semantics.",
				representativeTests: [
					"regression/function_result_invariants",
					"phoenix/router",
					"exunit/exunit_comprehensive"
				]
			}
		];
	}

	public static function scopeContracts():Array<PassScopeContract> {
		return [
			{
				id: "core",
				title: "Core language",
				applicability: "Currently invoked for every module; individual transforms gate on ElixirAST shape.",
				representativeTests: ["core/basic_syntax", "regression/non_void_tail_values"]
			},
			{
				id: "stdlib",
				title: "Target stdlib/runtime",
				applicability: "Currently invoked for every module; transforms recognize Haxe stdlib modules, abstract impls, or target runtime call shapes.",
				representativeTests: ["stdlib/stdlib_externs", "test:haxe-exunit-stdlib"]
			},
			{
				id: "phoenix",
				title: "Phoenix and OTP",
				applicability: "Currently invoked for every module; transforms self-gate on Phoenix/OTP annotations, metadata, callback heads, or target call shapes.",
				representativeTests: ["phoenix/router", "otp/otp_supervision"]
			},
			{
				id: "liveview",
				title: "Phoenix LiveView",
				applicability: "Currently invoked for every module; transforms self-gate on LiveView metadata, callbacks, socket shapes, or presence/event AST.",
				representativeTests: ["liveview/golden_liveview_fixture", "phoenix/liveview_basic"]
			},
			{
				id: "ecto",
				title: "Ecto",
				applicability: "Currently invoked for every module; transforms self-gate on Ecto annotations, changeset/query calls, migration mode, or Repo shapes.",
				representativeTests: ["ecto/changeset", "ecto/typed_query_basic"]
			},
			{
				id: "hxx",
				title: "HXX and HEEx",
				applicability: "Currently invoked for every module; transforms self-gate on HEEx sigils, HXX metadata, component calls, or assigns usage.",
				representativeTests: ["phoenix/hxx_inline_markup_basic", "liveview/golden_liveview_fixture"]
			},
			{
				id: "exunit",
				title: "ExUnit",
				applicability: "Currently invoked for every module; transforms self-gate on ExUnit annotations, test definitions, or assertion call shapes.",
				representativeTests: ["exunit/exunit_comprehensive"]
			},
			{
				id: "diagnostics",
				title: "Diagnostics",
				applicability: "Compile-time define gated; production builds retain no diagnostic output.",
				representativeTests: ["test:result-invariant", "guard:pass-inventory"]
			},
			{
				id: "mixed",
				title: "Mixed bundle",
				applicability: "Lean-mode bundle containing multiple granular ownership scopes.",
				representativeTests: ["test:quick"]
			}
		];
	}

	public static function phaseAssignments(passes:Array<ElixirASTTransformer.PassConfig>):Array<String> {
		var phases:Array<String> = [];
		if (passes == null)
			return phases;

		for (pass in passes) {
			phases.push(switch (pass.name) {
				case "BundleBootstrap": "bootstrap";
				case "BundlePhoenixAnnotations": "framework-annotations";
				case "BundleGuardsAndInterpolation": "guards-interpolation";
				case "BundleCoreTransforms": "core-lowering";
				case "BundleHeexPipeline": "hxx-heex";
				case "BundleHygieneFinal": "final-hygiene";
				case "BundleAbsoluteFinal": "absolute-final";
				default: "";
			});
		}

		if (passes.length > 0 && phases[0] != "")
			return phases;

		var annotationsStart = indexOfPass(passes, "PhoenixWebTransform");
		var guardsStart = indexOfPass(passes, "GuardGrouping");
		var coreStart = indexOfPass(passes, "BareCallToUnderscoreAssign");
		var heexStart = indexOfPass(passes, "HeexStringReturnToSigil");
		var hygieneStart = indexOfPass(passes, "AccAliasLateRewrite");
		var absoluteFinalStart = indexOfPass(passes, "EFnTempChainSimplify_AlwaysRun");

		for (index in 0...passes.length) {
			phases[index] = if (annotationsStart >= 0 && index < annotationsStart) {
				"bootstrap";
			} else if (guardsStart >= 0 && index < guardsStart) {
				"framework-annotations";
			} else if (coreStart >= 0 && index < coreStart) {
				"guards-interpolation";
			} else if (heexStart >= 0 && index < heexStart) {
				"core-lowering";
			} else if (hygieneStart >= 0 && index < hygieneStart) {
				"hxx-heex";
			} else if (absoluteFinalStart >= 0 && index < absoluteFinalStart) {
				"final-hygiene";
			} else {
				"absolute-final";
			};
		}
		return phases;
	}

	public static function scopeFor(passName:String):String {
		if (passName == null || passName.length == 0)
			return "core";
		if (passName.startsWith("Bundle"))
			return "mixed";
		if (containsAny(passName, ["Debug", "Diagnostic", "Invariant", "Trace"]))
			return "diagnostics";
		if (containsAny(passName, ["Heex", "HEEx", "HXX", "Hxx", "InlineMarkup", "PhoenixComponent"]))
			return "hxx";
		if (containsAny(passName, ["ExUnit", "Assert", "TestCase"]))
			return "exunit";
		if (containsAny(passName, [
			"Changeset",
			"Ecto",
			"Repo",
			"Schema",
			"Migration",
			"Postgrex",
			"DbTypes",
			"ValidateLength",
			"Queryable",
			"QueryBinder"
		]))
			return "ecto";
		if (containsAny(passName, [
			"LiveView",
			"LiveMount",
			"LiveNoreply",
			"HandleEvent",
			"HandleInfo",
			"Mount",
			"Presence",
			"SocketPutFlash",
			"SocketAssign",
			"LiveSession"
		]))
			return "liveview";
		if (containsAny(passName, [
			"Phoenix",
			"Controller",
			"Web",
			"Endpoint",
			"Router",
			"Channel",
			"Supervisor",
			"Application",
			"Telemetry",
			"PubSub",
			"Gettext"
		]))
			return "phoenix";
		if (containsAny(passName, [
			"StdHaxe",
			"StringTools",
			"StringBuf",
			"FPHelper",
			"DateTime",
			"HaxeMap",
			"HaxeFloat",
			"AbstractImpl",
			"AbstractNilDefault"
		]))
			return "stdlib";
		return "core";
	}

	public static function canonicalReplayName(passName:String):String {
		if (passName == null)
			return "";
		var result = passName;
		var suffixes = [
			"_Replay2_UltraFinal",
			"_Replay_Ultimate",
			"_Replay_AbsoluteLast",
			"_Replay_AbsoluteFinal",
			"_Replay_Final",
			"_Replay_Last",
			"_AbsoluteLastReplay",
			"_AbsoluteFinal_Replay",
			"_AbsoluteLast",
			"_AbsoluteFinal",
			"_UltraFinal",
			"_Ultimate",
			"_PostFinal",
			"_PreFinal",
			"_Final",
			"_Late",
			"_Early",
			"_Post",
			"_Pre",
			"_AlwaysRun"
		];
		var changed = true;
		while (changed) {
			changed = false;
			for (suffix in suffixes) {
				if (result.endsWith(suffix)) {
					result = result.substr(0, result.length - suffix.length);
					changed = true;
					break;
				}
			}
		}
		return result;
	}

	static function indexOfPass(passes:Array<ElixirASTTransformer.PassConfig>, name:String):Int {
		for (index in 0...passes.length)
			if (passes[index].name == name)
				return index;
		return -1;
	}

	static function containsAny(value:String, fragments:Array<String>):Bool {
		for (fragment in fragments)
			if (value.indexOf(fragment) >= 0)
				return true;
		return false;
	}
}
#end
