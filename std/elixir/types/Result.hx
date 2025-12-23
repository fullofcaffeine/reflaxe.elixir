package elixir.types;

/**
 * Result<T, E>
 *
 * WHAT
 * - Deprecated alias kept for older code that imported `elixir.types.Result`.
 *
 * WHY
 * - The canonical Result type for new code is `haxe.functional.Result` (annotated as Elixir-idiomatic
 *   by `reflaxe.elixir.CompilerInit.Start()`).
 * - This alias remains to avoid breaking existing user code and older examples.
 *
 * HOW
 * - Prefer `import haxe.functional.Result;` in new code.
 * - Prefer `using haxe.functional.ResultTools;` for functional helpers (map/flatMap/fold).
 */
@:deprecated("Use haxe.functional.Result")
typedef Result<T, E = String> = haxe.functional.Result<T, E>;
