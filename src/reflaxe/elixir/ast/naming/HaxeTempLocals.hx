package reflaxe.elixir.ast.naming;

#if (macro || reflaxe_runtime)
import haxe.macro.Type.TVar;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypedExprTools;

/**
 * HaxeTempLocals: tells a temp that Haxe introduced from a local that the program declared.
 *
 * WHAT
 * - `isTemp(v)` is true for a local named like a Haxe temp (`_g`, `_g1`, `g`, `g1`, ...)
 *   unless Haxe recorded that the program itself declared it.
 * - `isSourceLocal(v)` is true when Haxe recorded that the program declared the local.
 *
 * WHY
 * - Haxe desugars loops, comprehensions and switches with temps named `_g`, `_g1`, ...
 *   Many passes recognise these temps by their name. A program local can have the same
 *   name: `var g = 0;`. When a pass treats it as a temp, the output is silently wrong:
 *   - `var g = 0; g = 5; while (i < n) g++;` started the loop from 0, not from 5;
 *   - `var g = []; for (i in 0...n) g.push(i);` lost the declaration, and the range
 *     counter `_g = 0` took the name `g`, so the loop appended to `0`.
 *
 * HOW
 * - Haxe types a temp with the name "`" (a backtick). Haxe's final renaming filter
 *   then gives it a printable name (`_g`, `_g1`, ...) and records each earlier name in
 *   `@:realPath`. A program local records its source spelling there instead; a local
 *   from an inlined function keeps its own name. Haxe 5 can keep the backtick in the
 *   name itself.
 * - So the rule is structural: a local is a program local when it has a `@:realPath`
 *   entry, and neither its name nor any of those entries starts with a backtick.
 * - A local without `@:realPath`, such as a `TVar` that this compiler builds, keeps the
 *   old name rule. Only locals that Haxe proves are program locals change behaviour.
 * - Before the builders run, `renamesForSourceLocalsWithTempNames` moves most program
 *   locals out of the temp names (`g` -> `local_g`). Kept match binders
 *   (`case RGB(r, g, b)`) and locals that this compiler builds can still have a temp
 *   name, so a builder that must not drop a program value checks `isSourceLocal`, not the name.
 *
 * EXAMPLES (Haxe 4.3.7, as the compiler sees them after Haxe's filters)
 * - `var g = [];`                  -> name `g`,  `@:realPath("g")`           -> source local
 * - `for (k => v in m)` iterator   -> name `_g`, `@:realPath("_g")`, `@:realPath("\`")` -> temp
 * - `var _g = 1;` written by hand  -> name `_g`, `@:realPath("_g")`          -> source local
 * - `for (g in m.keys())`          -> the iterator `var g = m.keys()` and the loop variable
 *   `var g = g.next()` both have name `g` and `@:realPath("g")`. Haxe names the iterator
 *   after the loop variable, so both count as source locals; the rename keeps them paired.
 */
class HaxeTempLocals {
	static final TEMP_NAME = ~/^_?g[0-9]*$/;

	/**
	 * Returns true when `v` is a Haxe temp: it has a temp-shaped name (`_g`, `g1`, ...)
	 * and Haxe did not record that the program declared it.
	 *
	 * Use this, not a name check, before treating a local as loop or switch
	 * infrastructure (seeding a loop from its declared value, substituting its
	 * initializer, or skipping its declaration).
	 */
	public static function isTemp(v:Null<TVar>):Bool {
		if (v == null || v.name == null)
			return false;
		return TEMP_NAME.match(v.name) && !isSourceLocal(v);
	}

	/**
	 * Returns true when `v` has a temp-shaped name (`_g`, `g1`, ...), whatever its origin.
	 * Prefer `isTemp`; this keeps an existing name-only rule where the origin does not matter.
	 */
	public static function hasTempName(v:Null<TVar>):Bool {
		return v != null && v.name != null && TEMP_NAME.match(v.name);
	}

	/**
	 * Returns true when Haxe recorded that the program declared `v`.
	 *
	 * Haxe records the source spelling of each local in `@:realPath`. A temp has the
	 * generated mark (a leading backtick) in one of those entries or in its name.
	 * A local without any `@:realPath` entry is not proven to be a source local.
	 */
	public static function isSourceLocal(v:Null<TVar>):Bool {
		if (v == null || v.name == null || StringTools.startsWith(v.name, "`"))
			return false;
		if (v.meta == null)
			return false;
		final entries = v.meta.extract(":realPath");
		if (entries.length == 0)
			return false;
		for (entry in entries) {
			if (entry.params == null)
				continue;
			for (param in entry.params) {
				switch (param.expr) {
					case EConst(CString(path, _)) if (StringTools.startsWith(path, "`")):
						return false;
					default:
				}
			}
		}
		return true;
	}

	/**
	 * Picks a new name for each program local whose name looks like a Haxe temp:
	 * `g` becomes `local_g`. Returns the renamed `TVar` copies by ID; apply them with
	 * `applyRenames`, and use them for the function's own arguments.
	 *
	 * WHAT
	 * - A program local is a local that the program declared and that Haxe recorded
	 *   with its source name (`isSourceLocal`). When its name has the temp shape
	 *   (`g`, `g1`, `_g`, `_g2`, ...), it gets a new name such as `local_g`.
	 * - Each renamed declaration gets a fresh name that nothing else in the function
	 *   uses: `local_g`, then `local_g_2`, ... Leading underscores go, so `_g` becomes
	 *   `local_g` too, unless that name is taken. Two declarations with the same Haxe
	 *   name get different new names: Elixir has no block scope, so an inlined
	 *   function's own `var g` must not take over the caller's `g`. Locals with other
	 *   names get the same protection from `ShadowedLocals`.
	 * - One pair keeps one name: Haxe names the iterator of `for (g in m.keys())` after
	 *   the loop variable (`var g = m.keys(); while (g.hasNext()) { var g = g.next(); }`).
	 *   The loop variable, whose value is `g.next()` on its same-named iterator, reuses
	 *   the iterator's new name (paired by ID), because later passes match the
	 *   `iter = iter.next.()` shape by name.
	 * - This applies to every kind of declaration: `var`, the function's own
	 *   arguments (`arguments`), the arguments of a local function, and `catch`
	 *   variables. Loop variables, and the iterator that Haxe names after a loop
	 *   variable, are `var` declarations by this stage.
	 * - It applies whether or not the function also has a Haxe temp.
	 * - One exception keeps a common pattern readable. A match binder
	 *   (`case RGB(r, g, b)` types as `var g = _g1`, see `isMatchBinderInit`) keeps its
	 *   name, unless a loop condition in the same function reads a temp with the same
	 *   base name. Its case pattern binds it, and `{:rgb, r, g, b}` reads better than
	 *   `{:rgb, r, local_g, b}`.
	 * - The names in `argumentNames` (Elixir form) always count as used. The copy keeps
	 *   the ID, so ID-keyed tracking is unchanged.
	 * - Call it on the body that the builders compile, after
	 *   `TypedExprPreprocessor.preprocess`.
	 *
	 * WHY
	 * - Many builder paths and ElixirAST passes decide by name alone that a local is
	 *   a Haxe temp: `g`, `_g` and `g1` are temps there. This rename keeps most
	 *   program locals away from those checks. Before it, a program local with such
	 *   a name could be silently miscompiled:
	 *   - an argument `g` next to `for (i in 0...n)` was overwritten by the loop
	 *     counter `_g = 0`, which a hygiene pass promotes to `g` when it sees `g` read;
	 *   - a program local `_g` read after a loop was rewritten to `g`, an undefined
	 *     variable in Elixir.
	 * - It does not cover kept match binders or locals that this compiler builds; a
	 *   check that must not lose a program value asks `isSourceLocal`.
	 * - The temps keep their names because many passes recognise temps by them.
	 */
	public static function renamesForSourceLocalsWithTempNames(body:Null<TypedExpr>, ?argumentNames:Array<String>, ?arguments:Array<TVar>):Map<Int, TVar> {
		final renamed = new Map<Int, TVar>();
		final loopTempBases = new Map<String, Bool>();
		final binders = new Map<Int, Bool>();
		final nextOf = new Map<Int, TVar>();
		final usedNames = new Map<String, Bool>();
		final candidates:Array<TVar> = [];
		final seen = new Map<Int, Bool>();
		if (argumentNames != null)
			for (name in argumentNames)
				usedNames.set(name, true);
		function note(v:Null<TVar>):Void {
			if (v == null || v.name == null)
				return;
			usedNames.set(ElixirNaming.toVarName(v.name), true);
		}
		function consider(v:Null<TVar>, ?init:TypedExpr):Void {
			note(v);
			if (v == null || v.name == null || seen.exists(v.id) || !TEMP_NAME.match(v.name) || !isSourceLocal(v))
				return;
			seen.set(v.id, true);
			candidates.push(v);
			if (isMatchBinderInit(init))
				binders.set(v.id, true);
			final iterator = iteratorOfNextCall(init);
			if (iterator != null)
				nextOf.set(v.id, iterator);
		}
		function noteLoopTemps(cond:TypedExpr):Void {
			switch (cond.expr) {
				case TLocal(v) if (isTemp(v)):
					loopTempBases.set(stripLeadingUnderscores(v.name), true);
				default:
			}
			TypedExprTools.iter(cond, noteLoopTemps);
		}
		function scan(e:TypedExpr):Void {
			switch (e.expr) {
				case TWhile(cond, _, _):
					noteLoopTemps(cond);
				case TVar(v, init):
					consider(v, init);
				case TLocal(v):
					note(v);
				case TFunction(fn):
					for (arg in fn.args)
						consider(arg.v);
				case TTry(_, catches):
					for (c in catches)
						consider(c.v);
				default:
			}
			TypedExprTools.iter(e, scan);
		}
		if (arguments != null)
			for (v in arguments)
				consider(v);
		if (body != null)
			scan(body);

		for (v in candidates) {
			final base = stripLeadingUnderscores(v.name);
			if (binders.exists(v.id) && !loopTempBases.exists(base))
				continue;
			// `for (g in m.keys())`: the loop variable `var g = g.next()` keeps the name of
			// its iterator `var g = m.keys()`, as in the Haxe output.
			final iterator = nextOf.get(v.id);
			var name = iterator != null && iterator.name == v.name && renamed.exists(iterator.id) ? renamed.get(iterator.id).name : null;
			if (name == null) {
				name = 'local_$base';
				var suffix = 2;
				while (usedNames.exists(name))
					name = 'local_${base}_${suffix++}';
				usedNames.set(name, true);
			}
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

	/**
	 * Returns true when `init` only reads a Haxe temp or an enum parameter, as the
	 * declaration of a match binder does: `case Error(g)` types as `var g = _g1`.
	 */
	public static function isMatchBinderInit(init:Null<TypedExpr>):Bool {
		if (init == null)
			return false;
		return switch (init.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, null): isMatchBinderInit(inner);
			case TLocal(local): isTemp(local);
			case TEnumParameter(_, _, _): true;
			default: false;
		};
	}

	/**
	 * Returns the local `it` when `init` is the call `it.next()`, as in the loop variable
	 * `var g = g.next()` that Haxe declares for `for (g in m.keys())`; null otherwise.
	 */
	public static function iteratorOfNextCall(init:Null<TypedExpr>):Null<TVar> {
		if (init == null)
			return null;
		return switch (init.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, null): iteratorOfNextCall(inner);
			case TCall({expr: TField({expr: TLocal(it)}, field)}, []) if (fieldName(field) == "next"): it;
			default: null;
		};
	}

	static function fieldName(field:haxe.macro.Type.FieldAccess):Null<String> {
		return switch (field) {
			case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf): cf.get().name;
			case FDynamic(name): name;
			case FEnum(_, ef): ef.name;
		};
	}

	/**
	 * Returns `e` with every declaration and read of a renamed local replaced by its
	 * renamed copy from `renamesForSourceLocalsWithTempNames`. Declarations are `var`,
	 * local function arguments and `catch` variables.
	 */
	public static function applyRenames(e:Null<TypedExpr>, renamed:Map<Int, TVar>):Null<TypedExpr> {
		if (e == null || !renamed.keys().hasNext())
			return e;
		function renamedVar(v:TVar):TVar
			return v != null && renamed.exists(v.id) ? renamed.get(v.id) : v;
		function rewrite(e:TypedExpr):TypedExpr {
			return switch (e.expr) {
				case TLocal(v) if (v != null && renamed.exists(v.id)):
					{expr: TLocal(renamed.get(v.id)), pos: e.pos, t: e.t};
				case TVar(v, init) if (v != null && renamed.exists(v.id)):
					{expr: TVar(renamed.get(v.id), init == null ? null : rewrite(init)), pos: e.pos, t: e.t};
				case TFunction(fn) if (Lambda.exists(fn.args, arg -> arg.v != null && renamed.exists(arg.v.id))):
					final args = fn.args.map(arg -> {v: renamedVar(arg.v), value: arg.value == null ? null : rewrite(arg.value)});
					{expr: TFunction({args: args, t: fn.t, expr: rewrite(fn.expr)}), pos: e.pos, t: e.t};
				case TTry(tryExpr, catches) if (Lambda.exists(catches, c -> c.v != null && renamed.exists(c.v.id))):
					final renamedCatches = catches.map(c -> {v: renamedVar(c.v), expr: rewrite(c.expr)});
					{expr: TTry(rewrite(tryExpr), renamedCatches), pos: e.pos, t: e.t};
				default:
					TypedExprTools.map(e, rewrite);
			}
		}
		return rewrite(e);
	}

	static function stripLeadingUnderscores(name:String):String {
		var start = 0;
		while (start < name.length && name.charAt(start) == "_")
			start++;
		return name.substr(start);
	}
}
#end
