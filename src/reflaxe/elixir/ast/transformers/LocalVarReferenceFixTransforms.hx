package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.NodeBinders;

/**
 * LocalVarReferenceFixTransforms: points a reference to an unbound name at the one
 * bound local it drifted from.
 *
 * WHAT
 * - Inside each `def`/`defp`, a reference `EVar(name)` whose name no pattern in the
 *   function binds is rewritten to a bound local with a closely related name:
 *   - rule 1: `name` -> `_name` when `_name` is bound;
 *   - rule 2: `name` -> `nameN` when exactly one `nameN` (`name` plus digits) is bound;
 *   - rule 3: `nameN` -> `name` when `name` is bound.
 * - "Bound" means bound by any pattern anywhere in the function: the `def` arguments,
 *   `fn` arguments, `case`/`receive`/`with` clause patterns, comprehension generators,
 *   `rescue`/`catch` patterns, and the left side of `=` (see `NodeBinders`).
 * - Declarations are never changed; only references are.
 *
 * WHY
 * - Older builder and hygiene steps could declare one spelling and read another
 *   (`_changeset` declared, `changeset` read; `query2` declared, `query` read). Elixir
 *   rejects the unbound read, so pointing it at the only candidate repaired the build.
 * - The rules match names by their shape, so they are safe only for a name that is
 *   really unbound. Earlier versions counted only `def` arguments and `=` patterns as
 *   bound. A `fn q -> ... end` argument, a case binder or a catch binder then looked
 *   unbound, and its reads were moved to another variable with a similar name
 *   (`haxe.elixir.codex-hhp5`):
 *
 *       Haxe:   function(q:Int) { { var q = 999; } return q * 2; }
 *       Elixir: fn q -> q1 = 999; q * 2 end
 *       Before: fn q -> q1 = 999; q1 * 2 end   (returns 1998, not 8)
 *       After:  unchanged, because `q` is bound by the `fn`.
 *
 *   Haxe already proved these names are different variables (`q1` is its own rename
 *   of an inner shadow); the shape rule must not merge them again.
 *
 * HOW
 * - One walk collects every bound name of the function (`NodeBinders.forEach` for each
 *   node, plus the variables on the left of `a = b = rhs` chains).
 * - The rules build a rename map whose keys are never bound names, then one transform
 *   rewrites matching `EVar` references. A reference to a bound name is never changed,
 *   so a read that Elixir already resolves keeps its meaning. Only a read that would
 *   fail to compile can change.
 * - Haxe `TVar` ids would decide drift exactly, but references no longer carry
 *   `sourceVarId` metadata when this late pass runs, so the bound-name check is the
 *   structural guard here.
 *
 * EXAMPLES
 * - `_changeset = cast(...); changeset` -> `_changeset = cast(...); _changeset` (rule 1)
 * - `query2 = from(...); Repo.all(query)` -> `...; Repo.all(query2)` (rule 2)
 * - a read of `count2` where only `count` is bound -> a read of `count` (rule 3)
 *
 * LIMITS
 * - Names inside raw code (`ERaw`, such as an interpolated string) are neither counted
 *   as reads nor rewritten.
 * - The bound-name check covers the whole function, not one scope: a name that is
 *   bound anywhere in the function is left alone everywhere in it.
 * - Regression coverage: `test/differential/r18_name_drift_binders`.
 */
class LocalVarReferenceFixTransforms {
	public static function localVarReferenceFixPass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case EDef(name, args, guards, body):
					var newBody = normalizeBody(body, args);
					makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
				case EDefp(name, args, guards, body):
					var newBody = normalizeBody(body, args);
					makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
				default:
					node;
			}
		});
	}

	static function normalizeBody(body:ElixirAST, fnArgs:Array<EPattern>):ElixirAST {
		var declared = collectBoundNames(body, fnArgs);

		// Build a simple, unambiguous rename map
		var rename = new Map<String, String>();

		// Helper to test uniqueness of candidate
		function uniqueCandidate(base:String, candidates:Array<String>):Null<String> {
			return candidates.length == 1 ? candidates[0] : null;
		}

		// Precompute declared lists for matching
		var declaredKeys = [for (k in declared.keys()) k];

		// Rule 1: name -> _name when _name declared and name not declared
		for (k in declaredKeys) {
			if (StringTools.startsWith(k, "_") && k.length > 1) {
				var base = k.substr(1);
				if (!declared.exists(base)) {
					// Map base -> k only if not already mapped
					rename.set(base, k);
				}
			}
		}

		// Rule 2: name -> nameN when nameN declared and name not declared (single numeric suffix)
		// Build index by base name
		var groups = new Map<String, Array<String>>();
		for (k in declaredKeys) {
			// Split trailing digits
			var i = k.length - 1;
			while (i >= 0 && k.charCodeAt(i) >= '0'.code && k.charCodeAt(i) <= '9'.code)
				i--;
			var base = k.substr(0, i + 1);
			var suffix = k.substr(i + 1);
			if (suffix.length > 0) {
				var arr = groups.exists(base) ? groups.get(base) : [];
				arr.push(k);
				groups.set(base, arr);
			}
		}
		for (base in groups.keys()) {
			if (!declared.exists(base)) {
				var cand = uniqueCandidate(base, groups.get(base));
				if (cand != null) {
					rename.set(base, cand);
				}
			}
		}

		// Rule 3: nameN -> name when base declared and nameN not declared
		var referenced = new Map<String, Bool>();
		reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST) {
			switch (n.def) {
				case EVar(v):
					referenced.set(v, true);
				default:
			}
		});

		for (k in referenced.keys()) {
			// Detect numeric variant like base + digits
			var i = k.length - 1;
			while (i >= 0 && k.charCodeAt(i) >= '0'.code && k.charCodeAt(i) <= '9'.code)
				i--;
			if (i < k.length - 1) {
				var base = k.substr(0, i + 1);
				var suffix = k.substr(i + 1);
				if (suffix.length > 0 && declared.exists(base) && !declared.exists(k)) {
					rename.set(k, base);
				}
			}
		}

		// Apply renaming only to references (EVar), not to declarations
		function transform(n:ElixirAST):ElixirAST {
			if (n == null || n.def == null)
				return n;
			return switch (n.def) {
				case EVar(name) if (rename.exists(name)):
					makeASTWithMeta(EVar(rename.get(name)), n.metadata, n.pos);
				default:
					n;
			}
		}

		return ElixirASTTransformer.transformNode(body, transform);
	}

	/**
	 * Returns every name that a pattern binds anywhere in one function: its arguments,
	 * the binders of every nested node (`NodeBinders.forEach`), and each variable on the
	 * left of an expression-form match chain (`a = b = rhs`).
	 *
	 * The rename rules use it to decide that a reference is unbound. A binder missing here
	 * makes a valid read look unbound, and a rule then moves it to another variable.
	 */
	static function collectBoundNames(body:ElixirAST, fnArgs:Array<EPattern>):Map<String, Bool> {
		var declared = new Map<String, Bool>();
		function add(name:String):Void
			declared.set(name, true);
		if (fnArgs != null)
			for (arg in fnArgs)
				NodeBinders.forEachInPattern(arg, add);

		function collectMatchChainLhs(lhs:ElixirAST):Void {
			switch (lhs.def) {
				case EVar(lhsName):
					add(lhsName);
				case EBinary(Match, left, right):
					collectMatchChainLhs(left);
					collectMatchChainLhs(right);
				default:
			}
		}

		reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST) {
			NodeBinders.forEach(n, add);
			switch (n.def) {
				case EBinary(Match, left, _):
					collectMatchChainLhs(left);
				default:
			}
		});
		return declared;
	}
}
#end
