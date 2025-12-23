package elixir.types;

/**
 * Result<T, E>
 *
 * WHAT
 * - Backwards-compatible Result enum kept for older code that imported `elixir.types.Result`.
 *
 * WHY
 * - The canonical Result type for new code is `haxe.functional.Result` (annotated as Elixir-idiomatic
 *   by `reflaxe.elixir.CompilerInit.Start()`).
 * - This module remains to avoid breaking existing user code and older examples.
 *
 * HOW
 * - Prefer `import haxe.functional.Result;` in new code.
 * - This enum remains `@:elixirIdiomatic` so the AST pipeline emits Elixir tuples.
 */
@:deprecated("Use haxe.functional.Result")
@:elixirIdiomatic
enum Result<T, E = String> {
    Ok(value: T);
    Error(reason: E);
}
