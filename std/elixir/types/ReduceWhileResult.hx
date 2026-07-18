package elixir.types;

/**
 * Result type for `Enum.reduce_while/3` callbacks.
 *
 * `Cont(value)` maps to `{:cont, value}` and continues the reduction;
 * `Halt(value)` maps to `{:halt, value}` and returns the accumulator.
 * The type lives in its own module so importing the native `elixir.Enum`
 * extern does not emit this carrier when no callback uses it.
 */
@:native("Elixir.ReduceWhileResult")
enum ReduceWhileResult<T> {
	/** Continue reducing with the given accumulator value. */
	Cont(value:T);

	/** Halt reduction and return the given accumulator value. */
	Halt(value:T);
}
