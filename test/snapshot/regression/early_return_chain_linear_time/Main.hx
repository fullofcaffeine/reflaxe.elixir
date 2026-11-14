/** The result of one step: a value, or the reason why the step stopped. */
enum Outcome<T, E> {
	Ok(value:T);
	Err(error:E);
}

/**
 * Regression for haxe.elixir.codex-ryt: a function that returns early on each error.
 *
 * Each `switch` below becomes one Elixir `case` nested in the `Ok` branch of the
 * previous one. Compile time must grow with the number of steps, not double (or
 * worse) with each step. `runtime.exs` checks the returned values independently.
 */
@:keep
class Main {
	static function main():Void {}

	/** Adds one to `n`, or stops when `n` is the step that the caller asked to fail. */
	static function step(n:Int, failAt:Int):Outcome<Int, String>
		return n == failAt ? Err("stopped at " + n) : Ok(n + 1);

	/** Runs every step in order and returns the first error, or the final count. */
	public static function chain(start:Int, failAt:Int):Outcome<Int, String> {
		final a1 = switch step(start, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a2 = switch step(a1, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a3 = switch step(a2, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a4 = switch step(a3, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a5 = switch step(a4, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a6 = switch step(a5, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a7 = switch step(a6, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a8 = switch step(a7, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a9 = switch step(a8, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a10 = switch step(a9, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a11 = switch step(a10, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a12 = switch step(a11, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a13 = switch step(a12, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a14 = switch step(a13, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a15 = switch step(a14, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a16 = switch step(a15, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a17 = switch step(a16, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a18 = switch step(a17, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a19 = switch step(a18, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a20 = switch step(a19, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a21 = switch step(a20, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a22 = switch step(a21, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a23 = switch step(a22, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final a24 = switch step(a23, failAt) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		return Ok(a24);
	}
}
