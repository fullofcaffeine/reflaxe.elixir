package ecto;

#if (elixir || reflaxe_runtime)

import elixir.Atom;
import elixir.types.Term;
import ecto.Changeset;

/**
 * ChangesetBridge
 *
 * WHAT
 * - Thin wrapper around `Ecto.Changeset` that keeps `untyped __elixir__()` calls inside
 *   the stdlib, so application code stays “pure Haxe” while still calling the canonical
 *   Ecto API.
 *
 * WHY
 * - Ecto is an Elixir library. Any Haxe→Elixir integration needs externs at the boundary.
 * - Some Ecto ergonomics (notably idiomatic `|>` pipelines, sigils like `~r//`, and keyword
 *   lists in options) are currently simplest to emit via `__elixir__()` without leaking raw
 *   Elixir strings into user code.
 * - This wrapper centralizes that escape hatch in one place, so apps can stay readable and
 *   portable while still generating hand-written-looking Elixir.
 *
 * HOW
 * - `castParams` / `validate*` / `change` forward to `Ecto.Changeset.*` using the fully-qualified
 *   module name.
 * - `registration` / `update` / `password` provide a small opinionated surface used by the
 *   example todo-app.
 *
 * EXAMPLES
 * Haxe:
 *   CS.registration(user, params);
 *
 * Elixir (generated):
 *   user
 *   |> Ecto.Changeset.cast(params, [:name, :email, :password, :password_confirmation])
 *   |> Ecto.Changeset.validate_required([:name, :email, :password])
 *   |> Ecto.Changeset.validate_format(:email, ~r/.../)
 */
@:native("Ecto.ChangesetBridge")
class ChangesetBridge {
    public static function castParams<T, P>(data: T, params: P, permitted: Array<Atom>): Changeset<T, P> {
        return cast untyped __elixir__('Ecto.Changeset.cast({0}, {1}, {2})', data, params, permitted);
    }

    public static function validateRequired<T, P>(cs: Changeset<T, P>, fields: Array<Atom>): Changeset<T, P> {
        return cast untyped __elixir__('Ecto.Changeset.validate_required({0}, {1})', cs, fields);
    }

    public static function validateLength<T, P>(cs: Changeset<T, P>, field: Atom, opts: Term): Changeset<T, P> {
        return cast untyped __elixir__('Ecto.Changeset.validate_length({0}, {1}, {2})', cs, field, opts);
    }

    public static function validateFormat<T, P>(cs: Changeset<T, P>, field: Atom, regex: Term): Changeset<T, P> {
        return cast untyped __elixir__('Ecto.Changeset.validate_format({0}, {1}, {2})', cs, field, regex);
    }

    public static function validateConfirmation<T, P>(cs: Changeset<T, P>, field: Atom, ?opts: Term): Changeset<T, P> {
        return opts == null
            ? cast untyped __elixir__('Ecto.Changeset.validate_confirmation({0}, {1})', cs, field)
            : cast untyped __elixir__('Ecto.Changeset.validate_confirmation({0}, {1}, {2})', cs, field, opts);
    }

    public static function uniqueConstraint<T, P>(cs: Changeset<T, P>, field: Atom, ?opts: Term): Changeset<T, P> {
        return opts == null
            ? cast untyped __elixir__('Ecto.Changeset.unique_constraint({0}, {1})', cs, field)
            : cast untyped __elixir__('Ecto.Changeset.unique_constraint({0}, {1}, {2})', cs, field, opts);
    }

    public static function change<T, P>(data: T, params: P): Changeset<T, P> {
        return cast untyped __elixir__('Ecto.Changeset.change({0}, {1})', data, params);
    }

    public static function registration<TUser, P>(user: TUser, params: P): Changeset<TUser, P> {
        return cast untyped __elixir__('
            {0}
            |> Ecto.Changeset.cast({1}, [:name, :email, :password, :password_confirmation])
            |> Ecto.Changeset.validate_required([:name, :email, :password])
            |> Ecto.Changeset.validate_format(:email, ~r/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/)
            |> Ecto.Changeset.validate_length(:password, min: 8, max: 128)
            |> Ecto.Changeset.validate_confirmation(:password)
            |> Ecto.Changeset.unique_constraint(:email)
        ', user, params);
    }

    public static function update<TUser, P>(user: TUser, params: P): Changeset<TUser, P> {
        return cast untyped __elixir__('
            {0}
            |> Ecto.Changeset.cast({1}, [:name, :email, :bio])
            |> Ecto.Changeset.validate_required([:name, :email])
            |> Ecto.Changeset.validate_length(:name, min: 2, max: 100)
            |> Ecto.Changeset.validate_length(:bio, max: 280)
            |> Ecto.Changeset.validate_format(:email, ~r/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/)
            |> Ecto.Changeset.unique_constraint(:email)
        ', user, params);
    }

    public static function password<TUser, P>(user: TUser, params: P): Changeset<TUser, P> {
        return cast untyped __elixir__('
            {0}
            |> Ecto.Changeset.cast({1}, [:password, :password_confirmation])
            |> Ecto.Changeset.validate_required([:password])
            |> Ecto.Changeset.validate_length(:password, min: 8, max: 128)
            |> Ecto.Changeset.validate_confirmation(:password)
        ', user, params);
    }
}

#end
