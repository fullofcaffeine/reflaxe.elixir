package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.NodeBinders;

/**
 * LocalVarReferenceFixTransforms: points a reference whose name looks undeclared at a
 * declared local with a closely related name.
 *
 * WHAT
 * - Inside each `def`/`defp`, the rules look at two name sets:
 *   - targets: the names bound by the `def` arguments and by `=` (an `EMatch` pattern
 *     or an `a = b = rhs` chain). A rule may move a reference only to a target, and
 *     only a target decides that a name is "declared" for the rules;
 *   - binders: every name that `NodeBinders` sees bound anywhere in the function:
 *     the targets, plus `fn` arguments, `case`/`receive`/`with` clause patterns,
 *     comprehension generators, and `rescue`/`catch` patterns.
 * - The rules, as before `haxe.elixir.codex-hhp5`:
 *   - rule 1: `name` -> `_name` when `_name` is a target and `name` is not;
 *   - rule 2: `name` -> `nameN` when `nameN` (`name` plus digits) is the only numbered
 *     target of that base and `name` is not a target;
 *   - rule 3: `nameN` -> `name` when `name` is a target and `nameN` is not.
 * - Two blocks then remove rewrites:
 *   - a reference whose name is in the binder set is never changed;
 *   - rule 2 is dropped when the binder set has more than one `nameN` for that base.
 * - Declarations are never changed; only references are.
 *
 * GUARANTEE
 * - Every rewrite this pass makes is one that the pass also made before
 *   `haxe.elixir.codex-hhp5` (same reference, same new name). The fix only removes
 *   rewrites; it never adds one.
 * - A reference keeps its name when any binder that `NodeBinders` sees declares it.
 * - This is not a proof that every changed reference was unbound. Some valid reads
 *   have no binder that this pass can see: names bound inside raw code (`ERaw`,
 *   `__elixir__`), names bound by macros (an Ecto query binding `[t]`), names bound by
 *   an expression-form tuple match (`{a, b} = rhs` as `EBinary(Match, ...)`), and
 *   function references. A rule can still move such a read, exactly as before.
 *
 * WHY
 * - Older builder and hygiene steps could declare one spelling and read another
 *   (`_changeset` declared, `changeset` read; `query2` declared, `query` read). Elixir
 *   rejects the unbound read, so pointing it at the only candidate repaired the build.
 * - The rules match names by their shape. Earlier versions counted only the targets as
 *   declared. A `fn q -> ... end` argument, a case binder or a catch binder then looked
 *   undeclared, and its reads were moved to another variable with a similar name:
 *
 *       Haxe:   function(q:Int) { { var q = 999; } return q * 2; }
 *       Elixir: fn q -> q1 = 999; q * 2 end
 *       Before: fn q -> q1 = 999; q1 * 2 end   (returns 1998, not 8)
 *       After:  unchanged, because the `fn` binds `q`.
 *
 *   Haxe already proved these names are different variables (`q1` is its own rename
 *   of an inner shadow); the shape rule must not merge them again.
 * - The binder set must only block, never offer targets. If a `fn` argument `t2` were
 *   a target, rule 2 would move a valid read `t` of an Ecto query binding `[t]` (which
 *   no binder that this pass sees declares) to `t2`, and the query would change.
 *
 * HOW
 * - One walk collects the targets (`collectRenameTargets`), one collects the binders
 *   (`collectBoundNames`). The rules build a rename map from the targets, the blocks
 *   remove entries, and one transform rewrites matching `EVar` references.
 * - Haxe `TVar` ids would decide drift exactly, but references no longer carry
 *   `sourceVarId` metadata when this late pass runs, so the name sets are the
 *   structural guard here.
 *
 * EXAMPLES
 * - `_changeset = cast(...); changeset` -> `_changeset = cast(...); _changeset` (rule 1)
 * - `query2 = from(...); Repo.all(query)` -> `...; Repo.all(query2)` (rule 2)
 * - a read of `count2` where only `count` is bound -> a read of `count` (rule 3)
 * - `fn q -> q1 = 999; q * 2 end`: no change, a binder declares `q` (block 1)
 * - `query(...)` with a raw-bound `[t]` and `fn t2 -> ... end`: no change, `t2` is not
 *   a target
 *
 * LIMITS
 * - Names inside raw code (`ERaw`, such as an interpolated string) are neither counted
 *   as reads nor rewritten.
 * - The binder check covers the whole function, not one scope: a name that is bound
 *   anywhere in the function is left alone everywhere in it.
 * - Regression coverage: `test/differential/r18_name_drift_binders` and
 *   `test/snapshot/ecto/typed_query_binding_numbered_args`.
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
		// Rename targets: the binders the rules were written for (def arguments and `=`).
		var targets = collectRenameTargets(body, fnArgs);
		// Every binder NodeBinders sees. It only blocks rewrites; it never adds a target.
		var bound = collectBoundNames(body, fnArgs);

		// Build a simple, unambiguous rename map
		var rename = new Map<String, String>();

		// Helper to test uniqueness of candidate
		function uniqueCandidate(base:String, candidates:Array<String>):Null<String> {
			return candidates.length == 1 ? candidates[0] : null;
		}

		// Precompute target lists for matching
		var targetKeys = [for (k in targets.keys()) k];

		// Rule 1: name -> _name when _name is a target and name is not
		for (k in targetKeys) {
			if (StringTools.startsWith(k, "_") && k.length > 1) {
				var base = k.substr(1);
				if (!targets.exists(base)) {
					// Map base -> k only if not already mapped
					rename.set(base, k);
				}
			}
		}

		// Rule 2: name -> nameN when nameN is the only numbered target and name is not a target
		// Build index by base name
		var groups = numberedByBase(targetKeys);
		var boundGroups = numberedByBase([for (k in bound.keys()) k]);
		for (base in groups.keys()) {
			if (!targets.exists(base)) {
				var cand = uniqueCandidate(base, groups.get(base));
				if (cand != null) {
					// Block: another binder (a fn argument, a case binder, ...) also has this
					// base plus digits, so `cand` is not the only candidate. Drop the whole
					// entry, including a rule-1 mapping of the same name.
					var numberedBinders = boundGroups.get(base);
					if (numberedBinders == null || numberedBinders.length == 1)
						rename.set(base, cand);
					else
						rename.remove(base);
				}
			}
		}

		// Rule 3: nameN -> name when base is a target and nameN is not
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
				if (suffix.length > 0 && targets.exists(base) && !targets.exists(k)) {
					rename.set(k, base);
				}
			}
		}

		// Block: a name that any binder declares is a valid read; never move it.
		for (name in [for (k in rename.keys()) k])
			if (bound.exists(name))
				rename.remove(name);

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
	 * Groups the names that end in digits by their base: `query2` and `query10` under
	 * `query`. Names without a digit suffix are left out.
	 */
	static function numberedByBase(names:Array<String>):Map<String, Array<String>> {
		var groups = new Map<String, Array<String>>();
		for (k in names) {
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
		return groups;
	}

	/**
	 * Returns the names the rename rules may point a reference at: the `def` arguments
	 * (plain names, and plain names one level inside a tuple or list) and the names bound
	 * by `=` (`EMatch` patterns and `a = b = rhs` chains).
	 *
	 * This is exactly the set that the rules used before `haxe.elixir.codex-hhp5`. It
	 * stays narrow on purpose. A wider set (fn arguments, case binders, loop elements)
	 * would offer new targets: a valid read of a name bound by raw code, such as an Ecto
	 * query binding `[t]`, would then move to a lambda argument `t2`.
	 */
	static function collectRenameTargets(body:ElixirAST, fnArgs:Array<EPattern>):Map<String, Bool> {
		var targets = new Map<String, Bool>();
		if (fnArgs != null) {
			for (a in fnArgs)
				switch (a) {
					case PVar(n):
						targets.set(n, true);
					case PTuple(es) | PList(es):
						for (e in es)
							switch (e) {
								case PVar(n2): targets.set(n2, true);
								default:
							}
					default:
				}
		}

		function collectPattern(p:EPattern):Void {
			switch (p) {
				case PVar(n):
					targets.set(n, true);
				case PTuple(es) | PList(es):
					for (e in es)
						collectPattern(e);
				case PCons(h, t):
					collectPattern(h);
					collectPattern(t);
				case PMap(kvs):
					for (kv in kvs)
						collectPattern(kv.value);
				case PStruct(_, fs):
					for (f in fs)
						collectPattern(f.value);
				case PPin(inner):
					collectPattern(inner);
				default:
			}
		}

		function collectLhsVars(lhs:ElixirAST):Void {
			switch (lhs.def) {
				case EVar(lhsName):
					targets.set(lhsName, true);
				case EBinary(Match, l2, r2):
					collectLhsVars(l2);
					collectLhsVars(r2);
				default:
			}
		}

		reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST) {
			if (n == null || n.def == null)
				return;
			switch (n.def) {
				case EMatch(pattern, _):
					collectPattern(pattern);
				case EBinary(Match, left, _):
					collectLhsVars(left);
				default:
			}
		});
		return targets;
	}

	/**
	 * Returns every name that a pattern binds anywhere in one function: its arguments,
	 * the binders of every nested node (`NodeBinders.forEach`), and each variable on the
	 * left of an expression-form match chain (`a = b = rhs`).
	 *
	 * Only the blocks use it: a reference whose name is here is never rewritten, and rule 2
	 * needs exactly one numbered binder of its base here. It never offers a rename target.
	 * A binder missing here lets a rule move a valid read. It does not see names bound in
	 * raw code, by macros, or by an expression-form tuple match (`{a, b} = rhs`).
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
