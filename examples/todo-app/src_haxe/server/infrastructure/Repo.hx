package server.infrastructure;

import elixir.types.Result;
import ecto.Changeset;
import ecto.Query.EctoQuery;

/**
 * Database repository for TodoApp
 * 
 * This class uses @:repo annotation to generate the Ecto.Repo module,
 * then acts as an extern to reference the injected functions.
 * 
 * The @:repo annotation generates:
 * ```elixir
 * defmodule TodoApp.Repo do
 *   use Ecto.Repo, otp_app: :todo_app, adapter: Ecto.Adapters.Postgres
 * end
 * ```
 * 
 * The methods below are extern declarations that reference the functions
 * injected by the Ecto.Repo macro.
 */
@:native("TodoApp.Repo")
@:repo
extern class Repo {
    // These are extern declarations for the functions injected by Ecto.Repo
    
    @:overload(function<T>(query: EctoQuery<T>): Array<T> {})
    public static function all<T>(queryable: Class<T>): Array<T>;
    
    public static function get<T>(queryable: Class<T>, id: Int): Null<T>;
    
    public static function insert<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    
    public static function update<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    
    public static function delete<T>(struct: T): Result<T, Changeset<T, {}>>;
}