package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.PassPrecondition;

/**
 * The structural facts of one module tree that pass preconditions read.
 *
 * WHAT
 * - Records which `ElixirASTDef` constructors occur in the tree, which call
 *   names occur, which `Module.fn` calls occur, and which variable and binder
 *   names occur (from `EVar` and from `PVar`/`PAlias` in every pattern position).
 * - `satisfies` answers whether a `PassPrecondition` holds for the scanned tree.
 *
 * WHY
 * - The runner uses the answer to skip a pass that cannot change the module.
 *   One scan replaces many full-tree walks by passes that would find nothing.
 *
 * HOW
 * - `scan` walks the tree once with `ASTUtils.walk`, the same traversal engine
 *   that `ElixirASTTransformer.transformNode` uses. A pass built on that engine
 *   therefore sees no node that the scan does not see.
 * - The scan describes exactly one tree object. The runner skips a pass only on
 *   a scan of the current tree object: after a pass returns a different tree, it
 *   scans again before the next skip. An older scan is used only when it says the
 *   fact is present, which only makes the pass run. So a fact added by any pass is
 *   seen before the next skip, whether or not that pass declares anything.
 * - The scan reads only `def` values. It does not read metadata, `ERaw` text, or
 *   the compilation context, so a precondition cannot depend on them.
 *
 * EXAMPLE
 * - For `def show(conn), do: Phoenix.Controller.json(conn, %{})`, the scan holds
 *   `EDef`, `ERemoteCall`, `EVar`, `EMap`, the call name `json`, and the call
 *   `Phoenix.Controller.json`. `CallTo("Phoenix.Controller", "json")` holds;
 *   `HasNode("EStructUpdate")` does not.
 */
class PassFeatureScan {
	static var knownConstructorIndexes:Null<Map<String, Int>> = null;

	final kinds:Array<Bool>;
	final callNames:Map<String, Bool>;
	final moduleCalls:Map<String, Map<String, Bool>>;
	final names:Map<String, Bool>;

	function new() {
		kinds = [];
		callNames = new Map();
		moduleCalls = new Map();
		names = new Map();
	}

	/**
	 * Returns the facts of `ast`, read in one preorder walk.
	 *
	 * The result describes this tree object only. Scan again after a pass returns
	 * a different tree.
	 */
	public static function scan(ast:ElixirAST):PassFeatureScan {
		var features = new PassFeatureScan();
		ASTUtils.walk(ast, node -> features.record(node));
		return features;
	}

	/**
	 * Returns true when `precondition` holds for the scanned tree.
	 *
	 * A true answer means the pass must run. A false answer means the declared
	 * fact is absent, so the pass cannot change this tree and may be skipped.
	 */
	public function satisfies(precondition:PassPrecondition):Bool {
		return switch (precondition) {
			case HasNode(constructorName): var index = constructorIndex(constructorName); index < kinds.length && kinds[index] == true;
			case CallTo(module, fn): var calls = moduleCalls.get(module); calls != null && calls.exists(fn);
			case CallNamed(fn):
				callNames.exists(fn);
			case HasName(feature):
				hasName(feature);
			case AnyOf(conditions):
				var any = false;
				for (condition in conditions)
					if (satisfies(condition)) {
						any = true;
						break;
					}
				any;
			case AllOf(conditions):
				var all = true;
				for (condition in conditions)
					if (!satisfies(condition)) {
						all = false;
						break;
					}
				all;
		};
	}

	/**
	 * Fails with a clear message when a precondition names an unknown AST constructor
	 * or an empty name, so a misspelled declaration cannot silently skip a pass.
	 */
	public static function validate(passName:String, precondition:PassPrecondition):Void {
		switch (precondition) {
			case HasNode(constructorName):
				if (!constructorIndexes().exists(constructorName))
					throw 'Pass precondition for $passName names unknown ElixirASTDef constructor "$constructorName"';
			case CallTo(module, fn):
				if (module == null || module.length == 0 || fn == null || fn.length == 0)
					throw 'Pass precondition for $passName has an empty CallTo module or function';
			case CallNamed(fn):
				if (fn == null || fn.length == 0)
					throw 'Pass precondition for $passName has an empty CallNamed function';
			case HasName(Exactly(text) | StartsWith(text)):
				if (text == null || text.length == 0)
					throw 'Pass precondition for $passName has an empty name';
			case HasName(UnderscoredBinder | HasUppercase | EndsWithDigit):
			case AnyOf(conditions) | AllOf(conditions):
				if (conditions == null || conditions.length == 0)
					throw 'Pass precondition for $passName has an empty condition list';
				for (condition in conditions)
					validate(passName, condition);
		}
	}

	function record(node:ElixirAST):Void {
		var def = node.def;
		var index = Type.enumIndex(def);
		while (kinds.length <= index)
			kinds.push(false);
		kinds[index] = true;
		switch (def) {
			case ERemoteCall(module, fn, _):
				callNames.set(fn, true);
				recordModuleCall(module, fn);
			case ECall(target, fn, _):
				callNames.set(fn, true);
				if (target != null)
					recordModuleCall(target, fn);
			case EVar(name):
				recordName(name);
			// Every constructor that carries a pattern. A new pattern position must be
			// added here; TestPassPreconditions builds one of each and checks the names.
			case EDef(_, args, _, _) | EDefp(_, args, _, _) | EDefmacro(_, args, _, _) | EDefmacrop(_, args, _, _):
				recordPatterns(args);
			case EMatch(pattern, _):
				recordPattern(pattern);
			case ECase(_, clauses) | EReceive(clauses, _):
				for (clause in clauses)
					recordPattern(clause.pattern);
			case EWith(clauses, _, _):
				for (clause in clauses)
					recordPattern(clause.pattern);
			case ETry(_, rescueClauses, catchClauses, _, _):
				for (clause in rescueClauses) {
					recordPattern(clause.pattern);
					recordName(clause.varName);
				}
				for (clause in catchClauses)
					recordPattern(clause.pattern);
			case EFor(generators, _, _, _, _):
				for (generator in generators)
					recordPattern(generator.pattern);
			case EFn(clauses):
				for (clause in clauses)
					recordPatterns(clause.args);
			default:
		}
	}

	function recordPatterns(patterns:Null<Array<EPattern>>):Void {
		if (patterns != null)
			for (pattern in patterns)
				recordPattern(pattern);
	}

	/**
	 * Records the binder names of one pattern and of every nested pattern.
	 *
	 * The switch has no default branch, so adding an `EPattern` constructor fails to
	 * compile here until its binders are handled. AST values inside patterns
	 * (`PLiteral`, map keys, binary sizes) are visited by the main walk.
	 */
	function recordPattern(pattern:Null<EPattern>):Void {
		if (pattern == null)
			return;
		switch (pattern) {
			case PVar(name):
				recordName(name);
			case PAlias(name, inner):
				recordName(name);
				recordPattern(inner);
			case PTuple(elements) | PList(elements):
				recordPatterns(elements);
			case PCons(head, tail):
				recordPattern(head);
				recordPattern(tail);
			case PMap(pairs):
				for (pair in pairs)
					recordPattern(pair.value);
			case PStruct(_, fields):
				for (field in fields)
					recordPattern(field.value);
			case PPin(inner):
				recordPattern(inner);
			case PBinary(segments):
				for (segment in segments)
					recordPattern(segment.pattern);
			case PLiteral(_) | PWildcard:
		}
	}

	function recordName(name:Null<String>):Void {
		if (name != null)
			names.set(name, true);
	}

	function hasName(feature:PassNameFeature):Bool {
		return switch (feature) {
			case Exactly(name):
				names.exists(name);
			case StartsWith(prefix):
				var found = false;
				for (name in names.keys())
					if (StringTools.startsWith(name, prefix)) {
						found = true;
						break;
					}
				found;
			case UnderscoredBinder:
				var found = false;
				for (name in names.keys())
					if (name.length > 1 && name.charCodeAt(0) == "_".code) {
						found = true;
						break;
					}
				found;
			case HasUppercase:
				var found = false;
				for (name in names.keys())
					if (hasCapitalLetter(name)) {
						found = true;
						break;
					}
				found;
			case EndsWithDigit:
				var found = false;
				for (name in names.keys()) {
					var last = name.length > 0 ? name.charCodeAt(name.length - 1) : null;
					if (last != null && last >= "0".code && last <= "9".code) {
						found = true;
						break;
					}
				}
				found;
		};
	}

	static function hasCapitalLetter(name:String):Bool {
		for (index in 0...name.length) {
			var code = name.charCodeAt(index);
			if (code != null && code >= "A".code && code <= "Z".code)
				return true;
		}
		return false;
	}

	function recordModuleCall(module:ElixirAST, fn:String):Void {
		if (module == null || module.def == null)
			return;
		var moduleName = switch (module.def) {
			case EVar(name) | EAlias(name, _): name;
			default: null;
		};
		if (moduleName == null)
			return;
		var calls = moduleCalls.get(moduleName);
		if (calls == null) {
			calls = new Map();
			moduleCalls.set(moduleName, calls);
		}
		calls.set(fn, true);
	}

	static function constructorIndex(constructorName:String):Int {
		var index:Null<Int> = constructorIndexes().get(constructorName);
		return switch (index) {
			case null: throw 'Unknown ElixirASTDef constructor in pass precondition: $constructorName';
			case known: known;
		};
	}

	static function constructorIndexes():Map<String, Int> {
		var known = knownConstructorIndexes;
		if (known != null)
			return known;
		var indexes = new Map<String, Int>();
		var names = Type.getEnumConstructs(ElixirASTDef);
		for (i in 0...names.length)
			indexes.set(names[i], i);
		knownConstructorIndexes = indexes;
		return indexes;
	}
}
#end
