package server.infrastructure;

/**
 * TodoApp database repository
 * Ecto.Repo for the TodoApp application
 */
@:native("TodoApp.Repo")
extern class Repo {
    // Provide typed interface for Haxe code
    public static function all(query: Dynamic): Array<Dynamic>;
    public static function insert(changeset: Dynamic): Dynamic;
    public static function update(changeset: Dynamic): Dynamic;
    public static function delete(entity: Dynamic): Dynamic;
    public static function get(schema: Dynamic, id: Int): Dynamic;
    
    @:native("get!")
    public static function get_not_null(schema: Dynamic, id: Int): Dynamic;
}