package server.infrastructure;

import elixir.types.Result;
import ecto.Changeset;
import ecto.Query.EctoQuery;
import ecto.DatabaseAdapter.*;

/**
 * Database repository for TodoApp
 * 
 * This class uses @:repo annotation with typed configuration to generate:
 * 1. The Ecto.Repo module with proper adapter settings
 * 2. A companion PostgrexTypes module for JSON encoding/decoding
 * 
 * The typed configuration ensures compile-time validation and
 * automatic generation of all required database modules.
 * 
 * Generated Elixir:
 * ```elixir
 * defmodule TodoApp.Repo do
 *   use Ecto.Repo, otp_app: :todo_app, adapter: Ecto.Adapters.Postgres
 * end
 * 
 * defmodule TodoApp.PostgrexTypes do
 *   Postgrex.Types.define(TodoApp.PostgrexTypes, [], json: Jason)
 * end
 * ```
 */
@:native("TodoApp.Repo")
@:repo({
    adapter: Postgres,
    json: Jason,
    extensions: [],
    poolSize: 10
})
extern class Repo {
    // These are extern declarations for the functions injected by Ecto.Repo
    
    @:overload(function<T>(query: EctoQuery<T>): Array<T> {})
    @:overload(function<T>(query: ecto.TypedQuery.TypedQuery<T>): Array<T> {})
    public static function all<T>(queryable: Class<T>): Array<T>;
    
    public static function get<T>(queryable: Class<T>, id: Int): Null<T>;
    
    public static function insert<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    
    public static function update<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    
    public static function delete<T>(struct: T): Result<T, Changeset<T, {}>>;
}
