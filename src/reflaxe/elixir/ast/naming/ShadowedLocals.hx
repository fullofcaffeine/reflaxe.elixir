package reflaxe.elixir.ast.naming;

#if (macro || reflaxe_runtime)
import haxe.macro.Type.TVar;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypedExprTools;

/**
 * ShadowedLocals: gives a fresh name to an inner local that would overwrite an outer
 * local with the same name in Elixir.
 *
 * WHAT
 * - Haxe gives every block its own scope. An inner `var q` hides an outer `q` only
 *   until the inner block ends; after the block, `q` is the outer local again.
 * - Elixir has no block scope inside one function clause. When the compiler prints
 *   the inner local into the same Elixir scope as the outer one, both become one
 *   variable, and the inner value replaces the outer value.
 * - `renamesForShadowingLocals` finds each inner `var` whose Elixir name equals the
 *   name of a local declared in an enclosing scope, where that outer local is read
 *   again after the inner declaration. It gives the inner local the next free name in
 *   Haxe's own style (`q` -> `q1`, then `q2`, ...). Apply the result with
 *   `HaxeTempLocals.applyRenames`.
 *
 * WHY
 * - Haxe renames a shadowing local only when the outer local is read inside the
 *   inner block (`var t = base + 1` next to the caller's `t` becomes `t1`). It does
 *   not rename when the outer local is read only after the inner block ends, because
 *   that is safe with block scope. Inlining makes this common: the inlined body of
 *   `inline function sum(xs) { var q = 0; for (x in xs) q += x; return q; }` is a
 *   nested block with its own `var q`.
 * - Late passes then put such a block into the caller's scope: for example
 *   `MatchBlockRhsExtractLast_Final` turns `a = (fn -> q = 0; ...; q end).()` into
 *   `q = 0; ...; a = q`, and the loop lowering threads accumulators by name. The
 *   caller's `q` was silently overwritten (`var q = 100; var a = sum(xs); q += a;`
 *   gave 15 on the BEAM instead of 109).
 * - A rename at the Haxe level, before any builder runs, keeps every later pass safe:
 *   two Haxe locals that can be alive at the same time never share an Elixir name.
 *
 * HOW
 * - One walk over the function body in evaluation order numbers each node. It
 *   records each local's declaration position and every position that reads or
 *   writes it, the open scopes (blocks, functions, `catch` clauses, `for` loops), the
 *   loops, and the innermost local function around each declaration.
 * - A `var` declaration whose Elixir name is already declared in an open scope
 *   (including its own scope, because Haxe's typed tree can merge an inlined block
 *   into its parent) forms a pair with each such outer local.
 * - The inner local is renamed when an outer local of a pair is referenced
 *   - at any position after the inner declaration, up to the end of the innermost
 *     local function around the inner declaration (an Elixir `fn` keeps its own
 *     bindings, so reads after it ends are safe), or
 *   - anywhere inside a loop that contains the inner declaration but not the outer
 *     declaration: the next iteration reads the outer local again.
 * - A loop variable `var k = k.next()` keeps the name of its iterator `k`, which Haxe
 *   names after the loop variable; the loop lowering matches that shape by name.
 * - Only `var` declarations of locals that Haxe recorded with a source name are
 *   renamed (`HaxeTempLocals.isSourceLocal`): the program's own locals and the locals
 *   of inlined functions. Haxe temps (a backtick name or a backtick `@:realPath`,
 *   `_g`, `g1`) keep their names, because many passes recognise temps by name, and
 *   program locals with temp names are already unique after `HaxeTempLocals`.
 *   Function arguments, `catch` variables and match binders (`case Ok(value)`, see
 *   `HaxeTempLocals.isMatchBinderInit`) bind in their own Elixir clause and keep their
 *   names; `ControlFlowStateHoistTransforms` already keeps an outer value that a case
 *   clause binder hides.
 * - The copy keeps the TVar ID, so ID-keyed tracking is unchanged.
 *
 * EXAMPLES
 * Haxe:
 *   static inline function sum(xs:Array<Int>):Int { var q = 0; for (x in xs) q += x; return q; }
 *   static function use(xs:Array<Int>):Int { var q = 100; var a = sum(xs); q += a; return q; }
 * Elixir before:
 *   q = 100
 *   q = 0
 *   q = Enum.reduce(xs, q, fn x, q_acc -> q_acc + x end)
 *   a = q
 *   q = q + a
 * Elixir after:
 *   q = 100
 *   q1 = 0
 *   q1 = Enum.reduce(xs, q1, fn x, q1_acc -> q1_acc + x end)
 *   a = q1
 *   q = q + a
 *
 * LIMITS
 * - A shadow whose outer local is never referenced after the inner declaration keeps
 *   the shared name: the rebinding is then invisible.
 * - Haxe temps (`_g`, `_g1`, backtick names) and locals that this compiler builds
 *   are not renamed by this rule.
 * - Covered by test/differential/r14_inline_locals.
 */
class ShadowedLocals {
	/**
	 * Returns a renamed `TVar` copy, by ID, for each inner local that would overwrite an
	 * outer local in Elixir (see the class documentation). `argumentNames` (Elixir form)
	 * count as taken names; `arguments` are the function's own arguments, which are the
	 * outermost scope. Call it after `HaxeTempLocals` renames are applied to `body`.
	 */
	public static function renamesForShadowingLocals(body:Null<TypedExpr>, ?argumentNames:Array<String>, ?arguments:Array<TVar>):Map<Int, TVar> {
		final renamed = new Map<Int, TVar>();
		if (body == null)
			return renamed;
		final scan = new ShadowScan();
		if (argumentNames != null)
			for (name in argumentNames)
				scan.usedNames.set(name, true);
		scan.openScope();
		if (arguments != null)
			for (v in arguments)
				scan.declare(v, false);
		scan.walk(body);
		scan.closeScope();

		for (pair in scan.pairs) {
			if (renamed.exists(pair.inner.id) || !scan.isReadAfter(pair))
				continue;
			final base = pair.inner.name;
			var suffix = 1;
			var name = base + suffix;
			while (scan.usedNames.exists(ElixirNaming.toVarName(name)))
				name = base + (++suffix);
			scan.usedNames.set(ElixirNaming.toVarName(name), true);
			final v = pair.inner;
			renamed.set(v.id, {
				id: v.id,
				name: name,
				t: v.t,
				capture: v.capture,
				extra: v.extra,
				meta: v.meta,
				isStatic: v.isStatic
			});
		}
		return renamed;
	}
}

/**
 * A range of walk positions: a loop or a local function. `end` is set when the walk
 * leaves the node.
 */
private typedef PositionRange = {
	var start:Int;
	var end:Int;
}

/**
 * An inner `var` declaration and an outer local with the same Elixir name that is in
 * scope at that declaration.
 */
private typedef ShadowPair = {
	final inner:TVar;
	final outer:TVar;
	final declaredAt:Int;
	final outerDeclaredAt:Int;
	final enclosingFunction:PositionRange;
	final enclosingLoops:Array<PositionRange>;
}

/**
 * The walk state for `ShadowedLocals.renamesForShadowingLocals`: positions, scopes and
 * shadow pairs of one function body.
 */
private class ShadowScan {
	public final usedNames = new Map<String, Bool>();
	public final pairs:Array<ShadowPair> = [];

	final scopes:Array<Map<String, Array<TVar>>> = [];
	final declaredAt = new Map<Int, Int>();
	final references = new Map<Int, Array<Int>>();
	final loops:Array<PositionRange> = [];
	final functions:Array<PositionRange> = [];
	var position = 0;

	public function new() {
		functions.push({start: 0, end: 0x3FFFFFFF});
	}

	public function openScope():Void {
		scopes.push(new Map());
	}

	public function closeScope():Void {
		scopes.pop();
	}

	/**
	 * Records the declaration of `v` in the innermost scope. When `canRename` is true
	 * (a `var`), it first pairs `v` with each open local of the same Elixir name,
	 * except `iterator` when `v` is the loop variable `iterator.next()`.
	 */
	public function declare(v:Null<TVar>, canRename:Bool, ?iterator:TVar):Void {
		if (v == null || v.name == null)
			return;
		position++;
		final name = ElixirNaming.toVarName(v.name);
		usedNames.set(name, true);
		declaredAt.set(v.id, position);
		if (canRename && HaxeTempLocals.isSourceLocal(v) && !HaxeTempLocals.hasTempName(v)) {
			for (scope in scopes) {
				final outers = scope.get(name);
				if (outers == null)
					continue;
				for (outer in outers) {
					// `for (k in m.keys())`: Haxe names the iterator after the loop variable
					// (`var k = m.keys(); while (k.hasNext()) { var k = k.next(); ... }`).
					// The pair keeps one name, as in `HaxeTempLocals`, because the loop
					// lowering matches the `k = k.next()` shape by name.
					if (outer.id == v.id || (iterator != null && iterator.id == outer.id))
						continue;
					pairs.push({
						inner: v,
						outer: outer,
						declaredAt: position,
						outerDeclaredAt: declaredAt.exists(outer.id) ? declaredAt.get(outer.id) : 0,
						enclosingFunction: functions[functions.length - 1],
						enclosingLoops: loops.copy()
					});
				}
			}
		}
		final scope = scopes[scopes.length - 1];
		final list = scope.get(name);
		if (list == null)
			scope.set(name, [v]);
		else
			list.push(v);
	}

	/**
	 * Returns true when the outer local of `pair` is referenced after the inner
	 * declaration in the same Elixir function, or inside a loop around the inner
	 * declaration that does not also contain the outer declaration.
	 */
	public function isReadAfter(pair:ShadowPair):Bool {
		final positions = references.get(pair.outer.id);
		if (positions == null)
			return false;
		for (at in positions) {
			if (at > pair.declaredAt && at <= pair.enclosingFunction.end)
				return true;
			for (loop in pair.enclosingLoops)
				if (pair.outerDeclaredAt < loop.start && at >= loop.start && at <= loop.end)
					return true;
		}
		return false;
	}

	public function walk(e:TypedExpr):Void {
		position++;
		switch (e.expr) {
			case TLocal(v) if (v != null):
				var list = references.get(v.id);
				if (list == null) {
					list = [];
					references.set(v.id, list);
				}
				list.push(position);
			case TVar(v, init):
				if (init != null)
					walk(init);
				// A match binder (`case Ok(value)` types as `var value = _g1`) binds in its own
				// Elixir case clause and keeps its pattern name.
				declare(v, !HaxeTempLocals.isMatchBinderInit(init), HaxeTempLocals.iteratorOfNextCall(init));
			case TBlock(exprs):
				openScope();
				for (child in exprs)
					walk(child);
				closeScope();
			case TFunction(fn):
				final range = {start: position, end: position};
				functions.push(range);
				final outerLoops = loops.splice(0, loops.length);
				openScope();
				for (arg in fn.args) {
					if (arg.value != null)
						walk(arg.value);
					declare(arg.v, false);
				}
				walk(fn.expr);
				closeScope();
				for (loop in outerLoops)
					loops.push(loop);
				functions.pop();
				range.end = position;
			case TWhile(cond, body, _):
				final range = {start: position, end: position};
				loops.push(range);
				walk(cond);
				walk(body);
				loops.pop();
				range.end = position;
			case TFor(v, iterator, body):
				walk(iterator);
				final range = {start: position + 1, end: position};
				loops.push(range);
				openScope();
				declare(v, false);
				walk(body);
				closeScope();
				loops.pop();
				range.end = position;
			case TTry(tryExpr, catches):
				walk(tryExpr);
				for (c in catches) {
					openScope();
					declare(c.v, false);
					walk(c.expr);
					closeScope();
				}
			default:
				TypedExprTools.iter(e, walk);
		}
	}
}
#end
