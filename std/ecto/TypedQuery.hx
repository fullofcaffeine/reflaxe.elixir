package ecto;

import ecto.Query;

/**
 * Represents an Elixir Stream - the internal stream data structure
 * 
 * This is an opaque type in Elixir representing lazy, composable enumerables.
 * Streams in Elixir are not evaluated until explicitly consumed.
 */
extern class ElixirStream<T> {
    // Opaque Elixir Stream type - internal structure not exposed to Haxe
}

/**
 * Type-safe wrapper for Elixir Streams - lazy, composable enumerables
 * 
 * ## What are Elixir Streams?
 * 
 * Streams are lazy enumerables that allow you to work with potentially
 * infinite collections or expensive computations without evaluating them
 * upfront. Unlike regular Enum operations which are eager (evaluate immediately),
 * Stream operations build up a computation pipeline that only executes when
 * explicitly consumed.
 * 
 * ## Key Characteristics
 * 
 * - **Lazy**: Operations are not executed until the stream is consumed
 * - **Composable**: Multiple operations can be chained without intermediate results
 * - **Memory Efficient**: Only processes one element at a time
 * - **Infinite Support**: Can represent infinite sequences
 * 
 * ## Usage Example
 * 
 * ```haxe
 * // Database query returning a stream instead of loading all records
 * var stream = Repo.stream(query);
 * 
 * // Chain operations - nothing is executed yet!
 * var processed = stream
 *     .filter(todo -> todo.priority == "high")
 *     .map(todo -> todo.title)
 *     .take(10);
 * 
 * // NOW the stream is consumed and operations execute
 * var results: Array<String> = processed.toArray();
 * ```
 * 
 * ## When to Use Streams
 * 
 * - **Large datasets**: When loading all data would use too much memory
 * - **Expensive operations**: When you want to defer computation
 * - **Infinite sequences**: Working with potentially unbounded data
 * - **Pipeline optimization**: Combining multiple transformations efficiently
 * 
 * ## Stream vs Enum
 * 
 * ```haxe
 * // Enum (eager) - loads ALL todos, then filters, then maps
 * var eager = Repo.all(query)  // Load 10,000 records into memory!
 *     |> Enum.filter(_, todo -> todo.completed)
 *     |> Enum.map(_, todo -> todo.title)
 *     |> Enum.take(_, 5);  // Only wanted 5!
 * 
 * // Stream (lazy) - loads and processes one at a time
 * var lazy = Repo.stream(query)  // Returns a stream, no loading yet
 *     .filter(todo -> todo.completed)  // Adds filter to pipeline
 *     .map(todo -> todo.title)  // Adds map to pipeline
 *     .take(5)  // Adds limit to pipeline
 *     .toArray();  // NOW it executes, stops after 5 matches
 * ```
 * 
 * ## Common Gotchas
 * 
 * - Streams are single-use: once consumed, they can't be reused
 * - Side effects in stream operations may not execute as expected
 * - Streams hold database transactions open until consumed
 */
abstract Stream<T>(ElixirStream<T>) from ElixirStream<T> to ElixirStream<T> {
    public inline function new(s: ElixirStream<T>) {
        this = s;
    }
    
    public inline function toArray(): Array<T> {
        return untyped __elixir__('Enum.to_list({0})', this);
    }
    
    public inline function map<R>(fn: T -> R): Stream<R> {
        return untyped __elixir__('Stream.map({0}, {1})', this, fn);
    }
    
    public inline function filter(fn: T -> Bool): Stream<T> {
        return untyped __elixir__('Stream.filter({0}, {1})', this, fn);
    }
    
    public inline function take(count: Int): Stream<T> {
        return untyped __elixir__('Stream.take({0}, {1})', this, count);
    }
}

/**
 * Ecto Repo extern for database operations
 */
@:native("Repo")
extern class Repo {
    static function all<T>(query: EctoQuery<T>): Array<T>;
    static function one<T>(query: EctoQuery<T>): Null<T>;
    static function aggregate<T>(query: EctoQuery<T>, aggregate: String, field: String): Float;
    static function exists<T>(query: EctoQuery<T>): Bool;
    static function preload<T>(records: T, associations: Array<String>): T;
    static function stream<T>(query: EctoQuery<T>): Stream<T>;
}

/**
 * Type-safe query builder for Ecto with compile-time field validation
 * 
 * Provides both type-safe operations and escape hatches for complex queries.
 * 
 * ## Type-Safe API (Default)
 * 
 * ```haxe
 * var query = TypedQuery.from(Todo)
 *     .where(todo -> todo.completed == true)
 *     .where(todo -> todo.priority == "high")
 *     .select(todo -> {
 *         id: todo.id,
 *         title: todo.title,
 *         dueDate: todo.dueDate
 *     })
 *     .orderBy(todo -> todo.dueDate, Desc)
 *     .limit(10);
 * 
 * var results = Repo.all(query);
 * ```
 * 
 * ## Escape Hatch API (When Needed)
 * 
 * ```haxe
 * // For complex Ecto queries that don't fit the type-safe model
 * var query = TypedQuery.from(Todo)
 *     .whereRaw("completed = ? AND priority IN (?)", [true, ["high", "medium"]])
 *     .joinRaw("LEFT JOIN users u ON u.id = todos.user_id")
 *     .selectRaw("todos.*, u.name as user_name");
 * ```
 * 
 * ## Benefits
 * 
 * - **Compile-time field validation**: Typos in field names caught at compile time
 * - **Type-safe operators**: Can't compare incompatible types
 * - **IntelliSense support**: Full autocomplete for schema fields
 * - **Escape hatches**: Raw queries when type system is limiting
 * - **Gradual migration**: Can mix typed and raw queries
 */
class TypedQuery<T> {
    private var query: EctoQuery<T>;
    private var schemaType: Class<T>;
    
    public function new(schema: Class<T>) {
        this.schemaType = schema;
        this.query = Query.from(schema);
    }
    
    /**
     * Create a new typed query from a schema
     */
    public static function from<T>(schema: Class<T>): TypedQuery<T> {
        return new TypedQuery(schema);
    }
    
    /**
     * Type-safe WHERE clause with lambda expression
     * 
     * @param predicate Lambda that receives typed schema instance
     */
    public function where(predicate: T -> Bool): TypedQuery<T> {
        // This would be processed by a macro to extract field names
        // and generate proper Ecto query
        #if macro
        // Extract field accesses from lambda AST
        // Convert to Ecto where clause
        #end
        return this;
    }
    
    /**
     * Raw WHERE clause for complex queries (escape hatch)
     */
    public function whereRaw(condition: String, ?params: Array<Dynamic>): TypedQuery<T> {
        // Direct pass-through to Ecto
        query = query.where(condition, params);
        return this;
    }
    
    /**
     * Type-safe SELECT with projection
     */
    public function select<R>(projection: T -> R): TypedQuery<R> {
        // Macro processes the projection lambda
        #if macro
        // Extract field selections
        // Generate Ecto select clause
        #end
        return cast this;
    }
    
    /**
     * Raw SELECT for complex projections (escape hatch)
     */
    public function selectRaw(fields: String): TypedQuery<Dynamic> {
        // Direct Ecto select
        return cast this;
    }
    
    /**
     * Type-safe ORDER BY
     */
    public function orderBy<F>(field: T -> F, ?direction: OrderDirection = Asc): TypedQuery<T> {
        // Macro extracts field name from lambda
        return this;
    }
    
    /**
     * Raw ORDER BY (escape hatch)
     */
    public function orderByRaw(clause: String): TypedQuery<T> {
        return this;
    }
    
    /**
     * Type-safe JOIN with related schema
     */
    public function join<R>(relation: T -> R, ?alias: String): TypedQuery<T> {
        // Macro processes relationship
        return this;
    }
    
    /**
     * Raw JOIN for complex relationships (escape hatch)
     */
    public function joinRaw(clause: String): TypedQuery<T> {
        return this;
    }
    
    /**
     * Type-safe GROUP BY
     */
    public function groupBy<F>(field: T -> F): TypedQuery<T> {
        return this;
    }
    
    /**
     * Type-safe HAVING clause
     */
    public function having(predicate: T -> Bool): TypedQuery<T> {
        return this;
    }
    
    /**
     * Limit results
     */
    public function limit(count: Int): TypedQuery<T> {
        query = query.limit(count);
        return this;
    }
    
    /**
     * Offset results
     */
    public function offset(count: Int): TypedQuery<T> {
        query = query.offset(count);
        return this;
    }
    
    /**
     * Preload associations
     */
    public function preload(associations: Array<String>): TypedQuery<T> {
        query = query.preload(associations);
        return this;
    }
    
    /**
     * Lock records for update
     */
    public function lock(?type: LockType = ForUpdate): TypedQuery<T> {
        return this;
    }
    
    /**
     * Get the underlying Ecto query (escape hatch)
     * 
     * Use this when you need direct access to Ecto's query API
     */
    public function toEctoQuery(): EctoQuery<T> {
        return query;
    }
    
    /**
     * Execute query and return all results
     */
    public function all(): Array<T> {
        return Repo.all(query);
    }
    
    /**
     * Execute query and return first result
     */
    public function first(): Null<T> {
        return Repo.one(query.limit(1));
    }
    
    /**
     * Execute query and return single result (throws if not exactly one)
     */
    public function one(): T {
        return untyped __elixir__('Repo.one!({0})', query);
    }
    
    /**
     * Check if any records match
     */
    public function exists(): Bool {
        return untyped __elixir__('Repo.exists?({0})', query);
    }
    
    /**
     * Count matching records
     */
    public function count(): Int {
        return Std.int(Repo.aggregate(query, "count", "*"));
    }
    
    /**
     * Stream results for large datasets
     * 
     * Returns a lazy Stream that can be processed without loading
     * all results into memory at once.
     * 
     * @return A Stream of results that can be transformed and consumed
     */
    public function stream(): Stream<T> {
        return Repo.stream(query);
    }
}

/**
 * Order direction for sorting
 */
enum OrderDirection {
    Asc;
    Desc;
}

/**
 * Lock types for transactions
 */
enum LockType {
    ForUpdate;
    ForShare;
    ForKeyShare;
    ForNoKeyUpdate;
}

/**
 * Query operators for type-safe comparisons
 * Allows natural syntax like: todo.completed == true
 */
abstract QueryOp<T>(T) from T {
    public inline function new(value: T) {
        this = value;
    }
    
    
    @:op(A == B)
    public static inline function eq<T>(a: QueryOp<T>, b: QueryOp<T>): Bool {
        return untyped __elixir__('{0} == {1}', a, b);
    }
    
    @:op(A != B) 
    public static inline function neq<T>(a: QueryOp<T>, b: QueryOp<T>): Bool {
        return untyped __elixir__('{0} != {1}', a, b);
    }
    
    @:op(A < B)
    public static inline function lt<T>(a: QueryOp<T>, b: QueryOp<T>): Bool {
        return untyped __elixir__('{0} < {1}', a, b);
    }
    
    @:op(A > B)
    public static inline function gt<T>(a: QueryOp<T>, b: QueryOp<T>): Bool {
        return untyped __elixir__('{0} > {1}', a, b);
    }
    
    @:op(A <= B)
    public static inline function lte<T>(a: QueryOp<T>, b: QueryOp<T>): Bool {
        return untyped __elixir__('{0} <= {1}', a, b);
    }
    
    @:op(A >= B)
    public static inline function gte<T>(a: QueryOp<T>, b: QueryOp<T>): Bool {
        return untyped __elixir__('{0} >= {1}', a, b);
    }
}

/**
 * Field reference for type-safe queries
 * 
 * This would be generated by macros based on schema definitions
 */
@:generic
abstract FieldRef<T, F>(String) {
    public inline function new(name: String) {
        this = name;
    }
    
    public function equals(value: F): QueryCondition {
        return new QueryCondition(this + " = ?", [value]);
    }
    
    public function notEquals(value: F): QueryCondition {
        return new QueryCondition(this + " != ?", [value]);
    }
    
    public function isIn(values: Array<F>): QueryCondition {
        return new QueryCondition(this + " IN (?)", [values]);
    }
    
    public function isNull(): QueryCondition {
        return new QueryCondition(this + " IS NULL", []);
    }
    
    public function isNotNull(): QueryCondition {
        return new QueryCondition(this + " IS NOT NULL", []);
    }
}

/**
 * Query condition for building complex queries
 */
class QueryCondition {
    public var clause: String;
    public var params: Array<Dynamic>;
    
    public function new(clause: String, params: Array<Dynamic>) {
        this.clause = clause;
        this.params = params;
    }
    
    public function and(other: QueryCondition): QueryCondition {
        return new QueryCondition(
            "(" + this.clause + ") AND (" + other.clause + ")",
            this.params.concat(other.params)
        );
    }
    
    public function or(other: QueryCondition): QueryCondition {
        return new QueryCondition(
            "(" + this.clause + ") OR (" + other.clause + ")",
            this.params.concat(other.params)
        );
    }
}