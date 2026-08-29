package haxe.ds;

/**
 * ListSort (Elixir target override) - explicit unsupported runtime surface.
 *
 * WHAT
 * - Preserves the upstream static method signatures so code type-checks far
 *   enough for the Elixir backend to issue a clear diagnostic.
 *
 * WHY
 * - Upstream `ListSort` mutates arbitrary linked-node `next`/`prev` fields in
 *   place. Ordinary BEAM structs and maps are immutable values, so lowering
 *   that API silently would produce misleading code.
 *
 * HOW
 * - Macro/eval contexts use `haxe/ds/ListSort.macro.hx`.
 * - Runtime calls are extern and are rejected by `CallExprBuilder` with an
 *   actionable target diagnostic.
 */
@:nativeGen
extern class ListSort {
	public static function sort<T:{prev:T, next:T}>(list:T, cmp:T->T->Int):T;
	public static function sortSingleLinked<T:{next:T}>(list:T, cmp:T->T->Int):T;
}
