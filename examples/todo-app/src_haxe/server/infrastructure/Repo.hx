package server.infrastructure;

import elixir.types.Result;
import ecto.Changeset;
import ecto.Query.EctoQuery;

/**
 * Database repository extern for TodoApp.Repo
 * 
 * ## Why This Is An Extern
 * 
 * This is an `extern class` because Ecto.Repo requires each application to define
 * its own Repo module. This is NOT provided by Phoenix or Ecto - it must be created
 * by the application itself.
 * 
 * The actual implementation lives in `lib/todo_app/repo.ex`:
 * ```elixir
 * defmodule TodoApp.Repo do
 *   use Ecto.Repo,
 *     otp_app: :todo_app,
 *     adapter: Ecto.Adapters.Postgres
 * end
 * ```
 * 
 * The `use Ecto.Repo` macro injects all the database functions (all/2, get/3, insert/2, etc.)
 * into the module. Since this is macro-heavy Elixir code that generates functions at compile-time,
 * it's more practical to use an extern than to try to generate this from Haxe.
 * 
 * ## How Static Methods Map to Elixir
 * 
 * Haxe static methods map perfectly to Elixir module functions:
 * - `Repo.all(query)` in Haxe → `TodoApp.Repo.all(query)` in Elixir
 * - `Repo.insert(changeset)` in Haxe → `TodoApp.Repo.insert(changeset)` in Elixir
 * 
 * The `@:native("TodoApp.Repo")` annotation ensures the correct module name is used
 * in the generated Elixir code.
 * 
 * ## Future Enhancement
 * 
 * Ideally, we would add `@:repo` annotation support to the compiler to auto-generate
 * the boilerplate Repo module. For now, the manual file + extern pattern works well
 * and is the recommended approach for macro-heavy Elixir modules.
 * 
 * @see https://hexdocs.pm/ecto/Ecto.Repo.html for Ecto.Repo documentation
 */
@:native("TodoApp.Repo")
extern class Repo {
    /**
     * Fetch all entries from the data store matching the given query
     * @param queryable Either an EctoQuery or a schema module
     * @return Array of records matching the query
     */
    @:overload(function<T>(query: EctoQuery<T>): Array<T> {})
    public static function all<T>(queryable: Class<T>): Array<T>;
    
    /**
     * Fetch a single entry from the data store by id
     * @param queryable The schema module
     * @param id The primary key value
     * @return The record if found, null otherwise
     */
    public static function get<T>(queryable: Class<T>, id: Int): Null<T>;
    
    /**
     * Insert a struct or changeset into the data store
     * @param changeset The changeset to insert
     * @return Ok with the inserted record, or Error with the invalid changeset
     */
    public static function insert<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    
    /**
     * Update a changeset in the data store
     * @param changeset The changeset with changes to apply
     * @return Ok with the updated record, or Error with the invalid changeset
     */
    public static function update<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    
    /**
     * Delete a struct from the data store.
     * 
     * @param struct The record to delete  
     * @return Ok with the deleted record, or Error with a changeset if constraints fail
     * 
     * WHY WE USE `{}` INSTEAD OF DYNAMIC:
     * 
     * The `{}` type represents an empty anonymous structure (a record with no fields).
     * This is the correct type for delete operations because:
     * 
     * 1. DELETE OPERATIONS HAVE NO PARAMETERS - You're removing the entire record,
     *    not updating specific fields. There's no "partial delete".
     * 
     * 2. TYPE SAFETY - Using `{}` maintains full type safety. It explicitly states
     *    "this operation accepts no parameters" rather than "anything goes" (Dynamic).
     * 
     * 3. CHANGESET CONSISTENCY - The Changeset<T, P> type expects a params type.
     *    For delete, the params are empty, so `{}` accurately represents this.
     * 
     * 4. ERROR HANDLING - If deletion fails (e.g., foreign key constraint), the
     *    returned changeset will contain constraint errors but no param validation
     *    errors (because there were no params to validate).
     * 
     * 5. SEMANTIC CORRECTNESS - `{}` communicates intent: "This operation explicitly
     *    takes no parameters." Dynamic would wrongly suggest parameters are accepted
     *    but their type is unknown.
     * 
     * In Elixir, this compiles to:
     * Repo.delete(struct) # No changeset needed for delete
     * 
     * The error changeset is only created by Ecto if constraints fail.
     */
    public static function delete<T>(struct: T): Result<T, Changeset<T, {}>>;
}