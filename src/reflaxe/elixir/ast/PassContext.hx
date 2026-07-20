package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.PassApplicability.PassScope;

/** What a pass can truthfully say about its effect on the AST. */
enum PassChange {
	/** The pass proved that it changed the AST or analysis-relevant metadata. */
	Changed;

	/** The pass proved that it changed neither the AST nor analysis-relevant metadata. */
	Unchanged;

	/** The legacy pass API cannot prove whether it changed analysis inputs. */
	Unknown;
}

/** Result returned by an outcome-aware pass. */
typedef PassOutcome = {
	final ast:ElixirAST;
	final change:PassChange;
	final preservedAnalyses:Array<String>;
}

/** One request-local diagnostic attributed to the pass that emitted it. */
typedef PassDiagnostic = {
	final passId:String;
	final message:String;
}

/**
 * Deterministic allocator for compiler-owned temporary names.
 *
 * Reserved names are never returned. Allocation starts with the requested base
 * and then tries `_2`, `_3`, and so on. The allocator is deliberately local to a
 * `PassContext`; two concurrent compilation requests cannot consume each other's
 * counters. Callers remain responsible for choosing a valid Elixir identifier.
 */
class PassTempAllocator {
	final used:Map<String, Bool>;
	final nextSuffixByBase:Map<String, Int>;

	public function new(?reserved:Array<String>) {
		used = new Map();
		nextSuffixByBase = new Map();
		if (reserved != null)
			for (name in reserved)
				reserve(name);
	}

	/** Mark an existing structured identifier as unavailable. */
	public function reserve(name:String):Void {
		if (name != null && name.length > 0)
			used.set(name, true);
	}

	/** Allocate the first deterministic, non-reserved name for `base`. */
	public function allocate(base:String):String {
		if (base == null || base.length == 0)
			throw "Temporary name bases must not be empty";

		if (!used.exists(base)) {
			used.set(base, true);
			nextSuffixByBase.set(base, 2);
			return base;
		}

		var suffix = nextSuffixByBase.exists(base) ? nextSuffixByBase.get(base) : 2;
		var candidate = '${base}_$suffix';
		while (used.exists(candidate)) {
			suffix++;
			candidate = '${base}_$suffix';
		}
		used.set(candidate, true);
		nextSuffixByBase.set(base, suffix + 1);
		return candidate;
	}
}

/**
 * Request-local state for one invocation of the AST pass pipeline.
 *
 * WHAT
 * - Tracks the currently executing stable pass ID, phase, scope, AST revision,
 *   diagnostics, lazy analyses, and deterministic temporary-name allocation.
 *
 * WHY
 * - Process-global counters and caches can leak between warm, reordered, or
 *   concurrent compilations. Cached analyses can also become stale after a pass.
 *
 * HOW
 * - `ElixirASTTransformer.transform` creates a fresh instance for every pipeline
 *   invocation and passes it explicitly to outcome-aware pass functions.
 * - Existing AST-only passes are adapted as `Unknown`, so they invalidate all
 *   materialized analyses instead of claiming false preservation.
 * - Future passes may return an explicit `PassOutcome` after proving their result.
 *
 * Existing structured variable and pattern names are reserved lazily, the first
 * time a pass asks for a temporary name at a given AST revision. Pipelines that
 * do not allocate through this context therefore pay no extra tree-walk cost.
 * Opaque raw target text cannot be inspected honestly; an owner that allocates a
 * name around raw text must reserve any additional contract-known names itself.
 */
class PassContext {
	public final rootName:String;
	public final analyses:AnalysisManager;
	public final diagnostics:Array<PassDiagnostic>;

	final temps:PassTempAllocator;
	var tempInventoryRevision:Int;

	public var ast(default, null):ElixirAST;
	public var passId(default, null):String;
	public var phase(default, null):Null<String>;
	public var scope(default, null):Null<PassScope>;
	public var revision(default, null):Int;
	public var lastChange(default, null):PassChange;

	public function new(rootName:String, ast:ElixirAST, validateAnalysisCache:Bool = false) {
		this.rootName = rootName;
		this.ast = ast;
		analyses = new AnalysisManager(ast, validateAnalysisCache);
		temps = new PassTempAllocator();
		diagnostics = [];
		passId = "<pipeline>";
		phase = null;
		scope = null;
		revision = 0;
		lastChange = Unchanged;
		tempInventoryRevision = -1;
	}

	/** Set stable identity before invoking one visible pass boundary. */
	public function beginPass(passId:String, phase:Null<String>, scope:Null<PassScope>):Void {
		if (passId == null || passId.length == 0)
			throw "Pass IDs must not be empty";
		this.passId = passId;
		this.phase = phase;
		this.scope = scope;
	}

	/** Apply one honest outcome to revision and analysis-cache state. */
	public function finish(outcome:PassOutcome):Void {
		if (outcome == null || outcome.ast == null)
			throw 'Pass $passId returned no AST outcome';
		if (outcome.change == null)
			throw 'Pass $passId returned no change classification';

		lastChange = outcome.change;
		switch (outcome.change) {
			case Unchanged:
				analyses.retainRevision(outcome.ast);
			case Changed | Unknown:
				revision++;
				analyses.advanceRevision(outcome.ast, revision, outcome.preservedAnalyses);
		}
		ast = outcome.ast;
	}

	/** Attribute a request-local diagnostic to the current pass. */
	public function addDiagnostic(message:String):Void {
		diagnostics.push({
			passId: passId,
			message: message
		});
	}

	/**
	 * Allocate a deterministic compiler-owned name that cannot collide with a
	 * structured variable or pattern currently present in this request's AST.
	 */
	public function allocateTemp(base:String):String {
		ensureTempInventory();
		return temps.allocate(base);
	}

	/**
	 * Reserve a name known through a contract that structural traversal cannot
	 * discover, such as a binder inside explicitly opaque raw target text.
	 */
	public function reserveTemp(name:String):Void {
		temps.reserve(name);
	}

	/** Adapt the old AST-only pass contract without inventing change precision. */
	public static function legacyOutcome(ast:ElixirAST):PassOutcome {
		return {
			ast: ast,
			change: Unknown,
			preservedAnalyses: []
		};
	}

	function ensureTempInventory():Void {
		if (tempInventoryRevision == revision)
			return;

		reserveStructuredNames(ast);
		tempInventoryRevision = revision;
	}

	function reserveStructuredNames(ast:ElixirAST):Void {
		ASTUtils.walk(ast, node -> {
			switch (node.def) {
				case EVar(name):
					temps.reserve(name);

				case EDef(_, args, _, _) | EDefp(_, args, _, _) | EDefmacro(_, args, _, _) | EDefmacrop(_, args, _, _):
					for (arg in args)
						reservePattern(arg);

				case ECase(_, clauses):
					for (clause in clauses)
						reservePattern(clause.pattern);

				case EMatch(pattern, _):
					reservePattern(pattern);

				case EWith(generators, _, _):
					for (generator in generators)
						reservePattern(generator.pattern);

				case ETry(_, rescueClauses, catchClauses, _, _):
					for (clause in rescueClauses) {
						reservePattern(clause.pattern);
						temps.reserve(clause.varName);
					}
					for (clause in catchClauses)
						reservePattern(clause.pattern);

				case EFor(generators, _, _, _, _):
					for (generator in generators)
						reservePattern(generator.pattern);

				case EFn(clauses):
					for (clause in clauses)
						for (arg in clause.args)
							reservePattern(arg);

				case EReceive(clauses, _):
					for (clause in clauses)
						reservePattern(clause.pattern);

				default:
			}
		});
	}

	function reservePattern(pattern:EPattern):Void {
		ElixirPatternChildren.walk(pattern, _ -> {}, nested -> {
			switch (nested) {
				case PVar(name):
					temps.reserve(name);
				case PAlias(name, _):
					temps.reserve(name);
				default:
			}
		});
	}
}
#end
