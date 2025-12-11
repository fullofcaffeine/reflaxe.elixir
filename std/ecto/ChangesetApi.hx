package ecto;

#if (elixir || reflaxe_runtime)

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
