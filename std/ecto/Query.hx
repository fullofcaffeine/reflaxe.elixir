package ecto;

#if (elixir || reflaxe_runtime)

/**
 * Enhanced Ecto query externs with macro support for type-safe queries
 * Provides IDE autocomplete and compile-time validation
 */

// Type-safe schema base class for IDE support
@:generic
class Schema<T> {
    public var __schema_name: String;
    public var __fields: Map<String, String>;
    
    public function new() {}
    
    // Generic field accessor for IDE autocomplete
    @:generic
    public function field<F>(name: String): F {
        return cast null;
    }
}

// User schema for IDE autocomplete
class UserSchema extends Schema<UserSchema> {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var age: Null<Int>;
    public var active: Bool;
    public var inserted_at: NaiveDateTime;
    public var updated_at: NaiveDateTime;
    
    // Association accessors
    public var posts: Array<PostSchema>;
    public var comments: Array<CommentSchema>;
    
    public function new() {
        super();
        __schema_name = "User";
    }
}

// Post schema for IDE autocomplete  
class PostSchema extends Schema<PostSchema> {
    public var id: Int;
    public var title: String;
    public var body: String;
    public var user_id: Int;
    public var published: Bool;
    public var inserted_at: NaiveDateTime;
    public var updated_at: NaiveDateTime;
    
    // Association accessors
    public var user: UserSchema;
    public var comments: Array<CommentSchema>;
    
    public function new() {
        super();
        __schema_name = "Post";
    }
}

// Comment schema for IDE autocomplete
class CommentSchema extends Schema<CommentSchema> {
    public var id: Int;
    public var content: String;
    public var user_id: Int;
    public var post_id: Int;
    public var inserted_at: NaiveDateTime;
    public var updated_at: NaiveDateTime;
    
    // Association accessors
    public var user: UserSchema;
    public var post: PostSchema;
    
    public function new() {
        super();
        __schema_name = "Comment";
    }
}

// Type-safe query builder with IDE support
@:generic
class QueryBuilder<T> {
    public var __schema_type: Class<T>;
    public var __query_parts: Array<String>;
    
    public function new(schemaType: Class<T>) {
        __schema_type = schemaType;
        __query_parts = [];
    }
    
    // Type-safe where clause with field validation
    public function where(condition: T -> Bool): QueryBuilder<T> {
        // Macro will validate field access at compile-time
        return this;
    }
    
    // Type-safe select with field validation
    public function select<R>(selector: T -> R): QueryBuilder<R> {
        // Macro will validate selected fields
        return cast this;
    }
    
    // Type-safe join with association validation
    public function join<A>(association: T -> A): QueryBuilder<T> {
        // Macro will validate association exists
        return this;
    }
    
    // Type-safe order by with field validation
    public function order_by(orderBy: T -> Dynamic): QueryBuilder<T> {
        // Macro will validate field access
        return this;
    }
    
    // Type-safe group by with field validation
    public function group_by(groupBy: T -> Dynamic): QueryBuilder<T> {
        // Macro will validate field access
        return this;
    }
    
    // Aggregation functions with type safety
    public function count(?field: T -> Dynamic): Int {
        // Macro will validate field if provided
        return 0;
    }
    
    public function sum(field: T -> Float): Float {
        // Macro will validate numeric field
        return 0.0;
    }
    
    public function avg(field: T -> Float): Float {
        // Macro will validate numeric field
        return 0.0;
    }
    
    public function max<V>(field: T -> V): V {
        // Macro will validate field exists
        return cast null;
    }
    
    public function min<V>(field: T -> V): V {
        // Macro will validate field exists
        return cast null;
    }
    
    // Compile to Ecto query string
    public function compile(): String {
        // Macro will generate final Ecto.Query
        return "";
    }
    
    // Execute query (returns extern call)
    public function all(): Array<T> {
        // Will call Repo.all() with compiled query
        return [];
    }
    
    public function one(): Null<T> {
        // Will call Repo.one() with compiled query
        return null;
    }
    
    public function one_or_nil(): Null<T> {
        // Will call Repo.one() with compiled query
        return null;
    }
}

// Main Query module with static factory methods
@:native("Ecto.Query")
extern class Query {
    
    // Type-safe query factory
    public static function from<T>(schema: Class<T>): QueryBuilder<T>;
    
    // Traditional Ecto query functions (for compatibility)
    @:native("from")
    public static function fromNative(source: Dynamic, ?options: Dynamic): Dynamic;
    
    @:native("where")
    public static function whereNative(query: Dynamic, conditions: Dynamic): Dynamic;
    
    @:native("select")
    public static function selectNative(query: Dynamic, fields: Dynamic): Dynamic;
    
    @:native("join")
    public static function joinNative(query: Dynamic, join_type: Dynamic, source: Dynamic, ?conditions: Dynamic): Dynamic;
    
    @:native("order_by")
    public static function orderByNative(query: Dynamic, order: Dynamic): Dynamic;
    
    @:native("group_by")
    public static function groupByNative(query: Dynamic, fields: Dynamic): Dynamic;
    
    @:native("having")
    public static function having(query: Dynamic, conditions: Dynamic): Dynamic;
    
    @:native("limit")
    public static function limit(query: Dynamic, count: Int): Dynamic;
    
    @:native("offset")
    public static function offset(query: Dynamic, count: Int): Dynamic;
    
    @:native("distinct")
    public static function distinct(query: Dynamic, ?fields: Dynamic): Dynamic;
    
    @:native("preload")
    public static function preload(query: Dynamic, associations: Dynamic): Dynamic;
    
    // Aggregation functions
    @:native("count")
    public static function countNative(query: Dynamic, ?field: Dynamic): Dynamic;
    
    @:native("sum")
    public static function sumNative(query: Dynamic, field: Dynamic): Dynamic;
    
    @:native("avg")
    public static function avgNative(query: Dynamic, field: Dynamic): Dynamic;
    
    @:native("max")
    public static function maxNative(query: Dynamic, field: Dynamic): Dynamic;
    
    @:native("min")
    public static function minNative(query: Dynamic, field: Dynamic): Dynamic;
    
    // Query inspection and optimization
    @:native("plan")
    public static function plan(query: Dynamic): Dynamic;
    
    @:native("explain")
    public static function explain(repo: Dynamic, query: Dynamic, ?options: Dynamic): String;
}

// Repo interface for query execution
@:native("Ecto.Repo")
extern class Repo {
    @:native("all")
    public static function all(query: Dynamic, ?options: Dynamic): Array<Dynamic>;
    
    @:native("one")
    public static function one(query: Dynamic, ?options: Dynamic): Dynamic;
    
    @:native("one!")
    public static function oneUnsafe(query: Dynamic, ?options: Dynamic): Dynamic;
    
    @:native("get")
    public static function get(schema: Dynamic, id: Dynamic, ?options: Dynamic): Dynamic;
    
    @:native("get!")
    public static function getUnsafe(schema: Dynamic, id: Dynamic, ?options: Dynamic): Dynamic;
    
    @:native("get_by")
    public static function getBy(schema: Dynamic, conditions: Dynamic, ?options: Dynamic): Dynamic;
    
    @:native("get_by!")
    public static function getByUnsafe(schema: Dynamic, conditions: Dynamic, ?options: Dynamic): Dynamic;
    
    @:native("exists?")
    public static function exists(query: Dynamic, ?options: Dynamic): Bool;
    
    @:native("aggregate")
    public static function aggregate(query: Dynamic, aggregate: Dynamic, field: Dynamic, ?options: Dynamic): Dynamic;
}

// Helper types for better IDE support
typedef NaiveDateTime = Dynamic;
typedef Changeset<T> = Dynamic;
typedef Multi = Dynamic;

// Query DSL interfaces for IDE autocomplete
interface IQueryable<T> {
    function where(condition: T -> Bool): IQueryable<T>;
    function select<R>(selector: T -> R): IQueryable<R>;
    function join<A>(association: T -> A): IQueryable<T>;
    function order_by(orderBy: T -> Dynamic): IQueryable<T>;
    function group_by(groupBy: T -> Dynamic): IQueryable<T>;
    function limit(count: Int): IQueryable<T>;
    function offset(count: Int): IQueryable<T>;
    function all(): Array<T>;
    function one(): Null<T>;
    function compile(): String;
}

// Type-safe query result types
typedef QueryResult<T> = {
    success: Bool,
    data: Array<T>,
    errors: Array<String>
}

typedef AggregateResult = {
    count: Int,
    sum: Float,
    avg: Float,
    min: Dynamic,
    max: Dynamic
}

#end