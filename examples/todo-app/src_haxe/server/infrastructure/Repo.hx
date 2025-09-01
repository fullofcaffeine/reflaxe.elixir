package server.infrastructure;

import phoenix.Ecto.Query;
import phoenix.Ecto.Changeset;
import haxe.functional.Result;

/**
 * TodoApp database repository
 * External declaration for the Ecto.Repo module
 */
@:native("TodoApp.Repo")
extern class Repo {
    /**
     * Get all records matching a query
     */
    public static function all<T>(query: Query<T>): Array<T>;
    
    /**
     * Insert a new record
     */
    public static function insert<T>(changeset: Changeset<T>): Result<T, Dynamic>;
    
    /**
     * Update an existing record
     */
    public static function update<T>(changeset: Changeset<T>): Result<T, Dynamic>;
    
    /**
     * Delete a record
     */
    public static function delete<T>(record: T): Result<T, Dynamic>;
    
    /**
     * Get a single record by primary key
     */
    public static function get<T>(queryable: Class<T>, id: Int): Null<T>;
    
    /**
     * Get a single record by primary key, raise if not found
     */
    @:native("get!")
    public static function get_not_null<T>(queryable: Class<T>, id: Int): T;
}