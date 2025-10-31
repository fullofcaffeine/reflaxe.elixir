package ecto;

#if (elixir || reflaxe_runtime)

@:native("Ecto.Changeset")
extern class ChangesetApi {
    @:native("change")
    public static function change(data: Dynamic, params: Dynamic): Dynamic;

    @:native("cast")
    public static function castParams(data: Dynamic, params: Dynamic, permitted: Dynamic): Dynamic;
}

#end
