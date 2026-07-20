package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.transformers.registry.PassPipeline.PassPipelineGroup;
import reflaxe.elixir.ast.transformers.registry.RegistryCore.RegistryDiagnostics;

/**
	* PassIntrospection
	*
	* WHAT
	* - Typed, minimal DTO for exposing the effective pass order to tooling
	*   without leaking internal PassConfig or requiring Dynamic.
	*
	* WHY
	* - Tools run this API in Haxe macro context so compiler-only function
	*   references remain valid without parsing registry source text.
	* - The DTO keeps generators independent of executable PassConfig internals
	*   and honors the No-Dynamic policy.
	*
	* HOW
	* - Default documentation maps the seven transparent groups to `PassInfo`.
	* - Granular documentation maps every executable child pass, including hard or
	*   explicitly optional ordering relationships.

	*
	* EXAMPLES
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
typedef PassInfo = {
	var index:Int;
	var name:String;
	var description:String;
	var phase:String;
	var scope:String;
	var family:String;
	@:optional var replayFamily:String;
	@:optional var runAfter:Array<String>;
	@:optional var runBefore:Array<String>;
	@:optional var runAfterIfPresent:Array<String>;
	@:optional var runBeforeIfPresent:Array<String>;
}

class PassIntrospection {
	public static function list():Array<PassInfo> {
		#if hxx_granular_pass_registry
		return listPasses(ElixirASTPassRegistry.getGranularPasses());
		#else
		return listGroups(ElixirASTPassRegistry.getEnabledPassGroups());
		#end
	}

	static function listGroups(groups:Array<PassPipelineGroup>):Array<PassInfo> {
		var out:Array<PassInfo> = [];
		for (index in 0...groups.length) {
			var group = groups[index];
			out.push({
				index: index + 1,
				name: group.name,
				description: group.description + ' (${group.children.length} child passes)',
				phase: group.phase,
				scope: group.scope,
				family: group.phase + "." + group.scope
			});
		}
		return out;
	}

	static function listPasses(enabled:Array<ElixirASTTransformer.PassConfig>):Array<PassInfo> {
		var phases = PassInventory.phaseAssignments(enabled);
		var replayCounts = new Map<String, Int>();
		for (pass in enabled) {
			var canonical = PassInventory.canonicalReplayName(pass.name);
			replayCounts.set(canonical, replayCounts.exists(canonical) ? replayCounts.get(canonical) + 1 : 1);
		}
		var out:Array<PassInfo> = [];
		for (index in 0...enabled.length) {
			var pass = enabled[index];
			var phase = pass.phase != null && pass.phase.length > 0 ? pass.phase : phases[index];
			var scope:String = pass.scope == null ? "core" : pass.scope;
			var replayFamily = PassInventory.canonicalReplayName(pass.name);
			var replayCount = replayCounts.get(replayFamily);
			out.push({
				index: index + 1,
				name: pass.name,
				description: pass.description,
				phase: phase,
				scope: scope,
				family: phase + "." + scope,
				replayFamily: replayCount != null && replayCount > 1 ? replayFamily : null,
				runAfter: pass.runAfter,
				runBefore: pass.runBefore,
				runAfterIfPresent: pass.runAfterIfPresent,
				runBeforeIfPresent: pass.runBeforeIfPresent
			});
		}
		return out;
	}

	public static function diagnostics():RegistryDiagnostics {
		return RegistryCore.diagnostics();
	}
}
#end
