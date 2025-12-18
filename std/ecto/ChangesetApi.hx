package ecto;

#if (elixir || reflaxe_runtime)

import elixir.types.Term;

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
 * - Ecto changesets/params/keyword options are runtime data structures. We model that
 *   boundary as `elixir.types.Term` (opaque Elixir term) instead of leaking `Dynamic`.
 *   Prefer higher-level wrappers (e.g. `ecto.Changeset`) when you want a typed builder.
 */
@:native("Ecto.Changeset")
extern class ChangesetApi {
    @:native("change")
    public static function change(data: Term, params: Term): Term;

    @:native("cast")
    public static function castParams(data: Term, params: Term, permitted: Term): Term;

    @:native("validate_required")
    public static function validateRequired(cs: Term, fields: Term): Term;

    @:native("validate_length")
    public static function validateLength(cs: Term, field: Term, opts: Term): Term;

    @:native("validate_format")
    public static function validateFormat(cs: Term, field: Term, pattern: Term): Term;

    @:native("validate_confirmation")
    public static function validateConfirmation(cs: Term, field: Term, opts: Term = null): Term;

    @:native("unique_constraint")
    public static function uniqueConstraint(cs: Term, field: Term, opts: Term = null): Term;
}

#end
