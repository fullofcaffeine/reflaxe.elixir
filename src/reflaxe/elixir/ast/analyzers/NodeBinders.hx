package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.ElixirAST;
import reflaxe.elixir.ast.ElixirPatternChildren;

/**
 * NodeBinders: lists the variable names that one Elixir AST node binds in its own
 * patterns.
 *
 * WHAT
 * - `forEach(node, visit)` calls `visit` once for each name that a pattern owned by
 *   `node` binds. It does not look into child nodes; walk the tree and call it for
 *   each node to get every binder of a function body.
 * - The binding positions are: the arguments of `def`/`defp`/`defmacro`/`defmacrop`,
 *   the arguments of each `fn` clause, `case` and `receive` clause patterns, `with`
 *   clause patterns, comprehension generators (`for x <- xs`), `rescue` patterns and
 *   their `e in ...` name, `catch` patterns, and the left side of `=` (`EMatch`).
 * - Inside a pattern, `x` (`PVar`) and `x = pattern` (`PAlias`) bind `x`. A pinned
 *   `^x` (`PPin`) reads `x`, but `forEach` reports it too. A caller that uses the result
 *   to decide "this name already belongs to a variable, leave it alone" stays on the
 *   safe side; the pinned variable is bound somewhere else anyway.
 *
 * WHY
 * - A pass that renames a reference because "its name is not bound in this function"
 *   must see every binder it can. Several passes collected only the `def` arguments and the
 *   `=` patterns. A `fn q -> ... end` argument then looked unbound, and the reference
 *   `q` was rewritten to another variable `q1`: the program computed with the wrong
 *   value (`haxe.elixir.codex-hhp5`).
 * - Each binder kind is listed once here, so a new binding form is added in one place.
 *
 * HOW
 * - A switch over the binder-owning node kinds, then `ElixirPatternChildren.walk` over
 *   each owned pattern. The order of calls is deterministic (field order).
 * - `EBinary(Match, ...)`, the expression form of `a = rhs`, is not a pattern node, so
 *   `forEach` reports nothing for it. `LocalVarReferenceFixTransforms` adds the plain
 *   variables of an `a = b = rhs` chain itself.
 *
 * LIMITS
 * - This is not every binding in the program. It does not see names bound:
 *   - by an expression-form match whose left side is not a plain variable
 *     (`{a, b} = rhs` as `EBinary(Match, ETuple(...), rhs)`);
 *   - inside raw code (`ERaw`, `__elixir__` text);
 *   - by macros, such as an Ecto query binding `[t]` in `where(query, [t], t.name)`.
 * - So "no binder declares this name" does not prove that a read is undefined. Use the
 *   result to block a rewrite, not to choose a new name.
 *
 * EXAMPLES
 * - `fn q -> q * 2 end`                         -> `q`
 * - `case r do {:ok, value} -> value end`       -> `value`
 * - `for {k, v} <- pairs, do: k`                -> `k`, `v`
 * - `try do ... rescue e in ArgumentError -> e end` -> `e`
 */
class NodeBinders {
	/**
	 * Calls `visit` with each name bound by a pattern that `node` itself owns.
	 *
	 * Use it inside a tree walk to collect all binders of a function, for example before
	 * deciding that a reference is undefined. It never reports names from child nodes.
	 */
	public static function forEach(node:ElixirAST, visit:String->Void):Void {
		if (node == null || node.def == null)
			return;
		switch (node.def) {
			case EDef(_, args, _, _) | EDefp(_, args, _, _) | EDefmacro(_, args, _, _) | EDefmacrop(_, args, _, _):
				for (arg in args)
					forEachInPattern(arg, visit);
			case EFn(clauses):
				for (clause in clauses)
					for (arg in clause.args)
						forEachInPattern(arg, visit);
			case ECase(_, clauses) | EReceive(clauses, _):
				for (clause in clauses)
					forEachInPattern(clause.pattern, visit);
			case EWith(clauses, _, _):
				for (clause in clauses)
					forEachInPattern(clause.pattern, visit);
			case EFor(generators, _, _, _, _):
				for (generator in generators)
					forEachInPattern(generator.pattern, visit);
			case ETry(_, rescueClauses, catchClauses, _, _):
				if (rescueClauses != null)
					for (clause in rescueClauses) {
						forEachInPattern(clause.pattern, visit);
						if (clause.varName != null)
							visit(clause.varName);
					}
				if (catchClauses != null)
					for (clause in catchClauses)
						forEachInPattern(clause.pattern, visit);
			case EMatch(pattern, _):
				forEachInPattern(pattern, visit);
			default:
		}
	}

	/**
	 * Calls `visit` with each name that `pattern` binds (`x` and `x = ...`), and with
	 * pinned names (`^x`), in deterministic order.
	 */
	public static function forEachInPattern(pattern:Null<EPattern>, visit:String->Void):Void {
		if (pattern == null)
			return;
		ElixirPatternChildren.walk(pattern, _ -> {}, nested -> switch (nested) {
			case PVar(name):
				visit(name);
			case PAlias(name, _):
				visit(name);
			default:
		});
	}
}
#end
