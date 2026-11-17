package reflaxe.elixir.ast.naming;

#if (macro || reflaxe_runtime)
import haxe.macro.Expr.Unop;
import haxe.macro.Type.FieldAccess;
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
 *   again after the inner declaration. It gives the inner local a fresh name with a
 *   `_shadow` suffix (`q` -> `q_shadow`). Shadows of one name that are never live at
 *   the same time share that name; only shadows that are live together get
 *   `q_shadow_b`, `q_shadow_c`, ... Apply the result with `HaxeTempLocals.applyRenames`.
 * - The new name never ends in a digit. Several passes treat `name` and `nameN` as
 *   one variable that drifted (`LocalVarReferenceFixTransforms` rules 2 and 3, the
 *   undefined-variable repair in `ElixirASTTransformer`, `GuardConditionFlattener`),
 *   and would map a `q1` back to `q` or a `q` to `q1`. A search of the name rules
 *   (trailing digits, a leading underscore, suffix checks with `endsWith`) found none
 *   that matches a `_shadow` suffix.
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
 * - A rename at the Haxe level, before any builder runs, gives the two locals
 *   different Elixir names, so a pass that flattens the inner block can no longer
 *   merge them. It does not make later passes safe in general: a pass that rewrites
 *   names by their shape can still merge other locals.
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
 * - A variable that the loop or switch lowering binds as an Elixir `fn` argument or a
 *   clause pattern is never renamed, because Elixir already scopes it: the element of
 *   a `for` loop or comprehension (`var x = _g1[_g]`), the index of a range loop
 *   (`var i = _g++`), an iterator element (`var x = it.next()` as the first statement of
 *   `while (it.hasNext())`), a key or value of a key-value loop (`var k = _g1.key`),
 *   and a match binder (`var value = _g1`). See `isLoweredBinderInit`.
 * - A loop variable `var k = k.next()` always has the Elixir name of its iterator `k`,
 *   which Haxe names after the loop variable: when the iterator is renamed, the loop
 *   variable gets the same new name, because the loop lowering matches the
 *   `k = k.next()` shape by name.
 * - Only `var` declarations of locals that Haxe recorded with a source name are
 *   renamed (`HaxeTempLocals.isSourceLocal`): the program's own locals and the locals
 *   of inlined functions. Haxe temps (a backtick name or a backtick `@:realPath`,
 *   `_g`, `g1`) keep their names, because many passes recognise temps by name, and
 *   program locals with temp names are already unique after `HaxeTempLocals`.
 *   Function arguments and `catch` variables bind in their own Elixir clause and keep
 *   their names; `ControlFlowStateHoistTransforms` already keeps an outer value that
 *   a case clause binder hides.
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
 *   q_shadow = 0
 *   q_shadow = Enum.reduce(xs, q_shadow, fn x, q_shadow_acc -> q_shadow_acc + x end)
 *   a = q_shadow
 *   q = q + a
 *
 * LIMITS
 * - A shadow whose outer local is never referenced after the inner declaration keeps
 *   the shared name: the rebinding is then invisible.
 * - Haxe temps (`_g`, `_g1`, backtick names) and locals that this compiler builds
 *   are not renamed by this rule.
 * - Haxe's own renames (`q1` for a shadow whose outer local is read inside the inner
 *   block) keep their digit names, so the name-drift passes above can still merge
 *   them with `q`.
 * - Sharing one shadow name relies on Haxe block scope (no read of an inner local
 *   after its block) and on Elixir closures capturing values, not variables. A later
 *   shadow inside a loop may still be threaded through the loop by name; the earlier
 *   holder is dead then, so the value is not read.
 * - Covered by test/differential/r14_inline_locals and r15_shadow_binders.
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

		// 1. Which inner locals need a new name.
		final shadows:Array<TVar> = [];
		final chosen = new Map<Int, Bool>();
		for (pair in scan.pairs) {
			if (chosen.exists(pair.inner.id) || !scan.isReadAfter(pair))
				continue;
			chosen.set(pair.inner.id, true);
			shadows.push(pair.inner);
		}

		// 2. Which name each one gets. Shadows of one name that are never live at the same
		// time share a name; see `assignShadowNames`.
		final followers = new Map<Int, Array<TVar>>();
		for (pair in scan.loopVariables) {
			final list = followers.get(pair.iterator.id);
			if (list == null)
				followers.set(pair.iterator.id, [pair.loopVariable]);
			else
				list.push(pair.loopVariable);
		}
		final groups = new Map<String, Array<ShadowInterval>>();
		final groupOrder:Array<String> = [];
		for (v in shadows) {
			var end = scan.liveEnd(v.id);
			final loopVariables = followers.get(v.id);
			if (loopVariables != null)
				for (loopVariable in loopVariables)
					end = end > scan.liveEnd(loopVariable.id) ? end : scan.liveEnd(loopVariable.id);
			final key = ElixirNaming.toVarName(v.name);
			var group = groups.get(key);
			if (group == null) {
				group = [];
				groups.set(key, group);
				groupOrder.push(key);
			}
			group.push({v: v, start: scan.declaredAtOf(v.id), end: end});
		}
		for (key in groupOrder)
			for (named in assignShadowNames(groups.get(key), scan.usedNames))
				renamed.set(named.v.id, renamedCopy(named.v, named.name));

		// `for (k in m.keys())`: the loop variable `var k = k.next()` follows its iterator.
		for (pair in scan.loopVariables)
			if (renamed.exists(pair.iterator.id))
				renamed.set(pair.loopVariable.id, renamedCopy(pair.loopVariable, renamed.get(pair.iterator.id).name));
		return renamed;
	}

	/**
	 * Returns a new name for each shadow of one original name, so that two shadows that
	 * can be live at the same time never share a name, and the names stay short.
	 *
	 * Each shadow is live from its declaration to its last read (`ShadowScan.liveEnd`).
	 * Haxe block scope means that no read of an inner local comes after its block ends,
	 * so a later shadow that reuses the name rebinds it only after the earlier one is
	 * dead: `sum += bump(1); sum += bump(2);` gives both inlined `t` locals `t_shadow`.
	 * The interval scheduling is greedy in declaration order: a shadow takes the first
	 * name whose previous holder is dead, otherwise the next name. The number of names
	 * is the largest number of shadows that are live together, so it depends on the
	 * nesting depth, not on the number of calls.
	 *
	 * Names: `t_shadow`, then `t_shadow_b`, `t_shadow_c`, ... (see `shadowName`). Names
	 * that the function already uses are skipped.
	 */
	static function assignShadowNames(group:Array<ShadowInterval>, usedNames:Map<String, Bool>):Array<{v:TVar, name:String}> {
		final result:Array<{v:TVar, name:String}> = [];
		group.sort((a, b) -> a.start - b.start);
		final slots:Array<{name:String, end:Int}> = [];
		var nextIndex = 0;
		for (shadow in group) {
			var slot = null;
			for (candidate in slots)
				if (candidate.end < shadow.start) {
					slot = candidate;
					break;
				}
			if (slot == null) {
				var name = shadowName(shadow.v.name, nextIndex++);
				while (usedNames.exists(ElixirNaming.toVarName(name)))
					name = shadowName(shadow.v.name, nextIndex++);
				usedNames.set(ElixirNaming.toVarName(name), true);
				slot = {name: name, end: shadow.end};
				slots.push(slot);
			}
			slot.end = slot.end > shadow.end ? slot.end : shadow.end;
			result.push({v: shadow.v, name: slot.name});
		}
		return result;
	}

	/**
	 * Returns the shadow name number `index` for `name`: `name_shadow` for 0, then
	 * `name_shadow_b`, `name_shadow_c`, ..., `name_shadow_z`, `name_shadow_bb`, ...
	 *
	 * The letters leave out `a` and those that some name passes match at the end of a
	 * name: `s` (plurals), `x`, `y`, `h` (`ch`) and `d` (`_id`). No digit appears, so
	 * the `name`/`nameN` drift rules never match. The length grows with the logarithm
	 * of `index`, which is at most the nesting depth of the shadows.
	 */
	static function shadowName(name:String, index:Int):String {
		if (index == 0)
			return name + SHADOW_SUFFIX;
		var letters = "";
		var rest = index - 1;
		while (true) {
			letters = SHADOW_LETTERS.charAt(rest % SHADOW_LETTERS.length) + letters;
			rest = Std.int(rest / SHADOW_LETTERS.length) - 1;
			if (rest < 0)
				break;
		}
		return name + SHADOW_SUFFIX + "_" + letters;
	}

	static final SHADOW_LETTERS = "bcefgijklmnopqrtuvwz";

	/**
	 * Returns true when `init` is the value that a loop or switch lowering binds as an
	 * Elixir `fn` argument or clause pattern, not as a `=` statement: `_g1[_g]` (the
	 * element of a `for` loop or comprehension), `_g++` (a range index), `_g1.key` and
	 * `_g1.value` (a key-value loop), and a match binder's value (`_g1`, an enum
	 * parameter). Elixir already scopes such a binding, so renaming it is unnecessary,
	 * and the lowering may not carry the new name to every read.
	 *
	 * An iterator element `var x = it.next()` counts only in the loop shape, which
	 * `ShadowScan` checks: the first statement of `while (it.hasNext())`. Elsewhere,
	 * such as `var tok = lx.next()` in an inlined function, it is an ordinary local.
	 */
	public static function isLoweredBinderInit(init:Null<TypedExpr>):Bool {
		if (init == null)
			return false;
		return switch (init.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, null):
				isLoweredBinderInit(inner);
			case TArray(_, {expr: TLocal(index)}) if (HaxeTempLocals.isTemp(index)):
				true;
			case TUnop(OpIncrement | OpDecrement, true, {expr: TLocal(counter)}) if (HaxeTempLocals.isTemp(counter)):
				true;
			case TField({expr: TLocal(entry)}, FAnon(cf)) if (HaxeTempLocals.isTemp(entry)
				&& (cf.get().name == "key" || cf.get().name == "value")):
				true;
			case TField({expr: TLocal(entry)}, FInstance(_, _, cf)) if (HaxeTempLocals.isTemp(entry)
				&& (cf.get().name == "key" || cf.get().name == "value")):
				true;
			default: HaxeTempLocals.isMatchBinderInit(init);
		};
	}

	static final SHADOW_SUFFIX = "_shadow";

	static function renamedCopy(v:TVar, name:String):TVar {
		return {
			id: v.id,
			name: name,
			t: v.t,
			capture: v.capture,
			extra: v.extra,
			meta: v.meta,
			isStatic: v.isStatic
		};
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

/** A shadow that gets a new name, live from walk position `start` to `end`. */
private typedef ShadowInterval = {
	final v:TVar;
	final start:Int;
	final end:Int;
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

	/** Each loop variable `var k = k.next()` and its same-named iterator `k`. */
	public final loopVariables:Array<{loopVariable:TVar, iterator:TVar}> = [];

	final scopes:Array<Map<String, Array<TVar>>> = [];
	final declaredAt = new Map<Int, Int>();
	final references = new Map<Int, Array<Int>>();
	final loops:Array<PositionRange> = [];
	final functions:Array<PositionRange> = [];

	/** Every open loop, also across local functions: a closure made in a loop is made again. */
	final allLoops:Array<PositionRange> = [];

	/** For each read, its position and the outermost open loop that starts after the declaration. */
	final liveReads = new Map<Int, Array<{at:Int, loop:Null<PositionRange>}>>();

	/** IDs of `var x = it.next()` declared as the first statement of `while (it.hasNext())`. */
	final iteratorElements = new Map<Int, Bool>();

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

	/** Returns the walk position of the declaration of the local `id` (0 when unknown). */
	public function declaredAtOf(id:Int):Int {
		return declaredAt.exists(id) ? declaredAt.get(id) : 0;
	}

	/**
	 * Returns the last walk position where the local `id` can still be read: its last
	 * read, or the end of a loop that reads it but started after its declaration (the
	 * next iteration reads it again). Never less than its declaration.
	 */
	public function liveEnd(id:Int):Int {
		var end = declaredAtOf(id);
		final reads = liveReads.get(id);
		if (reads != null)
			for (read in reads) {
				final at = read.loop != null && read.loop.end > read.at ? read.loop.end : read.at;
				if (at > end)
					end = at;
			}
		return end;
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

	/**
	 * Records the element `x` of a loop `while (it.hasNext()) { var x = it.next(); ... }`:
	 * the first declaration of the body, on the same iterator (`HaxeTempLocals.iteratorLoopHead`).
	 * The loop lowering binds it as an fn argument. A later `var y = it.next()` in the body
	 * is an ordinary local: the lowering leaves such a loop unchanged.
	 */
	function markIteratorElements(cond:TypedExpr, body:TypedExpr):Void {
		final head = HaxeTempLocals.iteratorLoopHead(cond, body);
		if (head != null)
			iteratorElements.set(head.element.id, true);
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
				final declared = declaredAtOf(v.id);
				var outermost:Null<PositionRange> = null;
				for (loop in allLoops)
					if (loop.start > declared) {
						outermost = loop;
						break;
					}
				var reads = liveReads.get(v.id);
				if (reads == null) {
					reads = [];
					liveReads.set(v.id, reads);
				}
				reads.push({at: position, loop: outermost});
			case TVar(v, init):
				if (init != null)
					walk(init);
				// A loop element, range index, iterator element or match binder binds as an
				// Elixir fn argument or clause pattern and keeps its name.
				final iterator = v != null && iteratorElements.exists(v.id) ? HaxeTempLocals.iteratorOfNextCall(init) : null;
				if (iterator != null && iterator.name == v.name)
					loopVariables.push({loopVariable: v, iterator: iterator});
				declare(v, iterator == null && !ShadowedLocals.isLoweredBinderInit(init), iterator);
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
				markIteratorElements(cond, body);
				final range = {start: position, end: position};
				loops.push(range);
				allLoops.push(range);
				walk(cond);
				walk(body);
				allLoops.pop();
				loops.pop();
				range.end = position;
			case TFor(v, iterator, body):
				walk(iterator);
				final range = {start: position + 1, end: position};
				loops.push(range);
				allLoops.push(range);
				openScope();
				declare(v, false);
				walk(body);
				closeScope();
				allLoops.pop();
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
