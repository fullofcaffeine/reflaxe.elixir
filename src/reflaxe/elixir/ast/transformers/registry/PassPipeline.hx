package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer.PassConfig;
import reflaxe.elixir.ast.PassApplicability.PassScope;

/** Stable contributor-facing description of one pass group. */
typedef PassGroupContract = {
	var name:String;
	var phase:String;
	var description:String;
}

/**
 * A readable pipeline group whose children are still ordinary executable passes.
 *
 * WHAT
 * - Keeps the seven established compiler phases visible as named groups.
 * - Stores the granular `PassConfig` children that belong to each phase.
 *
 * WHY
 * - The former bundle was itself an executable pass. It privately ran many child
 *   passes, so outer diagnostics such as the result invariant could report only
 *   the bundle name after a child exposed a problem.
 * - A transparent group is only scheduling structure. The main runner receives
 *   every child and can attribute timing, snapshots, and invariant changes to the
 *   exact pass that caused them.
 *
 * EXAMPLE
 * - `BundleBootstrap` remains the familiar documentation heading.
 * - Its 18 children execute directly through `ElixirASTTransformer`, rather than
 *   through a second loop hidden inside a bundle function.
 */
typedef PassPipelineGroup = {
	var name:String;
	var phase:String;
	var description:String;
	var scope:PassScope;
	var children:Array<PassConfig>;
}

/** Builds and flattens the seven transparent pass groups without changing child order. */
class PassPipeline {
	/**
	 * The stable group vocabulary. Historical `Bundle*` IDs are retained so existing
	 * diagnostics, documentation links, and disable specifications keep working.
	 */
	public static function contracts():Array<PassGroupContract> {
		return [
			{
				name: "BundleBootstrap",
				phase: "bootstrap",
				description: "Early normalization and binder alignment"
			},
			{
				name: "BundlePhoenixAnnotations",
				phase: "framework-annotations",
				description: "Phoenix, Ecto, LiveView, OTP, ExUnit, and Mix annotation lowering"
			},
			{
				name: "BundleGuardsAndInterpolation",
				phase: "guards-interpolation",
				description: "Case and guard normalization plus interpolation preparation"
			},
			{
				name: "BundleCoreTransforms",
				phase: "core-lowering",
				description: "Core idiom, control-flow, collection, and runtime lowering"
			},
			{
				name: "BundleHeexPipeline",
				phase: "hxx-heex",
				description: "Typed HXX and HEEx lowering"
			},
			{
				name: "BundleHygieneFinal",
				phase: "final-hygiene",
				description: "Late binder, temporary, result, and warning hygiene"
			},
			{
				name: "BundleAbsoluteFinal",
				phase: "absolute-final",
				description: "Absolute-final validation and narrowly scoped cleanup"
			}
		];
	}

	/**
	 * Partition an already validated granular schedule by its frozen phase labels.
	 * Unknown or missing phases fail immediately; silently falling back to an opaque
	 * or flat schedule would hide registry drift from contributors.
	 */
	public static function build(passes:Array<PassConfig>):Array<PassPipelineGroup> {
		if (passes == null)
			throw "Pass pipeline cannot group a null pass list";

		var groups:Array<PassPipelineGroup> = [];
		var byPhase = new Map<String, PassPipelineGroup>();
		for (contract in contracts()) {
			var group:PassPipelineGroup = {
				name: contract.name,
				phase: contract.phase,
				description: contract.description,
				scope: PassScope.Mixed,
				children: []
			};
			groups.push(group);
			byPhase.set(group.phase, group);
		}

		for (pass in passes) {
			var phase = pass.phase;
			if (phase == null || phase.length == 0 || !byPhase.exists(phase))
				throw 'Pass ${pass.name} cannot enter the transparent pipeline because phase ${phase == null ? "<missing>" : phase} has no group';

			var group = byPhase.get(phase);
			pass.group = group.name;
			group.children.push(pass);
		}

		return groups;
	}

	/** Return every child in group order without wrapping or copying executable passes. */
	public static function flatten(groups:Array<PassPipelineGroup>):Array<PassConfig> {
		if (groups == null)
			throw "Pass pipeline cannot flatten a null group list";

		var passes:Array<PassConfig> = [];
		for (group in groups)
			for (child in group.children)
				passes.push(child);
		return passes;
	}
}
#end
