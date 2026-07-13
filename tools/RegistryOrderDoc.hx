package tools;

import haxe.io.Path;
import reflaxe.elixir.ast.transformers.registry.PassIntrospection;
import reflaxe.elixir.ast.transformers.registry.PassInventory;
import reflaxe.elixir.ast.transformers.registry.PassScopeManifest;
import reflaxe.elixir.ast.transformers.registry.RegistryCore.RegistryDiagnostics;

using StringTools;

typedef PassBaselineContract = {
	var effectivePassCount:Int;
	var maxRecordsPerModule:Int;
}

class RegistryOrderDoc {
	static inline var OUT_LEAN = "docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md";
	static inline var OUT_GRANULAR = "docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md";
	static inline var OUT_INVENTORY = "docs/05-architecture/PASS_REGISTRY_INVENTORY.md";

	#if macro
	/** Run as a compiler macro so registry function references are typed in macro context. */
	public static function generate():haxe.macro.Expr {
		run();
		return macro null;
	}
	#end

	/** Generate deterministic pass-order and inventory documentation from typed registry data. */
	static function run():Void {
		var passes = PassIntrospection.list();
		var diagnostics = PassIntrospection.diagnostics();
		#if hxx_granular_pass_registry
		validateBaselineContract(passes.length);
		validateRegistryContract(passes, diagnostics);
		writeOrCheck(OUT_GRANULAR, renderOrderDoc("granular (`-D hxx_granular_pass_registry`)", passes));
		writeOrCheck(OUT_INVENTORY, renderInventory(passes, diagnostics));
		#else
		writeOrCheck(OUT_LEAN, renderOrderDoc("lean (default)", passes));
		#end
	}

	static function renderOrderDoc(mode:String, passes:Array<PassInfo>):String {
		var out = new StringBuf();
		out.add("# Transform Pass Registry Order\n\n");
		out.add("Generated from the validated registry by `tools/RegistryOrderDoc.hx`; do not edit manually.\n\n");
		out.add("Mode: " + mode + "\n\n");
		out.add("Effective pass count: **" + passes.length + "**\n\n");
		out.add("| # | Pass | Phase | Scope | Family | Ordering | Description |\n");
		out.add("|---:|---|---|---|---|---|---|\n");
		for (pass in passes) {
			out.add("| " + pass.index + " | `" + escape(pass.name) + "` | `" + escape(pass.phase) + "` | `" + escape(pass.scope) + "` | `"
				+ escape(pass.family) + "` | " + escape(ordering(pass)) + " | " + escape(pass.description) + " |\n");
		}
		return out.toString();
	}

	static function renderInventory(passes:Array<PassInfo>, diagnostics:RegistryDiagnostics):String {
		var out = new StringBuf();
		out.add("# Elixir AST Pass Registry Inventory\n\n");
		out.add("Generated from the validated granular registry by `tools/RegistryOrderDoc.hx`; do not edit manually.\n\n");
		out.add("Scope labels are executable semantic ownership. `PassScopeManifest` maps exact stable pass IDs to scopes, while `PassApplicability` derives module capabilities only from typed annotation metadata and structured ElixirAST. The verification-only `-D reflaxe_elixir_disable_pass_scopes` switch restores legacy all-pass execution for byte-parity checks.\n\n");
		out.add("- Effective granular passes per transformed module: **" + passes.length + "**\n");
		out.add("- Full deterministic order: [TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md](TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md)\n");
		out.add("- Rebuild: `npm run docs:passes`\n");
		out.add("- Drift guard: `npm run guard:pass-inventory`\n");
		out.add("- Scoped/legacy byte parity: `npm run test:pass-scope-parity`\n");
		out.add("- Representative timing/count baseline: `npm run profile:passes:baseline`\n");
		out.add("- Checked-in reference data: [PASS_REGISTRY_BASELINE.json](PASS_REGISTRY_BASELINE.json)\n\n");

		out.add("## Phase Contracts\n\n");
		out.add("| Phase | Input invariant | Output invariant | Known downstream dependency | Representative tests |\n");
		out.add("|---|---|---|---|---|\n");
		for (phase in PassInventory.phaseContracts()) {
			out.add("| `" + escape(phase.id) + "` " + escape(phase.title) + " | " + escape(phase.inputInvariant) + " | " + escape(phase.outputInvariant)
				+ " | " + escape(phase.downstreamDependency) + " | " + escape(phase.representativeTests.join(", ")) + " |\n");
		}

		out.add("\n## Scope Ownership\n\n");
		out.add("| Scope | Applicability predicate | Representative tests |\n");
		out.add("|---|---|---|\n");
		for (scope in PassInventory.scopeContracts()) {
			out.add("| `" + escape(scope.id) + "` " + escape(scope.title) + " | " + escape(scope.applicability) + " | "
				+ escape(scope.representativeTests.join(", ")) + " |\n");
		}

		out.add("\n## Effective Families\n\n");
		out.add("A family is the intersection of a phase contract and semantic ownership scope. Each effective pass is assigned exactly one family in the granular order document.\n\n");
		var familyCounts = new Map<String, Int>();
		for (pass in passes)
			familyCounts.set(pass.family, familyCounts.exists(pass.family) ? familyCounts.get(pass.family) + 1 : 1);
		var families = [for (family in familyCounts.keys()) family];
		families.sort(Reflect.compare);
		out.add("| Family | Effective passes |\n|---|---:|\n");
		for (family in families)
			out.add("| `" + escape(family) + "` | " + familyCounts.get(family) + " |\n");

		out.add("\n## Replay And Repair Families\n\n");
		out.add("These are naming-related candidates for later consolidation, not proof that a pass is redundant. Replays remain required until shape and idempotence tests prove otherwise.\n\n");
		var replayGroups = new Map<String, Array<String>>();
		for (pass in passes) {
			if (pass.replayFamily == null)
				continue;
			var names = replayGroups.exists(pass.replayFamily) ? replayGroups.get(pass.replayFamily) : [];
			names.push(pass.name);
			replayGroups.set(pass.replayFamily, names);
		}
		var replayNames = [for (name in replayGroups.keys()) name];
		replayNames.sort(Reflect.compare);
		out.add("| Canonical family | Effective registrations |\n|---|---|\n");
		for (name in replayNames)
			out.add("| `" + escape(name) + "` | " + escape(replayGroups.get(name).join(", ")) + " |\n");

		out.add("\n## Registry Diagnostics\n\n");
		out.add("`RegistryCore` validates registrations before execution and still deduplicates defensively. The inventory guard requires zero duplicate registrations and zero ordering cycles.\n\n");
		var uniqueDuplicates = new Map<String, Bool>();
		for (name in diagnostics.duplicateNames)
			uniqueDuplicates.set(name, true);
		var duplicateNames = [for (name in uniqueDuplicates.keys()) name];
		duplicateNames.sort(Reflect.compare);
		out.add("- Duplicate registrations removed: **"
			+ diagnostics.duplicateNames.length
			+ "** across **"
			+ duplicateNames.length
			+ "** names");
		if (duplicateNames.length > 0)
			out.add(" (`" + escape(duplicateNames.join("`, `")) + "`)");
		out.add("\n");
		out.add("- Missing ordering dependencies: **" + diagnostics.missingDependencies.length + "**\n");
		out.add("- Detected ordering cycle nodes: **" + diagnostics.cycleNodes.length + "**\n");
		if (diagnostics.missingDependencies.length > 0) {
			out.add("\n| Missing dependency | Referenced by |\n|---|---|\n");
			for (entry in diagnostics.missingDependencies)
				out.add("| `" + escape(entry.name) + "` | " + escape(entry.users.join(", ")) + " |\n");
		}
		return out.toString();
	}

	static function ordering(pass:PassInfo):String {
		var parts:Array<String> = [];
		if (pass.runAfter != null && pass.runAfter.length > 0)
			parts.push("after: " + pass.runAfter.join(", "));
		if (pass.runBefore != null && pass.runBefore.length > 0)
			parts.push("before: " + pass.runBefore.join(", "));
		return parts.length == 0 ? "source order" : parts.join("; ");
	}

	static function escape(value:String):String {
		if (value == null)
			return "";
		return value.replace("|", "\\|").replace("\r", " ").replace("\n", " ").trim();
	}

	static function writeOrCheck(path:String, content:String):Void {
		#if registry_order_check
		if (!sys.FileSystem.exists(path) || sys.io.File.getContent(path) != content)
			throw 'Generated pass inventory drifted: $path (run npm run docs:passes)';
		Sys.println('[registry-doc] OK: ' + path);
		#else
		var directory = Path.directory(path);
		if (!sys.FileSystem.exists(directory))
			sys.FileSystem.createDirectory(directory);
		sys.io.File.saveContent(path, content);
		Sys.println('[registry-doc] Wrote ' + path);
		#end
	}

	static function validateBaselineContract(effectivePassCount:Int):Void {
		var baselinePath = "docs/05-architecture/PASS_REGISTRY_BASELINE.json";
		if (!sys.FileSystem.exists(baselinePath))
			throw "Missing pass baseline contract: " + baselinePath;
		var baseline:PassBaselineContract = haxe.Json.parse(sys.io.File.getContent(baselinePath));
		if (baseline.effectivePassCount != effectivePassCount)
			throw 'Effective pass count changed from ${baseline.effectivePassCount} to $effectivePassCount; review the registry and update the baseline explicitly.';
		if (baseline.maxRecordsPerModule != effectivePassCount + 1)
			throw 'Pass baseline maxRecordsPerModule must equal effectivePassCount + one summary record.';
	}

	static function validateRegistryContract(passes:Array<PassInfo>, diagnostics:RegistryDiagnostics):Void {
		if (diagnostics.duplicateNames.length > 0)
			throw 'Pass registry contains ${diagnostics.duplicateNames.length} duplicate registrations; remove later same-name entries.';
		if (diagnostics.cycleNodes.length > 0)
			throw 'Pass registry contains ordering cycles: ${diagnostics.cycleNodes.join(", ")}';

		var effectiveNames = new Map<String, Bool>();
		for (pass in passes)
			effectiveNames.set(pass.name, true);
		var missingScopedPasses:Array<String> = [];
		for (passName in PassScopeManifest.declarations().keys())
			if (!effectiveNames.exists(passName))
				missingScopedPasses.push(passName);
		missingScopedPasses.sort(Reflect.compare);
		if (missingScopedPasses.length > 0)
			throw 'Pass scope manifest references missing registry IDs: ${missingScopedPasses.join(", ")}';
	}
}
