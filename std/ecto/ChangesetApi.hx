package ecto;

#if (elixir || reflaxe_runtime)

/**
 * ChangesetApi
 *
 * WHAT
 * - Low-level extern mapping to the canonical Elixir module `Ecto.Changeset`.
 *
 * WHY
 * - Ecto is an Elixir library, so Haxe code needs externs at the boundary.
 * - This is the “no string injection” option: it calls `Ecto.Changeset.*` via `@:native`
 *   instead of `untyped __elixir__()`.
 *
 * HOW
 * - Methods are declared as externs and map directly to the Elixir function names.
 * - Types are `Dynamic` at this boundary because Ecto changesets/params/keyword options
 *   are runtime data structures that are not modeled as a fully-typed Haxe API (yet).
 *   Prefer higher-level wrappers (e.g. `ecto.Changeset`) when you want a typed builder.
 */
@:native("Ecto.Changeset")
extern class ChangesetApi {
    @:native("change")
    public static function change(data: Dynamic, params: Dynamic): Dynamic;

    @:native("cast")
    public static function castParams(data: Dynamic, params: Dynamic, permitted: Dynamic): Dynamic;

    @:native("validate_required")
    public static function validateRequired(cs: Dynamic, fields: Dynamic): Dynamic;

    @:native("validate_length")
    public static function validateLength(cs: Dynamic, field: Dynamic, opts: Dynamic): Dynamic;

    @:native("validate_format")
    public static function validateFormat(cs: Dynamic, field: Dynamic, pattern: Dynamic): Dynamic;

    @:native("validate_confirmation")
    public static function validateConfirmation(cs: Dynamic, field: Dynamic, opts: Dynamic = null): Dynamic;

    @:native("unique_constraint")
    public static function uniqueConstraint(cs: Dynamic, field: Dynamic, opts: Dynamic = null): Dynamic;
}

#end
