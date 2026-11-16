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
	 * Picks a new name for each program local that shares its name with a Haxe temp
	 * of the same function: `g` becomes `local_g`. Returns the renamed `TVar` copies by
	 * ID; apply them with `applyRenames`.
	 *
	 * WHAT
	 * - When the program declares a local such as `g` or `g1` with `var`, and the body
	 *   still declares a Haxe temp with that name, with or without the leading
	 *   underscore, the program local gets the name `local_g` (`local_g1`, ...). The
	 *   copy keeps the ID, so ID-keyed tracking is unchanged.
	 * - For a plain local, every temp that is still declared counts: a loop counter or
	 *   iterator (`_g < _g1`, `_g.hasNext()`), and also the subject of a switch on a
	 *   computed value (`var _g = s.toUpperCase(); switch (_g)`).
	 * - For a match binder (`case RGB(r, g, b)` types as `var g = _g1`, see
	 *   `isMatchBinderInit`), only a temp that a loop condition reads counts. The case
	 *   pattern binds it, so the subject temp of its own switch does not clash with it,
	 *   and `case RGB(r, g, b)` keeps `g`.
	 * - A name that the function already uses is skipped (`local_g_2` is next). The
	 *   enclosing function's argument names (`argumentNames`, in Elixir form) always
	 *   count as used, read or not. Function arguments and `catch` variables keep
	 *   their names.
	 * - Call it on the body that the builders compile, after
	 *   `TypedExprPreprocessor.preprocess`: a temp that the preprocessor replaced by
	 *   its value is gone and does not count.
	 *
	 * WHY
	 * - Elixir treats `_g` as the unused spelling of `g`, and hygiene passes promote
	 *   `_g` to `g` when `g` is read later. With a program `g` and the counter `_g` of
	 *   a `for (i in 0...n)` loop in one function, the counter took the name `g` and
	 *   overwrote the program local: the loop appended to `0` (`:erlang.++(0, [0])`).
	 *   With two `for (k => v in m)` loops, the program `g` and the iterator temp `_g`
	 *   shared one name, and `g.key` read the wrong value.
	 *   A switch subject temp behaves the same way: `var g = "pre"` followed by
	 *   `switch (s.toUpperCase())` overwrote `g` with the subject.
	 * - The temps keep their names because many passes recognise temps by them.
	 */
	public static function renamesForSourceLocalsSharingTempNames(body:Null<TypedExpr>, ?argumentNames:Array<String>):Map<Int, TVar> {
		final renamed = new Map<Int, TVar>();
		if (body == null)
			return renamed;
		final tempBases = new Map<String, Bool>();
		final loopTempBases = new Map<String, Bool>();
		final binders = new Map<Int, Bool>();
		final usedNames = new Map<String, Bool>();
		final candidates:Array<TVar> = [];
		final seen = new Map<Int, Bool>();
		if (argumentNames != null)
			for (name in argumentNames)
				usedNames.set(name, true);
		function note(v:TVar):Void {
			if (v == null || v.name == null)
				return;
			usedNames.set(ElixirNaming.toVarName(v.name), true);
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
					note(v);
					if (isTemp(v))
						tempBases.set(stripLeadingUnderscores(v.name), true);
					if (v != null && !seen.exists(v.id) && TEMP_NAME.match(v.name) && isSourceLocal(v)) {
						seen.set(v.id, true);
						candidates.push(v);
						if (isMatchBinderInit(init))
							binders.set(v.id, true);
					}
				case TLocal(v):
					note(v);
				case TFunction(fn):
					for (arg in fn.args)
						note(arg.v);
				case TTry(_, catches):
					for (c in catches)
						note(c.v);
				default:
			}
			TypedExprTools.iter(e, scan);
		}
		scan(body);

		for (v in candidates) {
			final base = stripLeadingUnderscores(v.name);
			if (!(binders.exists(v.id) ? loopTempBases : tempBases).exists(base))
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
	 * renamed copy from `renamesForSourceLocalsSharingTempNames`.
	 */
	public static function applyRenames(e:Null<TypedExpr>, renamed:Map<Int, TVar>):Null<TypedExpr> {
		if (e == null || !renamed.keys().hasNext())
			return e;
		function rewrite(e:TypedExpr):TypedExpr {
			return switch (e.expr) {
				case TLocal(v) if (v != null && renamed.exists(v.id)):
					{expr: TLocal(renamed.get(v.id)), pos: e.pos, t: e.t};
				case TVar(v, init) if (v != null && renamed.exists(v.id)):
					{expr: TVar(renamed.get(v.id), init == null ? null : rewrite(init)), pos: e.pos, t: e.t};
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
