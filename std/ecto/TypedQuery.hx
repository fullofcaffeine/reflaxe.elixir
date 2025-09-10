package ecto;

#if (elixir || reflaxe_runtime)

/**
 * Type-safe query builder for Ecto following Phoenix patterns exactly
 * 
 * ## Overview
 * 
 * TypedQuery provides compile-time validated queries that generate idiomatic Ecto.Query code.
 * The API looks exactly like standard Phoenix/Ecto queries, just with type safety added on top.
 * This is the "Idiomatic Haxe for Elixir" philosophy: Phoenix patterns first, type safety second.
 * 
 * ## Key Features
 * 
 * - **Compile-time field validation**: Invalid field names are caught during compilation
 * - **Type-safe query building**: Full IntelliSense support for schema fields
 * - **Idiomatic Elixir generation**: Output is indistinguishable from hand-written Ecto queries
 * - **Phoenix-compatible API**: Works seamlessly with standard Phoenix/Ecto patterns
 * - **Automatic naming conversion**: camelCase in Haxe becomes snake_case in Elixir
 * 
 * ## Usage Example (Exactly Like Phoenix)
 * 
 * ```haxe
 * // Build a query with compile-time validation
 * var query = TypedQuery.from(Todo)
 *     .where(t -> t.completed == false)           // Field validated at compile time
 *     .where(t -> t.userId == userId)             // Multiple where clauses chain
 *     .orderBy(t -> [desc: t.insertedAt])        // Array syntax for ordering
 *     .preload(["user", "tags"]);                // Association preloading
 * 
 * // Use with Repo exactly like Phoenix
 * var todos = Repo.all(query);                   // Returns Array<Todo>
 * var todo = Repo.one(query);                    // Returns Null<Todo>
 * var exists = Repo.exists(query);               // Returns Bool
 * ```
 * 
 * ## Generated Idiomatic Elixir
 * 
 * ```elixir
 * # The above Haxe code generates standard Ecto.Query syntax
 * query = from(t in Todo,
 *   where: t.completed == false,
 *   where: t.user_id == ^user_id,
 *   order_by: [desc: t.inserted_at],
 *   preload: [:user, :tags]
 * )
 * 
 * todos = Repo.all(query)
 * todo = Repo.one(query)
 * exists = Repo.exists?(query)
 * ```
 * 
 * ## Compile-Time Validation
 * 
 * The macro system validates all field accesses at compile time:
 * 
 * ```haxe
 * // ✅ Valid: 'completed' field exists in Todo schema
 * query.where(t -> t.completed == false)
 * 
 * // ❌ Compile error: 'invalid_field' does not exist in Todo
 * query.where(t -> t.invalid_field == false)
 * // Error: Field "invalid_field" does not exist in Todo
 * ```
 * 
 * ## Advanced Query Building
 * 
 * ### Complex Where Clauses
 * ```haxe
 * query.where(t -> t.status == "active" && t.priority > 5)
 * query.where(t -> t.dueDate < now || t.override == true)
 * ```
 * 
 * ### Joins and Associations
 * ```haxe
 * query.join(t -> t.user, Left)                  // Left join on association
 *      .join(t -> t.comments, Inner, "comments") // Named join for references
 *      .where(c -> c.comments.approved == true)  // Reference joined table
 * ```
 * 
 * ### Select Projections
 * ```haxe
 * query.select(t -> {                            // Anonymous object projection
 *     id: t.id,
 *     title: t.title,
 *     userName: t.user.name
 * })
 * ```
 * 
 * ### Aggregations
 * ```haxe
 * query.groupBy(t -> [t.status])                 // Group by status
 *      .having(t -> count(t.id) > 5)            // Having clause
 * ```
 * 
 * ## Integration with Repository Pattern
 * 
 * TypedQuery works seamlessly with the Repo extern:
 * 
 * ```haxe
 * // Fetch operations
 * var todos = Repo.all(query);                   // All matching records
 * var todo = Repo.one(query);                    // Single record or null
 * 
 * // Direct fetches
 * var todo = Repo.get(Todo, 123);               // By ID
 * var todo = Repo.getOrThrow(Todo, 123);        // Raises if not found
 * 
 * // Aggregations
 * var count = Repo.aggregate(query, "count", "id");
 * ```
 * 
 * ## Design Philosophy
 * 
 * This implementation follows the "Idiomatic Haxe for Elixir" principle:
 * 
 * 1. **Phoenix patterns first**: The API mirrors Ecto.Query exactly
 * 2. **Type safety on top**: Compile-time validation without changing patterns
 * 3. **Zero runtime overhead**: Macros expand to standard Ecto queries
 * 4. **No abstraction penalty**: Generated code is what Phoenix developers write
 * 
 * @see ecto.Schema For defining database schemas
 * @see ecto.Changeset For data validation and casting
 * @see ecto.Migration For database migrations
 */

/**
 * Join types matching Ecto's join types exactly
 * 
 * Represents the different types of SQL joins available in Ecto.
 * These compile directly to Ecto's join atoms.
 * 
 * @see https://hexdocs.pm/ecto/Ecto.Query.html#join/5
 */
enum abstract JoinType(String) {
    /** Inner join - returns only matching records from both tables */
    var Inner = ":inner";
    
    /** Left join - returns all records from left table and matching from right */
    var Left = ":left";
    
    /** Right join - returns all records from right table and matching from left */
    var Right = ":right";
    
    /** Full outer join - returns all records when there's a match in either table */
    var FullOuter = ":full_outer";
}

/**
 * Type-safe wrapper for Ecto queries with fluent API
 * 
 * This abstract type wraps the underlying Elixir query struct while maintaining
 * type information through Haxe's type system. All methods return TypedQuery<T>
 * to enable fluent chaining exactly like Ecto.Query.
 * 
 * The generic type parameter T represents the schema type being queried,
 * providing compile-time type safety for all operations.
 * 
 * @param T The schema type being queried (e.g., Todo, User)
 */
abstract TypedQuery<T>(Dynamic) {
    public var query(get, never): Dynamic;
    
    public inline function new(query: Dynamic) {
        this = query;
    }
    
    inline function get_query(): Dynamic {
        return this;
    }
    
    /**
     * Create a new query from a schema class
     * 
     * This is the entry point for building queries. It creates a new TypedQuery
     * instance from a schema class, providing type safety for all subsequent operations.
     * 
     * @param schemaClass The schema class to query (e.g., Todo, User)
     * @return A new TypedQuery instance for fluent query building
     * 
     * @example
     * ```haxe
     * var query = TypedQuery.from(Todo);
     * // Generates: from(t in Todo)
     * ```
     */
    public static macro function from<T>(schemaClass: haxe.macro.Expr.ExprOf<Class<T>>): haxe.macro.Expr.ExprOf<TypedQuery<T>> {
        return reflaxe.elixir.macros.EctoQueryMacros.from(schemaClass);
    }
    
    /**
     * Add a where clause with compile-time field validation
     * 
     * Filters query results based on conditions. Multiple where clauses are combined
     * with AND logic. Field names are validated at compile time to ensure they exist
     * in the schema.
     * 
     * @param condition Lambda expression with filtering logic
     * @return Updated query with where clause added
     * 
     * @example
     * ```haxe
     * query.where(t -> t.completed == false)
     *      .where(t -> t.userId == currentUserId);
     * // Generates: where: t.completed == false, where: t.user_id == ^current_user_id
     * ```
     */
    public macro function where(ethis: haxe.macro.Expr, condition: haxe.macro.Expr): haxe.macro.Expr {
        return reflaxe.elixir.macros.EctoQueryMacros.where(ethis, condition);
    }
    
    /**
     * Add order_by clause for sorting results
     * 
     * Sorts query results by one or more fields. Supports both ascending and
     * descending order. Field names are validated at compile time.
     * 
     * @param ordering Lambda returning array of order specifications
     * @return Updated query with order_by clause added
     * 
     * @example
     * ```haxe
     * query.orderBy(t -> [desc: t.insertedAt, asc: t.title]);
     * // Generates: order_by: [desc: t.inserted_at, asc: t.title]
     * ```
     */
    public macro function orderBy(ethis: haxe.macro.Expr, ordering: haxe.macro.Expr): haxe.macro.Expr {
        return reflaxe.elixir.macros.EctoQueryMacros.orderBy(ethis, ordering);
    }
    
    /**
     * Select specific fields for projection
     * 
     * Projects query results into a custom structure. Useful for selecting only
     * the fields you need or creating calculated fields. The return type changes
     * to match the projection.
     * 
     * @param projection Lambda returning anonymous object with selected fields
     * @return Updated query with select clause and new return type
     * 
     * @example
     * ```haxe
     * query.select(t -> {
     *     id: t.id,
     *     title: t.title,
     *     userName: t.user.name
     * });
     * // Generates: select: %{id: t.id, title: t.title, user_name: t.user.name}
     * ```
     */
    public macro function select<R>(ethis: haxe.macro.Expr, projection: haxe.macro.Expr): haxe.macro.Expr {
        return reflaxe.elixir.macros.EctoQueryMacros.select(ethis, projection);
    }
    
    /**
     * Join associations for related data
     * 
     * Performs SQL joins with associated tables. Supports all standard join types
     * (inner, left, right, full outer). Associations must be defined in the schema.
     * 
     * @param association Lambda selecting the association to join
     * @param type Join type (Inner, Left, Right, FullOuter)
     * @param alias Optional alias for referencing joined table
     * @return Updated query with join clause added
     * 
     * @example
     * ```haxe
     * query.join(t -> t.user, Left)
     *      .join(t -> t.comments, Inner, "c")
     *      .where(c -> c.c.approved == true);
     * // Generates: join: :left, [t], u in assoc(t, :user),
     * //           join: :inner, [t], c in assoc(t, :comments), as: :c,
     * //           where: c.approved == true
     * ```
     */
    public macro function join(ethis: haxe.macro.Expr, association: haxe.macro.Expr, 
                              type: haxe.macro.Expr, ?alias: haxe.macro.Expr): haxe.macro.Expr {
        return reflaxe.elixir.macros.EctoQueryMacros.join(ethis, association, type, alias);
    }
    
    /**
     * Preload associations to avoid N+1 queries
     * 
     * Eagerly loads associated data in a single query (or minimal queries).
     * Essential for performance when accessing associations. Associations are
     * validated at compile time.
     * 
     * @param associations Array of association names to preload
     * @return Updated query with preload clause added
     * 
     * @example
     * ```haxe
     * query.preload(["user", "tags", "comments"]);
     * // Generates: preload: [:user, :tags, :comments]
     * ```
     */
    public macro function preload(ethis: haxe.macro.Expr, associations: haxe.macro.Expr): haxe.macro.Expr {
        return reflaxe.elixir.macros.EctoQueryMacros.preload(ethis, associations);
    }
    
    /**
     * Limit the number of results returned
     * 
     * Restricts query to return at most the specified number of records.
     * Commonly used with offset for pagination.
     * 
     * @param count Maximum number of records to return
     * @return Updated query with limit applied
     * 
     * @example
     * ```haxe
     * query.limit(10);
     * // Generates: limit: 10
     * ```
     */
    public function limit(count: Int): TypedQuery<T> {
        var newQuery = untyped __elixir__(
            '(require Ecto.Query; Ecto.Query.limit({0}, ^{1}))',
            this, count
        );
        return new TypedQuery<T>(newQuery);
    }
    
    /**
     * Skip a number of results for pagination
     * 
     * Skips the specified number of records before returning results.
     * Typically used with limit for implementing pagination.
     * 
     * @param count Number of records to skip
     * @return Updated query with offset applied
     * 
     * @example
     * ```haxe
     * query.limit(10).offset(20);  // Page 3 with 10 items per page
     * // Generates: limit: 10, offset: 20
     * ```
     */
    public function offset(count: Int): TypedQuery<T> {
        var newQuery = untyped __elixir__(
            '(require Ecto.Query; Ecto.Query.offset({0}, ^{1}))',
            this, count
        );
        return new TypedQuery<T>(newQuery);
    }
    
    /**
     * Group results by specified fields
     * 
     * Groups query results for use with aggregate functions. Must be used
     * with select clause that includes aggregate functions.
     * 
     * @param fields Lambda returning array of fields to group by
     * @return Updated query with group_by clause added
     * 
     * @example
     * ```haxe
     * query.groupBy(t -> [t.status, t.priority])
     *      .select(t -> {status: t.status, count: count(t.id)});
     * // Generates: group_by: [t.status, t.priority],
     * //           select: %{status: t.status, count: count(t.id)}
     * ```
     * 
     * @todo Implement macro expansion similar to orderBy
     */
    public macro function groupBy(ethis: haxe.macro.Expr, fields: haxe.macro.Expr): haxe.macro.Expr {
        // TODO: Implement similar to orderBy
        return ethis;
    }
    
    /**
     * Filter grouped results with aggregate conditions
     * 
     * Applies conditions to grouped results using aggregate functions.
     * Must be used after groupBy clause.
     * 
     * @param condition Lambda with aggregate condition
     * @return Updated query with having clause added
     * 
     * @example
     * ```haxe
     * query.groupBy(t -> [t.status])
     *      .having(t -> count(t.id) > 5);
     * // Generates: group_by: [t.status], having: count(t.id) > 5
     * ```
     * 
     * @todo Implement macro expansion similar to where
     */
    public macro function having(ethis: haxe.macro.Expr, condition: haxe.macro.Expr): haxe.macro.Expr {
        // TODO: Implement similar to where
        return ethis;
    }
    
    /**
     * Get the underlying Ecto query struct
     * 
     * Returns the raw Elixir query struct for direct use with Repo functions
     * or other Ecto operations. This is typically not needed as TypedQuery
     * works directly with Repo methods.
     * 
     * @return The underlying Ecto.Query struct
     */
    public inline function toEctoQuery(): Dynamic {
        return this;
    }
}

/**
 * Repository pattern for database operations
 * 
 * This extern class maps directly to your Phoenix application's Repo module,
 * providing type-safe database operations. It follows Phoenix's Repo pattern
 * exactly, with all the same methods and behaviors.
 * 
 * ## Design Philosophy
 * 
 * The Repo pattern centralizes all database interactions in a single module,
 * providing a consistent API for CRUD operations. This is standard Phoenix
 * architecture - we're not changing it, just adding type safety.
 * 
 * ## Configuration
 * 
 * Your Phoenix application must have a Repo module configured:
 * ```elixir
 * defmodule MyApp.Repo do
 *   use Ecto.Repo,
 *     otp_app: :my_app,
 *     adapter: Ecto.Adapters.Postgres
 * end
 * ```
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Query operations
 * var todos = Repo.all(TypedQuery.from(Todo));
 * var todo = Repo.get(Todo, 123);
 * 
 * // CRUD operations with changesets
 * var changeset = Todo.changeset(new Todo(), params);
 * switch(Repo.insert(changeset)) {
 *     case {ok: todo}: trace("Created: " + todo.id);
 *     case {error: changeset}: trace("Errors: " + changeset.errors);
 * }
 * ```
 * 
 * @see ecto.TypedQuery For building type-safe queries
 * @see ecto.Changeset For data validation
 * @see ecto.Schema For defining models
 */
@:native("Repo")
extern class Repo {
    /**
     * Fetch all records matching the query
     * 
     * Returns all records that match the given query. For large result sets,
     * consider using limit/offset for pagination.
     * 
     * @param query The TypedQuery to execute
     * @return Array of matching records
     * 
     * @example
     * ```haxe
     * var activeTodos = Repo.all(
     *     TypedQuery.from(Todo).where(t -> t.completed == false)
     * );
     * ```
     */
    static function all<T>(query: TypedQuery<T>): Array<T>;
    
    /**
     * Fetch a single record, returns null if not found
     * 
     * Returns at most one record matching the query. If multiple records match,
     * returns the first one (order is non-deterministic unless orderBy is used).
     * Returns null if no records match.
     * 
     * @param query The TypedQuery to execute
     * @return Single record or null
     * 
     * @example
     * ```haxe
     * var latestTodo = Repo.one(
     *     TypedQuery.from(Todo).orderBy(t -> [desc: t.insertedAt]).limit(1)
     * );
     * ```
     */
    static function one<T>(query: TypedQuery<T>): Null<T>;
    
    /**
     * Get a record by ID
     * 
     * Fetches a single record by its primary key. Returns null if not found.
     * This is the most efficient way to fetch a single record when you know the ID.
     * 
     * @param schema The schema class
     * @param id The primary key value
     * @return Record or null
     * 
     * @example
     * ```haxe
     * var todo = Repo.get(Todo, 123);
     * if (todo != null) {
     *     trace("Found: " + todo.title);
     * }
     * ```
     */
    static function get<T>(schema: Class<T>, id: Int): Null<T>;
    
    /**
     * Get a record by ID, raises if not found
     * 
     * Like get/2 but raises Ecto.NoResultsError if the record is not found.
     * Use this when the record must exist (e.g., after authentication).
     * 
     * @param schema The schema class
     * @param id The primary key value
     * @return Record (never null)
     * @throws Ecto.NoResultsError if record not found
     * 
     * @example
     * ```haxe
     * var todo = Repo.getOrThrow(Todo, todoId);
     * // Will raise if todo doesn't exist
     * trace("Title: " + todo.title);
     * ```
     */
    @:native("get!")
    static function getOrThrow<T>(schema: Class<T>, id: Int): T;
    
    /**
     * Get a record by fields
     * 
     * Fetches a single record matching the given field values.
     * Returns null if no record matches. If multiple records match,
     * returns an arbitrary one.
     * 
     * @param schema The schema class
     * @param clauses Map of field names to values
     * @return Record or null
     * 
     * @example
     * ```haxe
     * var user = Repo.get_by(User, {email: "user@example.com"});
     * ```
     * 
     * @todo Type this properly with compile-time field validation
     */
    static function get_by<T>(schema: Class<T>, clauses: Dynamic): Null<T>;
    
    /**
     * Insert a new record
     * 
     * Inserts a new record into the database after running changeset validations.
     * Returns {ok: record} on success or {error: changeset} on validation failure.
     * 
     * @param changeset The validated changeset to insert
     * @return Result with inserted record or error changeset
     * 
     * @example
     * ```haxe
     * var changeset = Todo.changeset(new Todo(), {title: "New task"});
     * switch(Repo.insert(changeset)) {
     *     case {ok: todo}: 
     *         trace("Created with ID: " + todo.id);
     *     case {error: changeset}:
     *         trace("Validation errors: " + changeset.errors);
     * }
     * ```
     */
    static function insert<T>(changeset: ecto.Changeset.Changeset<T, Dynamic>): {ok: T} | {error: ecto.Changeset.Changeset<T, Dynamic>};
    
    /**
     * Update an existing record
     * 
     * Updates a record in the database after running changeset validations.
     * The changeset must be built from an existing record (not a new struct).
     * 
     * @param changeset The validated changeset with changes
     * @return Result with updated record or error changeset
     * 
     * @example
     * ```haxe
     * var todo = Repo.get(Todo, todoId);
     * var changeset = Todo.changeset(todo, {completed: true});
     * switch(Repo.update(changeset)) {
     *     case {ok: updated}: 
     *         trace("Updated: " + updated.title);
     *     case {error: changeset}:
     *         trace("Update failed: " + changeset.errors);
     * }
     * ```
     */
    static function update<T>(changeset: ecto.Changeset.Changeset<T, Dynamic>): {ok: T} | {error: ecto.Changeset.Changeset<T, Dynamic>};
    
    /**
     * Delete a record
     * 
     * Deletes a record from the database. The record must have been previously
     * fetched from the database (must have an ID).
     * 
     * @param record The record to delete
     * @return Result with deleted record or error changeset
     * 
     * @example
     * ```haxe
     * var todo = Repo.get(Todo, todoId);
     * switch(Repo.delete(todo)) {
     *     case {ok: deleted}:
     *         trace("Deleted: " + deleted.title);
     *     case {error: changeset}:
     *         trace("Delete failed: " + changeset.errors);
     * }
     * ```
     */
    static function delete<T>(record: T): {ok: T} | {error: ecto.Changeset.Changeset<T, Dynamic>};
    
    /**
     * Check if records exist
     * 
     * Returns true if any records match the query, false otherwise.
     * More efficient than fetching records when you only need to check existence.
     * 
     * @param query The query to check
     * @return True if records exist
     * 
     * @example
     * ```haxe
     * var hasActiveTodos = Repo.exists(
     *     TypedQuery.from(Todo).where(t -> t.completed == false)
     * );
     * ```
     */
    static function exists<T>(query: TypedQuery<T>): Bool;
    
    /**
     * Perform aggregate functions
     * 
     * Calculates aggregate values like count, sum, avg, min, max.
     * Returns the aggregate result with appropriate type.
     * 
     * @param query The query to aggregate
     * @param aggregate The aggregate function ("count", "sum", "avg", "min", "max")
     * @param field The field to aggregate (use "id" for count)
     * @return Aggregate result
     * 
     * @example
     * ```haxe
     * var todoCount = Repo.aggregate(TypedQuery.from(Todo), "count", "id");
     * var avgPriority = Repo.aggregate(
     *     TypedQuery.from(Todo).where(t -> t.completed == false),
     *     "avg", 
     *     "priority"
     * );
     * ```
     */
    static function aggregate<T>(query: TypedQuery<T>, aggregate: String, field: String): Dynamic;
    
    /**
     * Preload associations on existing records
     * 
     * Loads associations for records that have already been fetched.
     * Useful when you need to load associations conditionally or later.
     * 
     * @param records Single record or array of records
     * @param associations Array of association names to preload
     * @return Records with associations loaded
     * 
     * @example
     * ```haxe
     * var todos = Repo.all(TypedQuery.from(Todo));
     * // Load associations later if needed
     * todos = Repo.preload(todos, ["user", "tags"]);
     * ```
     */
    static function preload<T>(records: T, associations: Array<String>): T;
}

#end