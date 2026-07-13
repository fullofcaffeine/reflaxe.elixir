package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

typedef MissingPassDependency = {
	var name:String;
	var users:Array<String>;
}

typedef RegistryDiagnostics = {
	var duplicateNames:Array<String>;
	var missingDependencies:Array<MissingPassDependency>;
	var cycleNodes:Array<String>;
}

/**
	* RegistryCore
	*
	* WHAT
	* - Shared types and lightweight validators for the AST pass registry.
	*
	* WHY
	* - Keep registry composition maintainable as we modularize into groups while
	*   ensuring correctness (unique names, missing dependencies, cycles).
	*
	* HOW
	* - Provides validation helpers that operate on the existing PassConfig list.
	*   Does not change ordering (no behavior drift) — only validates and returns
	*   the original list.

	*
	* EXAMPLES
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
class RegistryCore {
	static var lastDiagnostics:RegistryDiagnostics = {
		duplicateNames: [],
		missingDependencies: [],
		cycleNodes: []
	};

	public static function diagnostics():RegistryDiagnostics {
		return {
			duplicateNames: lastDiagnostics.duplicateNames.copy(),
			missingDependencies: [
				for (entry in lastDiagnostics.missingDependencies)
					{name: entry.name, users: entry.users.copy()}
			],
			cycleNodes: lastDiagnostics.cycleNodes.copy()
		};
	}

	public static function validate(passes:Array<ElixirASTTransformer.PassConfig>):Array<ElixirASTTransformer.PassConfig> {
		// Unique names (dedupe by first occurrence to avoid double-running a pass)
		var seen = new Map<String, Bool>();
		var duplicateNames:Array<String> = [];
		var deduped:Array<ElixirASTTransformer.PassConfig> = [];
		for (p in passes) {
			if (p == null || p.name == null)
				continue;
			if (seen.exists(p.name)) {
				duplicateNames.push(p.name);
				continue; // drop subsequent occurrences
			}
			seen.set(p.name, true);
			deduped.push(p);
		}
		// Missing dependencies
		var names = new Map<String, Bool>();
		for (p in deduped)
			if (p != null && p.name != null)
				names.set(p.name, true);
		var missingDeps = new Map<String, Array<String>>(); // dep -> [users]
		for (p in deduped)
			if (p != null && p.runAfter != null) {
				for (dep in p.runAfter)
					if (!names.exists(dep)) {
						var users = missingDeps.exists(dep) ? missingDeps.get(dep) : [];
						users.push(p.name);
						missingDeps.set(dep, users);
					}
			}
		// Cycle detection (best-effort):
		var graph = new Map<String, Array<String>>();
		for (p in deduped) {
			if (p == null || p.name == null)
				continue;
			graph.set(p.name, p.runAfter == null ? [] : p.runAfter.copy());
		}
		var visiting = new Map<String, Bool>();
		var visited = new Map<String, Bool>();
		var cycleNodes:Array<String> = [];
		function dfs(n:String, path:Array<String>):Void {
			if (visited.exists(n))
				return;
			if (visiting.exists(n)) {
				if (cycleNodes.indexOf(n) < 0)
					cycleNodes.push(n);
				return;
			}
			visiting.set(n, true);
			var deps = graph.get(n);
			if (deps != null)
				for (d in deps)
					dfs(d, path.concat([n]));
			visiting.remove(n);
			visited.set(n, true);
		}
		for (k in graph.keys())
			dfs(k, []);

		duplicateNames.sort(Reflect.compare);
		cycleNodes.sort(Reflect.compare);
		var missingDependencyList:Array<MissingPassDependency> = [];
		for (dependency in missingDeps.keys()) {
			var users = missingDeps.get(dependency);
			users.sort(Reflect.compare);
			missingDependencyList.push({name: dependency, users: users});
		}
		missingDependencyList.sort(function(left, right) return Reflect.compare(left.name, right.name));
		lastDiagnostics = {
			duplicateNames: duplicateNames,
			missingDependencies: missingDependencyList,
			cycleNodes: cycleNodes
		};

		// Emit compact diagnostics only when explicitly requested
		#if (sys && debug_pass_order)
		if (duplicateNames.length > 0) {
			// DEBUG: Sys.println('[RegistryCore] Duplicate pass names (deduped): ' + duplicateNames.join(', '));
		}
		if (missingDeps.keys().hasNext()) {
			for (dep in missingDeps.keys()) {
				var users = missingDeps.get(dep);
				// DEBUG: Sys.println('[RegistryCore] Missing runAfter dependency: ' + dep + ' (referenced by ' + users.join(', ') + ')');
			}
		}
		#end
		// Return deduped list to prevent duplicate pass side-effects
		return deduped;
	}
}
#end
