package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
/**
 * A lazy analysis definition owned by one compiler request.
 *
 * `dependencies` names analyses whose invalidation also invalidates this result.
 * `equals` is required because a forced fresh computation must compare semantic
 * results without guessing how an arbitrary `T` should be compared.
 */
typedef AnalysisDefinition<T> = {
	final id:String;
	final dependencies:Array<String>;
	final compute:ElixirAST->T;
	final equals:(T, T) -> Bool;
}

private typedef CachedAnalysis = {
	var revision:Int;
	final value:Any;
}

/**
 * Request-local cache for facts derived from `ElixirAST`.
 *
 * WHAT
 * - Computes an analysis only when requested and caches it for one AST revision.
 * - Invalidates dependants transitively when their inputs are no longer valid.
 *
 * WHY
 * - A pass can rewrite the tree after an earlier pass computed a capability,
 *   binding, or result-flow fact. Reusing that stale fact can miscompile code.
 * - Legacy passes cannot yet prove what they preserve, so the safe default is
 *   to invalidate cached facts after a changed or unknown outcome.
 *
 * HOW
 * - `PassContext` advances the revision and calls `advanceRevision`.
 * - Only explicitly preserved analyses whose dependencies are also preserved
 *   survive into the new revision.
 * - Validation mode recomputes a cached read and fails if it differs.
 *
 * This class does not own `PassApplicability` yet. That existing analysis keeps
 * its phase-boundary cadence until a separate differential migration proves that
 * caching it is both correct and within the compiler's performance budget.
 */
class AnalysisManager {
	final cache:Map<String, CachedAnalysis>;
	final dependenciesById:Map<String, Array<String>>;
	final validateCachedReads:Bool;
	var ast:ElixirAST;
	var cachedCount:Int;

	public var revision(default, null):Int;

	public function new(ast:ElixirAST, validateCachedReads:Bool = false) {
		if (ast == null)
			throw "AnalysisManager requires an AST root";

		cache = new Map();
		dependenciesById = new Map();
		this.validateCachedReads = validateCachedReads;
		this.ast = ast;
		revision = 0;
		cachedCount = 0;
	}

	/** Return the cached value for the current AST revision, or compute a fresh value. */
	public function get<T>(definition:AnalysisDefinition<T>, forceRecompute:Bool = false):T {
		var dependencies = registerDefinition(definition.id, definition.dependencies);
		var cached = cache.get(definition.id);

		if (!forceRecompute && cached != null && cached.revision == revision) {
			var cachedValue:T = cast cached.value;
			if (validateCachedReads) {
				var fresh = definition.compute(ast);
				if (!definition.equals(cachedValue, fresh))
					throw 'Analysis ${definition.id} returned stale data at AST revision $revision';
			}
			return cachedValue;
		}

		var value = definition.compute(ast);
		if (cached == null)
			cachedCount++;
		cache.set(definition.id, {
			revision: revision,
			value: value
		});
		dependenciesById.set(definition.id, dependencies);
		return value;
	}

	/** Remove one cached analysis and every cached analysis that depends on it. */
	public function invalidate(id:String):Void {
		invalidateRecursive(id, new Map());
	}

	/**
	 * Move proven-preserved facts to `nextRevision` and invalidate everything else.
	 *
	 * A named analysis is retained only when it and every declared dependency are
	 * present in `preserved`. This keeps preservation conservative even when the
	 * dependency itself was not materialized in the cache.
	 */
	public function advanceRevision(nextAst:ElixirAST, nextRevision:Int, preserved:Array<String>):Void {
		if (nextAst == null)
			throw "AnalysisManager cannot advance to a missing AST root";
		if (nextRevision != revision + 1)
			throw 'AnalysisManager expected AST revision ${revision + 1}, got $nextRevision';

		ast = nextAst;
		revision = nextRevision;
		if (cachedCount == 0)
			return;

		var preservedIds = new Map<String, Bool>();
		if (preserved != null)
			for (id in preserved)
				if (id != null && id.length > 0)
					preservedIds.set(id, true);

		var cachedIds = [for (id in cache.keys()) id];
		for (id in cachedIds)
			if (!canPreserve(id, preservedIds))
				invalidate(id);

		for (id in cache.keys())
			cache.get(id).revision = nextRevision;
	}

	/** Adopt a proven-equivalent root without changing the revision or cache. */
	public function retainRevision(nextAst:ElixirAST):Void {
		if (nextAst == null)
			throw "AnalysisManager cannot retain a missing AST root";
		ast = nextAst;
	}

	/** True only when `id` has a value for the current AST revision. */
	public function isCached(id:String):Bool {
		var entry = cache.get(id);
		return entry != null && entry.revision == revision;
	}

	/** Number of currently materialized analysis results. */
	public function cacheSize():Int {
		return cachedCount;
	}

	function registerDefinition(id:String, dependencies:Array<String>):Array<String> {
		if (id == null || id.length == 0)
			throw "Analysis IDs must not be empty";

		var normalized = normalizeDependencies(id, dependencies);
		var existing = dependenciesById.get(id);
		if (existing != null && existing.join("\u0000") != normalized.join("\u0000"))
			throw 'Analysis $id changed its dependency contract within one compiler request';

		if (existing == null) {
			dependenciesById.set(id, normalized);
			try {
				assertAcyclic(id, new Map(), new Map());
			} catch (error:Dynamic) {
				dependenciesById.remove(id);
				throw error;
			}
		}
		return normalized;
	}

	function normalizeDependencies(id:String, dependencies:Array<String>):Array<String> {
		var unique = new Map<String, Bool>();
		if (dependencies != null)
			for (dependency in dependencies) {
				if (dependency == null || dependency.length == 0)
					throw 'Analysis $id has an empty dependency ID';
				if (dependency == id)
					throw 'Analysis $id cannot depend on itself';
				unique.set(dependency, true);
			}

		var normalized = [for (dependency in unique.keys()) dependency];
		normalized.sort(Reflect.compare);
		return normalized;
	}

	function invalidateRecursive(id:String, visited:Map<String, Bool>):Void {
		if (visited.exists(id))
			return;
		visited.set(id, true);
		if (cache.remove(id))
			cachedCount--;

		var dependants = [];
		for (candidate in dependenciesById.keys()) {
			var dependencies = dependenciesById.get(candidate);
			if (dependencies != null && dependencies.indexOf(id) != -1)
				dependants.push(candidate);
		}
		for (dependant in dependants)
			invalidateRecursive(dependant, visited);
	}

	function assertAcyclic(id:String, visiting:Map<String, Bool>, visited:Map<String, Bool>):Void {
		if (visiting.exists(id))
			throw 'Analysis dependency cycle reaches $id';
		if (visited.exists(id))
			return;

		visiting.set(id, true);
		var dependencies = dependenciesById.get(id);
		if (dependencies != null)
			for (dependency in dependencies)
				if (dependenciesById.exists(dependency))
					assertAcyclic(dependency, visiting, visited);
		visiting.remove(id);
		visited.set(id, true);
	}

	function canPreserve(id:String, preserved:Map<String, Bool>):Bool {
		if (!preserved.exists(id))
			return false;

		var dependencies = dependenciesById.get(id);
		if (dependencies != null)
			for (dependency in dependencies)
				if (!canPreserve(dependency, preserved))
					return false;
		return true;
	}
}
#end
