package server.infrastructure;

import elixir.types.Result;

/**
 * TodoApp database repository
 * Ecto.Repo for the TodoApp application
 */
@:native("TodoApp.Repo")
extern class Repo {
    // Provide typed interface for Haxe code
    public static function all<T>(query: Dynamic): Array<T>;
    public static function insert<T>(changeset: Dynamic): Result<T, String>;
    public static function update<T>(changeset: Dynamic): Result<T, String>;
    public static function delete<T>(entity: T): Result<T, String>;
    public static function get<T>(schema: Dynamic, id: Int): Null<T>;
    
    @:native("get!")
    public static function get_not_null<T>(schema: Dynamic, id: Int): T;
}