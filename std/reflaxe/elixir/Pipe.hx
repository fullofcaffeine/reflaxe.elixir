package reflaxe.elixir;

/**
 * Typed Haxe authoring helper for Elixir-style dataflow.
 *
 * WHAT
 * - Wraps a value so Haxe can type-check a `>>` chain that reads left-to-right.
 *
 * WHY
 * - Elixir's `|>` operator is not valid Haxe syntax, so macros cannot make
 *   `params |> Map.get("id")` parse as Haxe source.
 * - Boundary code often reads better as a dataflow pipeline than as nested
 *   calls, especially when a runtime `Term` is narrowed into a domain type.
 *
 * HOW
 * - Start a chain with `value.pipe()` after `using reflaxe.elixir.Pipe`, or
 *   with `Pipe.of(value)` when you do not want a `using` import.
 * - Each `>> step` applies a unary function to the previous value.
 * - The final `Pipe<T>` converts back to `T` in typed positions; call
 *   `.value()` when an explicit unwrap is clearer.
 *
 * EXAMPLES
 * ```haxe
 * using reflaxe.elixir.Pipe;
 *
 * var id:Null<ResourceId> = params.pipe()
 *   >> (p -> ElixirMap.get(p, "resource_id"))
 *   >> Params.stringFromTerm
 *   >> ResourceIds.fromParam;
 * ```
 */
abstract Pipe<T>(T) from T to T {
	public inline function new(value:T) {
		this = value;
	}

	/**
	 * Starts a pipe chain without enabling static extension methods.
	 */
	@:noUsing
	public static inline function of<T>(value:T):Pipe<T> {
		return new Pipe(value);
	}

	/**
	 * Starts a pipe chain when `using reflaxe.elixir.Pipe` is in scope.
	 */
	public static inline function pipe<T>(value:T):Pipe<T> {
		return new Pipe(value);
	}

	/**
	 * Applies the next unary step in a typed pipe chain.
	 */
	@:op(A >> B)
	public static inline function then<T, U>(value:Pipe<T>, step:T->U):Pipe<U> {
		return new Pipe(step((value : T)));
	}

	/**
	 * Explicitly unwraps the final pipe value.
	 */
	public inline function value():T {
		return this;
	}
}
