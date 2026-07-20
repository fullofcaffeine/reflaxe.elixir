package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

typedef MissingPassDependency = {
	var name:String;
	var relation:String;
	var users:Array<String>;
}

typedef PassOrderingViolation = {
	var passName:String;
	var passIndex:Int;
	var dependencyName:String;
	var dependencyIndex:Int;
	var relation:String;
}

typedef PassPhaseRegression = {
	var previousPassName:String;
	var previousPhase:String;
	var passName:String;
	var phase:String;
}

typedef InvalidPassPhase = {
	var passName:String;
	var phase:String;
}

typedef RegistryDiagnostics = {
	var duplicateNames:Array<String>;
	var missingDependencies:Array<MissingPassDependency>;
	var cycleNodes:Array<String>;
	var orderingViolations:Array<PassOrderingViolation>;
	var phaseRegressions:Array<PassPhaseRegression>;
	var invalidPhases:Array<InvalidPassPhase>;
}

typedef RegistryValidationOptions = {
	/** Check that the supplied list already satisfies every present ordering edge. */
	@:optional var requireEffectiveOrder:Bool;

	/** Ordered phase IDs. When supplied, missing, unknown, or backward phases fail. */
	@:optional var phaseOrder:Array<String>;
}

private typedef PassConstraint = {
	var dependencyName:String;
	var relation:String;
}

/**
	Shared fail-closed contracts for pass registration and effective scheduling.

	For example, if `NormalizeCalls` says it runs after `BuildCalls`, misspelling that target used to
	make the edge disappear. The compiler could then run the passes in the wrong order. This checker
	rejects the registry before either pass runs and names the invalid relationship.

	A pass constraint is not merely a hint: a hard target must exist, every present edge must be
	acyclic, and the effective list must honor it. Optional edges are spelled separately so a typo
	in a hard pass ID cannot silently change compiler behavior.
 */
class RegistryCore {
	public static inline var RUN_AFTER = "runAfter";
	public static inline var RUN_BEFORE = "runBefore";
	public static inline var RUN_AFTER_IF_PRESENT = "runAfterIfPresent";
	public static inline var RUN_BEFORE_IF_PRESENT = "runBeforeIfPresent";

	static var lastDiagnostics:RegistryDiagnostics = emptyDiagnostics();

	public static function diagnostics():RegistryDiagnostics {
		return copyDiagnostics(lastDiagnostics);
	}

	/** Inspect a candidate list without throwing or changing the last compiler diagnostics. */
	public static function analyze(passes:Array<ElixirASTTransformer.PassConfig>, ?options:RegistryValidationOptions):RegistryDiagnostics {
		var duplicateNames = collectDuplicateNames(passes);
		var names = collectNames(passes);
		var missingDependencies = collectMissingDependencies(passes, names);
		var graph = buildGraph(passes, names);
		var cycleNodes = findCycleNodes(graph);
		var orderingViolations:Array<PassOrderingViolation> = [];
		if (options != null && options.requireEffectiveOrder == true)
			orderingViolations = collectOrderingViolations(passes, names);

		var phaseRegressions:Array<PassPhaseRegression> = [];
		var invalidPhases:Array<InvalidPassPhase> = [];
		if (options != null && options.phaseOrder != null)
			collectPhaseDiagnostics(passes, options.phaseOrder, phaseRegressions, invalidPhases);

		return {
			duplicateNames: duplicateNames,
			missingDependencies: missingDependencies,
			cycleNodes: cycleNodes,
			orderingViolations: orderingViolations,
			phaseRegressions: phaseRegressions,
			invalidPhases: invalidPhases
		};
	}

	/** Validate without deduplicating, reordering, or otherwise repairing the supplied list. */
	public static function validate(passes:Array<ElixirASTTransformer.PassConfig>, ?options:RegistryValidationOptions):Array<ElixirASTTransformer.PassConfig> {
		var diagnostics = analyze(passes, options);
		lastDiagnostics = copyDiagnostics(diagnostics);
		if (hasErrors(diagnostics))
			throw formatDiagnostics(diagnostics);
		return passes;
	}

	static function collectDuplicateNames(passes:Array<ElixirASTTransformer.PassConfig>):Array<String> {
		var seen = new Map<String, Bool>();
		var duplicates = new Map<String, Bool>();
		for (pass in passes) {
			if (seen.exists(pass.name))
				duplicates.set(pass.name, true);
			else
				seen.set(pass.name, true);
		}
		var result = [for (name in duplicates.keys()) name];
		result.sort(Reflect.compare);
		return result;
	}

	static function collectNames(passes:Array<ElixirASTTransformer.PassConfig>):Map<String, Bool> {
		var names = new Map<String, Bool>();
		for (pass in passes)
			names.set(pass.name, true);
		return names;
	}

	static function collectMissingDependencies(passes:Array<ElixirASTTransformer.PassConfig>, names:Map<String, Bool>):Array<MissingPassDependency> {
		var missing = new Map<String, MissingPassDependency>();
		for (pass in passes) {
			for (constraint in constraints(pass)) {
				if (isOptional(constraint.relation) || names.exists(constraint.dependencyName))
					continue;
				var key = constraint.relation + "\u0000" + constraint.dependencyName;
				var entry = missing.get(key);
				if (entry == null) {
					entry = {
						name: constraint.dependencyName,
						relation: constraint.relation,
						users: []
					};
					missing.set(key, entry);
				}
				entry.users.push(pass.name);
			}
		}

		var result = [for (entry in missing) entry];
		for (entry in result)
			entry.users.sort(Reflect.compare);
		result.sort(function(left, right) {
			var relationOrder = Reflect.compare(left.relation, right.relation);
			return relationOrder == 0 ? Reflect.compare(left.name, right.name) : relationOrder;
		});
		return result;
	}

	static function buildGraph(passes:Array<ElixirASTTransformer.PassConfig>, names:Map<String, Bool>):Map<String, Array<String>> {
		var graph = new Map<String, Array<String>>();
		for (pass in passes)
			if (!graph.exists(pass.name))
				graph.set(pass.name, []);

		for (pass in passes) {
			for (constraint in constraints(pass)) {
				if (!names.exists(constraint.dependencyName))
					continue;
				if (dependencyRunsFirst(constraint.relation))
					addEdge(graph, constraint.dependencyName, pass.name);
				else
					addEdge(graph, pass.name, constraint.dependencyName);
			}
		}
		return graph;
	}

	static function addEdge(graph:Map<String, Array<String>>, from:String, to:String):Void {
		var targets = graph.get(from);
		if (targets.indexOf(to) < 0) {
			targets.push(to);
			targets.sort(Reflect.compare);
		}
	}

	static function findCycleNodes(graph:Map<String, Array<String>>):Array<String> {
		var state = new Map<String, Int>();
		var stack:Array<String> = [];
		var cycleNames = new Map<String, Bool>();

		function visit(name:String):Void {
			state.set(name, 1);
			stack.push(name);
			for (target in graph.get(name)) {
				var targetState = state.exists(target) ? state.get(target) : 0;
				if (targetState == 0) {
					visit(target);
				} else if (targetState == 1) {
					var cycleStart = stack.indexOf(target);
					for (index in cycleStart...stack.length)
						cycleNames.set(stack[index], true);
				}
			}
			stack.pop();
			state.set(name, 2);
		}

		var names = [for (name in graph.keys()) name];
		names.sort(Reflect.compare);
		for (name in names)
			if (!state.exists(name))
				visit(name);

		var result = [for (name in cycleNames.keys()) name];
		result.sort(Reflect.compare);
		return result;
	}

	static function collectOrderingViolations(passes:Array<ElixirASTTransformer.PassConfig>, names:Map<String, Bool>):Array<PassOrderingViolation> {
		var indexes = new Map<String, Int>();
		for (index in 0...passes.length)
			if (!indexes.exists(passes[index].name))
				indexes.set(passes[index].name, index + 1);

		var result:Array<PassOrderingViolation> = [];
		for (pass in passes) {
			var passIndex = indexes.get(pass.name);
			for (constraint in constraints(pass)) {
				if (!names.exists(constraint.dependencyName))
					continue;
				var dependencyIndex = indexes.get(constraint.dependencyName);
				var satisfied = dependencyRunsFirst(constraint.relation) ? dependencyIndex < passIndex : passIndex < dependencyIndex;
				if (!satisfied)
					result.push({
						passName: pass.name,
						passIndex: passIndex,
						dependencyName: constraint.dependencyName,
						dependencyIndex: dependencyIndex,
						relation: constraint.relation
					});
			}
		}
		result.sort(function(left, right) {
			var passOrder = left.passIndex - right.passIndex;
			if (passOrder != 0)
				return passOrder;
			var relationOrder = Reflect.compare(left.relation, right.relation);
			return relationOrder == 0 ? Reflect.compare(left.dependencyName, right.dependencyName) : relationOrder;
		});
		return result;
	}

	static function collectPhaseDiagnostics(passes:Array<ElixirASTTransformer.PassConfig>, phaseOrder:Array<String>, regressions:Array<PassPhaseRegression>,
			invalid:Array<InvalidPassPhase>):Void {
		var ranks = new Map<String, Int>();
		for (index in 0...phaseOrder.length)
			ranks.set(phaseOrder[index], index);

		var previousPass:Null<ElixirASTTransformer.PassConfig> = null;
		var previousRank = -1;
		for (pass in passes) {
			var phase = pass.phase == null ? "<missing>" : pass.phase;
			if (!ranks.exists(phase)) {
				invalid.push({passName: pass.name, phase: phase});
				continue;
			}

			var rank = ranks.get(phase);
			if (previousPass != null && rank < previousRank)
				regressions.push({
					previousPassName: previousPass.name,
					previousPhase: previousPass.phase,
					passName: pass.name,
					phase: phase
				});
			previousPass = pass;
			previousRank = rank;
		}
	}

	static function constraints(pass:ElixirASTTransformer.PassConfig):Array<PassConstraint> {
		var result:Array<PassConstraint> = [];
		appendConstraints(result, pass.runAfter, RUN_AFTER);
		appendConstraints(result, pass.runBefore, RUN_BEFORE);
		appendConstraints(result, pass.runAfterIfPresent, RUN_AFTER_IF_PRESENT);
		appendConstraints(result, pass.runBeforeIfPresent, RUN_BEFORE_IF_PRESENT);
		return result;
	}

	static function appendConstraints(target:Array<PassConstraint>, dependencies:Null<Array<String>>, relation:String):Void {
		if (dependencies == null)
			return;
		for (dependencyName in dependencies)
			target.push({dependencyName: dependencyName, relation: relation});
	}

	static function isOptional(relation:String):Bool {
		return relation == RUN_AFTER_IF_PRESENT || relation == RUN_BEFORE_IF_PRESENT;
	}

	static function dependencyRunsFirst(relation:String):Bool {
		return relation == RUN_AFTER || relation == RUN_AFTER_IF_PRESENT;
	}

	static function hasErrors(diagnostics:RegistryDiagnostics):Bool {
		return diagnostics.duplicateNames.length > 0
			|| diagnostics.missingDependencies.length > 0
			|| diagnostics.cycleNodes.length > 0
			|| diagnostics.orderingViolations.length > 0
			|| diagnostics.phaseRegressions.length > 0
			|| diagnostics.invalidPhases.length > 0;
	}

	static function formatDiagnostics(diagnostics:RegistryDiagnostics):String {
		var lines = ["Pass registry validation failed; no passes were scheduled:"];
		if (diagnostics.duplicateNames.length > 0)
			lines.push("- duplicate pass IDs: " + diagnostics.duplicateNames.join(", "));
		for (missing in diagnostics.missingDependencies)
			lines.push('- missing hard ${missing.relation} target ${missing.name}, referenced by ${missing.users.join(", ")}');
		if (diagnostics.cycleNodes.length > 0)
			lines.push("- ordering cycle contains: " + diagnostics.cycleNodes.join(", "));
		for (violation in diagnostics.orderingViolations)
			lines.push('- ${violation.passName} at ${violation.passIndex} declares ${violation.relation} ${violation.dependencyName} at ${violation.dependencyIndex}');
		for (regression in diagnostics.phaseRegressions)
			lines.push('- phase regressed from ${regression.previousPassName} (${regression.previousPhase}) to ${regression.passName} (${regression.phase})');
		for (invalid in diagnostics.invalidPhases)
			lines.push('- ${invalid.passName} has missing or unknown phase ${invalid.phase}');
		return lines.join("\n");
	}

	static function emptyDiagnostics():RegistryDiagnostics {
		return {
			duplicateNames: [],
			missingDependencies: [],
			cycleNodes: [],
			orderingViolations: [],
			phaseRegressions: [],
			invalidPhases: []
		};
	}

	static function copyDiagnostics(source:RegistryDiagnostics):RegistryDiagnostics {
		return {
			duplicateNames: source.duplicateNames.copy(),
			missingDependencies: [
				for (entry in source.missingDependencies)
					{name: entry.name, relation: entry.relation, users: entry.users.copy()}
			],
			cycleNodes: source.cycleNodes.copy(),
			orderingViolations: [
				for (entry in source.orderingViolations)
					{
						passName: entry.passName,
						passIndex: entry.passIndex,
						dependencyName: entry.dependencyName,
						dependencyIndex: entry.dependencyIndex,
						relation: entry.relation
					}
			],
			phaseRegressions: [
				for (entry in source.phaseRegressions)
					{
						previousPassName: entry.previousPassName,
						previousPhase: entry.previousPhase,
						passName: entry.passName,
						phase: entry.phase
					}
			],
			invalidPhases: [
				for (entry in source.invalidPhases)
					{passName: entry.passName, phase: entry.phase}
			]
		};
	}
}
#end
