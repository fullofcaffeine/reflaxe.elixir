package ecto;

#if (elixir || reflaxe_runtime)

import elixir.types.Result;
import ecto.Query.EctoQuery;
import ecto.Changeset;

/**
 * Type-safe Repository pattern for Ecto database operations
 * 
 * ## Overview
 * 
 * This provides a type-safe abstraction over Ecto.Repo operations with
 * compile-time validation and better ergonomics for Haxe developers.
 * 
 * ## Architecture
 * 
 * The Repository pattern separates database concerns from business logic:
 * - **Repository**: Handles all database operations
 * - **Schema**: Defines data structure and validations
 * - **Context**: Contains business logic using repositories
 * 
 * ## Usage Example
 * 
 * ```haxe
 * // Define your repository
 * @:repo({adapter: Postgres})
 * class MyRepo extends Repository {}
 * 
 * // Use it with type safety
 * class UserContext {
 *     public static function createUser(params: UserParams): Result<User, Changeset<User, UserParams>> {
 *         var changeset = User.changeset(new User(), params);
 *         return MyRepo.insert(changeset);
 *     }
 *     
 *     public static function findUser(id: Int): Null<User> {
 *         return MyRepo.get(User, id);
 *     }
 *     
 *     public static function listActiveUsers(): Array<User> {
 *         var query = from(User)
 *             .where(u -> u.active == true)
 *             .orderBy(u -> u.createdAt, :desc);
 *         return MyRepo.all(query);
 *     }
 * }
 * ```
 * 
 * ## Generated Elixir
 * 
 * ```elixir
 * defmodule MyRepo do
 *   use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres
 * end
 * 
 * defmodule UserContext do
 *   def create_user(params) do
 *     %User{}
 *     |> User.changeset(params)
 *     |> MyRepo.insert()
 *   end
 *   
 *   def find_user(id), do: MyRepo.get(User, id)
 *   
 *   def list_active_users do
 *     from(u in User,
 *       where: u.active == true,
 *       order_by: [desc: u.inserted_at]
 *     )
 *     |> MyRepo.all()
 *   end
 * end
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Compile-time validation**: Schema types are validated at compile time
 * - **IDE support**: Full autocomplete for fields and methods
 * - **Refactoring safety**: Rename fields across entire codebase
 * - **Type inference**: Return types are automatically inferred
 * 
 * ## Advanced Features
 * 
 * ### Transactions
 * ```haxe
 * MyRepo.transaction(function() {
 *     var user = MyRepo.insert!(User.changeset(new User(), params));
 *     var profile = MyRepo.insert!(Profile.changeset(new Profile(), {userId: user.id}));
 *     return {user: user, profile: profile};
 * });
 * ```
 * 
 * ### Preloading Associations
 * ```haxe
 * var users = MyRepo.all(User);
 * users = MyRepo.preload(users, [:posts, :comments]);
 * ```
 * 
 * ### Aggregates
 * ```haxe
 * var count = MyRepo.aggregate(User, :count, :id);
 * var avgAge = MyRepo.aggregate(User, :avg, :age);
 * ```
 * 
 * @see ecto.Schema For defining database schemas
 * @see ecto.Changeset For data validation
 * @see ecto.Query For building queries
 */
@:autoBuild(reflaxe.elixir.macros.RepositoryBuilder.build())
class Repository {
    
    /**
     * Fetches all entries from the data store matching the given query
     * 
     * @param queryable Either a Schema class or a Query
     * @return Array of matching records
     */
    @:generic
    public static function all<T>(queryable: Dynamic): Array<T> {
        return untyped __elixir__('{0}.all({1})', getSelf(), queryable);
    }
    
    /**
     * Fetches a single struct from the data store by id
     * 
     * @param queryable The schema module
     * @param id The primary key value
     * @return The struct or null if not found
     */
    @:generic
    public static function get<T>(queryable: Class<T>, id: Dynamic): Null<T> {
        return untyped __elixir__('{0}.get({1}, {2})', getSelf(), queryable, id);
    }
    
    /**
     * Fetches a single struct from the data store by id, raises if not found
     * 
     * @param queryable The schema module
     * @param id The primary key value
     * @return The struct
     * @throws Ecto.NoResultsError if no record found
     */
    @:generic
    public static function get_<T>(queryable: Class<T>, id: Dynamic): T {
        return untyped __elixir__('{0}.get!({1}, {2})', getSelf(), queryable, id);
    }
    
    /**
     * Fetches a single result from the query
     * 
     * @param query The query
     * @return The struct or null if not found
     */
    @:generic
    public static function one<T>(query: EctoQuery<T>): Null<T> {
        return untyped __elixir__('{0}.one({1})', getSelf(), query);
    }
    
    /**
     * Fetches a single result from the query, raises if not found
     * 
     * @param query The query
     * @return The struct
     * @throws Ecto.NoResultsError if no record found
     */
    @:generic
    public static function one_<T>(query: EctoQuery<T>): T {
        return untyped __elixir__('{0}.one!({1})', getSelf(), query);
    }
    
    /**
     * Inserts a struct or changeset
     * 
     * @param struct_or_changeset The struct or changeset to insert
     * @return Ok with the inserted struct or Error with the invalid changeset
     */
    @:generic
    public static function insert<T, P>(struct_or_changeset: Dynamic): Result<T, Changeset<T, P>> {
        return untyped __elixir__('{0}.insert({1})', getSelf(), struct_or_changeset);
    }
    
    /**
     * Inserts a struct or changeset, raises on error
     * 
     * @param struct_or_changeset The struct or changeset to insert
     * @return The inserted struct
     * @throws Ecto.InvalidChangesetError if changeset is invalid
     */
    @:generic
    public static function insert_<T>(struct_or_changeset: Dynamic): T {
        return untyped __elixir__('{0}.insert!({1})', getSelf(), struct_or_changeset);
    }
    
    /**
     * Updates a changeset
     * 
     * @param changeset The changeset with changes
     * @return Ok with the updated struct or Error with the invalid changeset
     */
    @:generic
    public static function update<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>> {
        return untyped __elixir__('{0}.update({1})', getSelf(), changeset);
    }
    
    /**
     * Updates a changeset, raises on error
     * 
     * @param changeset The changeset with changes
     * @return The updated struct
     * @throws Ecto.InvalidChangesetError if changeset is invalid
     */
    @:generic
    public static function update_<T>(changeset: Dynamic): T {
        return untyped __elixir__('{0}.update!({1})', getSelf(), changeset);
    }
    
    /**
     * Deletes a struct
     * 
     * @param struct The struct to delete
     * @return Ok with the deleted struct or Error with the changeset
     */
    @:generic
    public static function delete<T>(struct: T): Result<T, Changeset<T, {}>> {
        return untyped __elixir__('{0}.delete({1})', getSelf(), struct);
    }
    
    /**
     * Deletes a struct, raises on error
     * 
     * @param struct The struct to delete
     * @return The deleted struct
     * @throws Ecto.InvalidChangesetError if deletion fails
     */
    @:generic
    public static function delete_<T>(struct: T): T {
        return untyped __elixir__('{0}.delete!({1})', getSelf(), struct);
    }
    
    /**
     * Deletes all entries matching the given query
     * 
     * @param queryable The query specifying entries to delete
     * @return Tuple with number of deleted entries and nil
     */
    @:generic
    public static function deleteAll<T>(queryable: Dynamic): {deleted: Int, data: Null<T>} {
        return untyped __elixir__('{0}.delete_all({1})', getSelf(), queryable);
    }
    
    /**
     * Updates all entries matching the given query
     * 
     * @param queryable The query specifying entries to update
     * @param updates The updates to apply
     * @return Tuple with number of updated entries and nil
     */
    public static function updateAll(queryable: Dynamic, updates: Dynamic): {updated: Int, data: Dynamic} {
        return untyped __elixir__('{0}.update_all({1}, {2})', getSelf(), queryable, updates);
    }
    
    /**
     * Preloads associations on structs
     * 
     * @param structs_or_struct The struct(s) to preload on
     * @param preloads List of associations to preload
     * @return The struct(s) with preloaded associations
     */
    @:generic
    public static function preload<T>(structs_or_struct: Dynamic, preloads: Dynamic): T {
        return untyped __elixir__('{0}.preload({1}, {2})', getSelf(), structs_or_struct, preloads);
    }
    
    /**
     * Calculates an aggregate over the given query
     * 
     * @param queryable The query
     * @param aggregate The aggregate operation (:count, :sum, :avg, :min, :max)
     * @param field The field to aggregate (optional for :count)
     * @return The aggregate value
     */
    public static function aggregate(queryable: Dynamic, aggregate: Dynamic, ?field: Dynamic): Dynamic {
        if (field != null) {
            return untyped __elixir__('{0}.aggregate({1}, {2}, {3})', getSelf(), queryable, aggregate, field);
        } else {
            return untyped __elixir__('{0}.aggregate({1}, {2})', getSelf(), queryable, aggregate);
        }
    }
    
    /**
     * Checks if any entries exist for the given query
     * 
     * @param queryable The query
     * @return True if any entries exist
     */
    public static function exists(queryable: Dynamic): Bool {
        return untyped __elixir__('{0}.exists?({1})', getSelf(), queryable);
    }
    
    /**
     * Runs a transaction
     * 
     * @param fun The function to run in the transaction
     * @param opts Transaction options
     * @return Ok with the function result or Error with the reason
     */
    @:generic
    public static function transaction<T>(fun: () -> T, ?opts: Dynamic): Result<T, Dynamic> {
        if (opts != null) {
            return untyped __elixir__('{0}.transaction({1}, {2})', getSelf(), fun, opts);
        } else {
            return untyped __elixir__('{0}.transaction({1})', getSelf(), fun);
        }
    }
    
    /**
     * Rolls back the current transaction
     * 
     * @param reason The rollback reason
     */
    public static function rollback(reason: Dynamic): Void {
        untyped __elixir__('{0}.rollback({1})', getSelf(), reason);
    }
    
    /**
     * Gets the repository module name at runtime
     * This is overridden by the build macro to return the actual repo module
     */
    private static function getSelf(): String {
        // This will be replaced by the build macro
        return "Repo";
    }
}

/**
 * Transaction result type
 */
typedef TransactionResult<T> = Result<T, Dynamic>;

/**
 * Aggregate operations
 */
enum abstract AggregateOp(String) to String {
    var Count = ":count";
    var Sum = ":sum";
    var Avg = ":avg";
    var Min = ":min";
    var Max = ":max";
}

#end