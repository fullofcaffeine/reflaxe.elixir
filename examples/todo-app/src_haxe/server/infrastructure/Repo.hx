package server.infrastructure;

import phoenix.Ecto.Query;
import phoenix.Ecto.Changeset;
import phoenix.Ecto.QueryConditions;
import haxe.functional.Result;

/**
 * TodoApp database repository
 * Provides type-safe database access using Ecto patterns
 * 
 * This module is compiled to TodoApp.Repo with proper Ecto.Repo usage
 * and PostgreSQL adapter configuration for the todo-app application.
 * 
 * ## Directory Structure Note
 * 
 * This file is located in `server/infrastructure/` which differs from Phoenix conventions.
 * Standard Phoenix would place this directly under the app namespace (TodoApp.Repo).
 * 
 * We use the @:native("TodoApp.Repo") annotation to ensure the generated module follows
 * Phoenix conventions regardless of the Haxe package structure. This allows us to organize
 * our Haxe code with more explicit architectural boundaries (infrastructure, domain, etc.)
 * while still generating idiomatic Phoenix/Elixir modules.
 * 
 * Phoenix convention: lib/todo_app/repo.ex
 * Our structure: server/infrastructure/Repo.hx → compiles to → lib/todo_app/repo.ex
 */
@:native("TodoApp.Repo")
@:repo
@:appName("TodoApp")
extern class Repo {
    /**
     * Get a single record by primary key
     */
    static function get<T>(queryable: Class<T>, id: Int): Null<T>;
    
    /**
     * Get a single record by primary key, raise if not found
     */
    static function get_by<T>(queryable: Class<T>, conditions: QueryConditions): Null<T>;
    
    /**
     * Get all records matching a query
     */
    static function all<T>(query: Query<T>): Array<T>;
    
    /**
     * Get the first record matching a query
     */
    static function one<T>(query: Query<T>): Null<T>;
    
    /**
     * Get the first record matching a query, raise if not found
     */
    static function one_not_null<T>(query: Query<T>): T;
    
    /**
     * Check if any records exist for a query
     */
    static function exists<T>(query: Query<T>): Bool;
    
    /**
     * Insert a new record
     */
    static function insert<T>(changeset: Changeset<T>): Result<T, ChangesetError>;
    
    /**
     * Insert a new record, raise on error
     */
    static function insert_not_null<T>(changeset: Changeset<T>): T;
    
    /**
     * Update an existing record
     */
    static function update<T>(changeset: Changeset<T>): Result<T, ChangesetError>;
    
    /**
     * Update an existing record, raise on error
     */
    static function update_not_null<T>(changeset: Changeset<T>): T;
    
    /**
     * Delete a record
     */
    static function delete<T>(record: T): Result<T, ChangesetError>;
    
    /**
     * Delete a record, raise on error
     */
    static function delete_not_null<T>(record: T): T;
    
    /**
     * Preload associations on a record or list of records
     */
    static function preload<T>(record: T, associations: Array<String>): T;
    
    /**
     * Run operations in a transaction
     */
    static function transaction<T>(fun: () -> Result<T, String>): Result<T, String>;
    
    /**
     * Rollback a transaction with a specific error value
     */
    static function rollback<E>(value: E): E;
}

/**
 * Error type for changeset operations
 */
typedef ChangesetError = {
    var errors: Array<{field: String, message: String}>;
    var action: String;
}