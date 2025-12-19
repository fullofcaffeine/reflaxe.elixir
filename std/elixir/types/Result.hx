package elixir.types;

/**
 * Result<T, E>
 *
 * WHAT
 * - Canonical Result type for Reflaxe.Elixir Elixir-target code.
 *
 * WHY
 * - We need a stable, idiomatic representation in Elixir: `{:ok, value}` / `{:error, reason}`.
 * - Haxe typedef aliases to enums do not reliably import enum constructors (`Ok`/`Error`) into scope,
 *   which can cause pattern matches to degrade into tag-only switches (e.g. `case 0/1`) and
 *   lose constructor parameters.
 *
 * HOW
 * - Defined as a real enum with `@:elixirIdiomatic` so the AST pipeline emits Elixir tuples.
 */
@:elixirIdiomatic
enum Result<T, E = String> {
    Ok(value: T);
    Error(reason: E);
}
