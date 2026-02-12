package;

/**
 * Regression: `-dce full` must not eliminate annotation-only `@:native("Elixir.Module")` classes
 * that are required at runtime but referenced only indirectly.
 *
 * This snapshot forces typing the module via a macro (simulating “indirect runtime reference”),
 * then asserts the module is still emitted under `-dce full`.
 */
class Main {
	static function main() {}
}
