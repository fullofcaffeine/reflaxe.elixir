package ecto;

#if (elixir || reflaxe_runtime)

import elixir.Atom;

/**
 * Runtime alias so generated `Changeset.*` calls resolve to `Ecto.Changeset.*`.
 * Keeps app code free of __elixir__; alias lives in std.
 */
@:native("Changeset")
class ChangesetAliasBare {
    public static inline function castParams(data: Dynamic, params: Dynamic, permitted: Dynamic): Dynamic {
        return untyped __elixir__('Ecto.Changeset.cast({0}, {1}, {2})', data, params, permitted);
    }
    public static inline function change(data: Dynamic, params: Dynamic): Dynamic {
        return untyped __elixir__('Ecto.Changeset.change({0}, {1})', data, params);
    }
    public static inline function validateRequired(cs: Dynamic, fields: Dynamic): Dynamic {
        return untyped __elixir__('Ecto.Changeset.validate_required({0}, {1})', cs, fields);
    }
    public static inline function validateLength(cs: Dynamic, field: Dynamic, opts: Dynamic): Dynamic {
        return untyped __elixir__('Ecto.Changeset.validate_length({0}, {1}, {2})', cs, field, opts);
    }
    public static inline function validateFormat(cs: Dynamic, field: Dynamic, regex: Dynamic): Dynamic {
        return untyped __elixir__('Ecto.Changeset.validate_format({0}, {1}, {2})', cs, field, regex);
    }
    public static inline function validateConfirmation(cs: Dynamic, field: Dynamic, opts: Dynamic = null): Dynamic {
        return opts == null
            ? untyped __elixir__('Ecto.Changeset.validate_confirmation({0}, {1})', cs, field)
            : untyped __elixir__('Ecto.Changeset.validate_confirmation({0}, {1}, {2})', cs, field, opts);
    }
    public static inline function uniqueConstraint(cs: Dynamic, field: Dynamic, opts: Dynamic = null): Dynamic {
        return opts == null
            ? untyped __elixir__('Ecto.Changeset.unique_constraint({0}, {1})', cs, field)
            : untyped __elixir__('Ecto.Changeset.unique_constraint({0}, {1}, {2})', cs, field, opts);
    }

    public static inline function __marker__(): Dynamic {
        return untyped __elixir__(':reflaxe_std_changeset_alias');
    }
}

#end
