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
 * - Before the builders run, `renamesForSourceLocalsWithTempNames` moves every program
 *   local out of the temp names (`g` -> `local_g`). After that, a name check such as
 *   "`g` is a temp" downstream is true for the locals that reach it.
 *
 * EXAMPLES (Haxe 4.3.7, as the compiler sees them after Haxe's filters)
 * - `var g = [];`                  -> name `g`,  `@:realPath("g")`           -> source local
 * - `for (k => v in m)` iterator   -> name `_g`, `@:realPath("_g")`, `@:realPath("\`")` -> temp
 * - `var _g = 1;` written by hand  -> name `_g`, `@:realPath("_g")`          -> source local
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
	 *   (`g`, `g1`, `_g`, `_g2`, ...), it gets the name `local_g` (`local_g1`, ...).
	 *   The leading underscores go: `var _g` also becomes `local_g`.
	 * - This applies to every kind of declaration: `var`, the function's own
	 *   arguments (`arguments`), the arguments of a local function, and `catch`
	 *   variables. Loop variables are `var` declarations by this stage.
	 * - It applies whether or not the function also has a Haxe temp. The rename does
	 *   not depend on what else is in the function.
	 * - One exception keeps a common pattern readable. A match binder
	 *   (`case RGB(r, g, b)` types as `var g = _g1`, see `isMatchBinderInit`) keeps its
	 *   name, unless a loop condition in the same function reads a temp with the same
	 *   base name. Its case pattern binds it, and `{:rgb, r, g, b}` reads better than
	 *   `{:rgb, r, local_g, b}`.
	 * - A name that the function already uses is skipped (`local_g_2` is next). The
	 *   names in `argumentNames` (Elixir form) always count as used. The copy keeps
	 *   the ID, so ID-keyed tracking is unchanged.
	 * - Call it on the body that the builders compile, after
	 *   `TypedExprPreprocessor.preprocess`.
	 *
	 * WHY
	 * - Many builder paths and ElixirAST passes decide by name alone that a local is
	 *   a Haxe temp: `g`, `_g` and `g1` are temps there. After this rename, only Haxe
	 *   temps have those names, so those checks are correct by construction. Before
	 *   it, a program local with such a name could be silently miscompiled:
	 *   - `var g = x * 2; var h = 0; if (c) { g = 1; h = 2; } else { h = g; }` lost
	 *     `h = g`, with no temp in the function at all;
	 *   - an argument `g` next to `for (i in 0...n)` was overwritten by the loop
	 *     counter `_g = 0`, which a hygiene pass promotes to `g` when it sees `g` read;
	 *   - a program local `_g` read after a loop was rewritten to `g`, an undefined
	 *     variable in Elixir.
	 * - The temps keep their names because many passes recognise temps by them.
	 */
	public static function renamesForSourceLocalsWithTempNames(body:Null<TypedExpr>, ?argumentNames:Array<String>, ?arguments:Array<TVar>):Map<Int, TVar> {
		final renamed = new Map<Int, TVar>();
		final loopTempBases = new Map<String, Bool>();
		final binders = new Map<Int, Bool>();
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
			var name = 'local_$base';
			var suffix = 2;
			while (usedNames.exists(name))
				name = 'local_${base}_${suffix++}';
			usedNames.set(name, true);
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
