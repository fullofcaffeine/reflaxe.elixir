package phoenix;

/**
 * Comprehensive Ecto ORM extern definitions for type-safe database operations
 * 
 * This module provides strongly-typed interfaces for Ecto schemas, queries, 
 * changesets, and repository operations - eliminating Dynamic types for 
 * compile-time safety in database interactions.
 */

/**
 * Main Ecto module with repository and query operations
 */
@:native("Ecto")
extern class Ecto {
    // Re-export key Ecto classes for convenience
    static var Repo(get, never): Class<EctoRepo>;
    static var Query(get, never): Class<EctoQuery>;
    // NOTE: For Changeset operations, use ecto.Changeset<T, P> abstract instead
    static var Schema(get, never): Class<EctoSchema>;
}

/**
 * Ecto.Repo for database operations with full type safety
 */
@:native("Ecto.Repo")
extern class EctoRepo {
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
    static function all<T>(queryable: Query<T>): Array<T>;
    
    /**
     * Get a single record from query
     */
    static function one<T>(queryable: Query<T>): Null<T>;
    
    /**
     * Insert a new record with changeset validation
     */
    static function insert<T, P>(changeset: ecto.Changeset<T, P>): Result<T, String>;

    /**
     * Update an existing record with changeset validation
     */
    static function update<T, P>(changeset: ecto.Changeset<T, P>): Result<T, String>;

    /**
     * Delete a record
     */
    static function delete<T>(record: T): Result<T, String>;

    /**
     * Insert or update based on primary key
     */
    static function insert_or_update<T, P>(changeset: ecto.Changeset<T, P>): Result<T, String>;
    
    /**
     * Execute a raw SQL query
     */
    static function query(sql: String, params: Array<QueryValue>): QueryResult;
    
    /**
     * Start a database transaction
     */
    static function transaction<T>(func: () -> T): Result<T, String>;
    
    /**
     * Check if repo is connected to database
     */
    static function connected(): Bool;
    
    /**
     * Get repository configuration
     */
    static function config(): RepoConfig;
}

/**
 * Ecto.Query for building type-safe database queries
 */
@:native("Ecto.Query")
extern class EctoQuery {
    /**
     * Start a query from a schema or table
     */
    static function from<T>(queryable: Class<T>, ?alias: String): Query<T>;
    
    /**
     * Add a WHERE clause with conditions
     */
    static function where<T>(query: Query<T>, conditions: QueryConditions): Query<T>;
    
    /**
     * Add an ORDER BY clause
     */
    static function order_by<T>(query: Query<T>, order: Array<OrderByClause>): Query<T>;
    
    /**
     * Add a GROUP BY clause
     */
    static function group_by<T>(query: Query<T>, fields: Array<String>): Query<T>;
    
    /**
     * Add a HAVING clause
     */
    static function having<T>(query: Query<T>, conditions: QueryConditions): Query<T>;
    
    /**
     * Add a LIMIT clause
     */
    static function limit<T>(query: Query<T>, count: Int): Query<T>;
    
    /**
     * Add an OFFSET clause
     */
    static function offset<T>(query: Query<T>, count: Int): Query<T>;
    
    /**
     * Add a SELECT clause with specific fields
     */
    static function select<T>(query: Query<T>, fields: Array<String>): Query<T>;
    
    /**
     * Add a JOIN clause
     */
    static function join<T>(query: Query<T>, type: JoinType, target: Class<Dynamic>, condition: JoinCondition): Query<T>;
    
    /**
     * Add a DISTINCT clause
     */
    static function distinct<T>(query: Query<T>, fields: Array<String>): Query<T>;
    
    /**
     * Add a preload for associations
     */
    static function preload<T>(query: Query<T>, associations: Array<String>): Query<T>;
    
    /**
     * Lock records for update
     */
    static function lock<T>(query: Query<T>, lockType: String): Query<T>;
    
    /**
     * Create a subquery
     */
    static function subquery<T>(query: Query<T>): SubQuery<T>;
    
    /**
     * Union two queries
     */
    static function union<T>(query1: Query<T>, query2: Query<T>): Query<T>;
    
    /**
     * Union all two queries  
     */
    static function union_all<T>(query1: Query<T>, query2: Query<T>): Query<T>;
}

// NOTE: EctoChangeset class has been removed. All changeset operations should use
// the ecto.Changeset<T, P> abstract type instead, which provides:
// - Full type safety with two type parameters (schema type T, params type P)
// - Chainable validation methods (validateRequired, validateLength, etc.)
// - Zero runtime overhead via extern inline methods
// See: std/ecto/Changeset.hx

/**
 * Ecto.Schema for defining database schemas
 */
@:native("Ecto.Schema")
extern class EctoSchema {
    /**
     * Define a schema with table name and fields
     */
    macro static function schema(table: String, fields: Array<SchemaField>): Dynamic;
    
    /**
     * Define an embedded schema
     */
    macro static function embedded_schema(fields: Array<SchemaField>): Dynamic {
        // This would be implemented as a build macro
        return macro {};
    }
    
    /**
     * Create field definition
     */
    inline static function field(name: String, type: FieldType, ?options: FieldOptions): SchemaField {
        return {
            name: name,
            type: type,
            options: options != null ? options : {}
        };
    }
    
    /**
     * Create association definition
     */
    inline static function belongs_to<T>(name: String, schema: Class<T>, ?options: AssociationOptions): SchemaField {
        return field(name, BelongsTo, cast options);
    }
    inline static function has_one<T>(name: String, schema: Class<T>, ?options: AssociationOptions): SchemaField {
        return field(name, HasOne, cast options);
    }
    inline static function has_many<T>(name: String, schema: Class<T>, ?options: AssociationOptions): SchemaField {
        return field(name, HasMany, cast options);
    }
    inline static function many_to_many<T>(name: String, schema: Class<T>, ?options: ManyToManyOptions): SchemaField {
        return field(name, ManyToMany, cast options);
    }
    
    /**
     * Create embedded field definition
     */
    inline static function embeds_one<T>(name: String, schema: Class<T>, ?options: EmbedOptions): SchemaField {
        return field(name, Custom("embed"), cast options);
    }
    inline static function embeds_many<T>(name: String, schema: Class<T>, ?options: EmbedOptions): SchemaField {
        return field(name, Array(Custom("embed")), cast options);
    }
    
    /**
     * Generate timestamps fields (inserted_at, updated_at)
     */
    inline static function timestamps(?options: TimestampsOptions): Array<SchemaField> {
        return [
            field("inserted_at", Naive_datetime, cast options),
            field("updated_at", Naive_datetime, cast options)
        ];
    }
}

/**
 * Ecto.Migration for database migrations
 */
@:native("Ecto.Migration")
extern class EctoMigration {
    /**
     * Create a new table
     */
    static function create_table(name: String, ?options: CreateTableOptions): TableBuilder;
    
    /**
     * Drop a table
     */
    static function drop_table(name: String, ?options: DropTableOptions): Void;
    
    /**
     * Alter an existing table
     */
    static function alter_table(name: String): TableBuilder;
    
    /**
     * Add a column to existing table
     */
    static function add_column(table: String, name: String, type: String, ?options: FieldOptions): Void;
    
    /**
     * Remove a column from table
     */
    static function remove_column(table: String, name: String): Void;
    
    /**
     * Modify a column in table
     */
    static function modify_column(table: String, name: String, type: String, ?options: FieldOptions): Void;
    
    /**
     * Rename a column
     */
    static function rename_column(table: String, oldName: String, newName: String): Void;
    
    /**
     * Create an index
     */
    static function create_index(table: String, columns: Array<String>, ?options: IndexOptions): Void;
    
    /**
     * Drop an index
     */
    static function drop_index(table: String, columns: Array<String>, ?options: IndexOptions): Void;
    
    /**
     * Execute raw SQL
     */
    static function execute(sql: String): Void;
    
    /**
     * Create a constraint
     */
    static function create_constraint(table: String, name: String, constraint: ConstraintDefinition): Void;
    
    /**
     * Drop a constraint
     */
    static function drop_constraint(table: String, name: String): Void;
}

// ============================================================================
// Type Definitions for Ecto Operations
// ============================================================================

/**
 * Type-safe query conditions - no more Dynamic!
 */
typedef QueryConditions = {
    // Field-based conditions
    var ?where: Map<String, QueryValue>;
    var ?and: Array<QueryConditions>;
    var ?or: Array<QueryConditions>;
    var ?not: QueryConditions;
}

/**
 * Type-safe changeset parameters - replaces Dynamic params
 */
typedef ChangesetParams = Map<String, ChangesetValue>;

/**
 * Valid changeset values - strongly typed
 */
enum ChangesetValue {
    StringValue(s: String);
    IntValue(i: Int);
    FloatValue(f: Float);
    BoolValue(b: Bool);
    DateValue(d: Date);
    NullValue;
    ArrayValue(values: Array<ChangesetValue>);
    MapValue(map: Map<String, ChangesetValue>);
}

/**
 * Type-safe join conditions
 */
typedef JoinCondition = {
    var leftField: String;
    var rightField: String; 
    var op: ComparisonOperator; // 'operator' is a reserved keyword in Haxe
}

/**
 * Comparison operators for joins and conditions
 */
enum ComparisonOperator {
    Equal;
    NotEqual;
    GreaterThan;
    GreaterThanOrEqual;
    LessThan;
    LessThanOrEqual;
    In(values: Array<QueryValue>);
    Like(pattern: String);
    IsNull;
    IsNotNull;
}

/**
 * Query source definition
 */
typedef QuerySource = {
    var source: String;
    /**
     * The schema class reference for type safety
     * 
     * Currently Class<Dynamic> because:
     * 1. It represents ANY Haxe class that can be used as an Ecto schema
     * 2. Provides compile-time validation that a real class is passed
     * 3. Prevents raw strings or invalid references
     * 
     * Future improvement: Use generics like Class<T> where T extends EctoSchema
     * This would enable:
     * - Full compile-time type checking of field access
     * - IntelliSense for schema fields in query building
     * - Compile-time validation of field names and types
     * 
     * Example future usage:
     * QuerySource<Todo> = { schema: Todo, ... }
     * This ensures only Todo fields can be accessed in queries.
     */
    var schema: Class<Dynamic>;
    var prefix: Null<String>;
}

/**
 * Query sources collection
 */
typedef QuerySources = Array<QuerySource>;

/**
 * Join clause definition
 */
typedef JoinClause = {
    var type: JoinType;
    var source: QuerySource;
    var condition: JoinCondition;
}

/**
 * Join type enumeration
 */
/**
 * Join type for Ecto.Query
 *
 * WHAT
 * - Marked with @:elixirIdiomatic so tags compile to :inner/:left/:right/:full/:cross,
 *   matching Ecto's expected atoms in macro DSL.
 */
@:elixirIdiomatic
enum JoinType {
    Inner;
    Left;
    Right;
    Full;
    Cross;
}

/**
 * Where clause definition
 */
typedef WhereClause = {
    var condition: QueryConditions;
    var params: Array<QueryValue>;
}

/**
 * Group by clause definition
 */
typedef GroupByClause = {
    var fields: Array<String>;
}

/**
 * Having clause definition
 */
typedef HavingClause = {
    var condition: QueryConditions;
    var params: Array<QueryValue>;
}

/**
 * Order by clause definition
 */
typedef OrderByClause = {
    var field: String;
    var direction: SortDirection;
    var nulls: NullsPosition;
}

/**
 * Sort direction for queries
 */
enum SortDirection {
    Asc;
    Desc;
}

/**
 * Nulls position in ordering
 */
/**
 * NULLS FIRST/LAST handling
 *
 * WHAT
 * - Compile to :first/:last/:default atoms to align with Ecto ordering options.
 */
@:elixirIdiomatic
enum NullsPosition {
    First;
    Last;
    Default;
}

/**
 * Create table options
 */
typedef CreateTableOptions = {
    var ?temporary: Bool;
    var ?if_not_exists: Bool;
    var ?engine: String;
    var ?charset: String;
    var ?collation: String;
}

/**
 * Generic Ecto query type
 */
typedef Query<T> = {
    var from: QuerySource;
    var joins: Array<JoinClause>;
    var wheres: Array<WhereClause>;
    var group_bys: Array<GroupByClause>;
    var havings: Array<HavingClause>;
    var order_bys: Array<OrderByClause>;
    var limit: Null<Int>;
    var offset: Null<Int>;
    var select: Array<String>;
    var distinct: Array<String>;
    var lock: Null<String>;
    var sources: QuerySources;
    var preloads: Array<String>;
    var assocs: Array<AssocQuery>;
    var prefix: Null<String>;
}

/**
 * Subquery type for nested queries
 */
typedef SubQuery<T> = Query<T>;

/**
 * Association query for preloading  
 */
typedef AssocQuery = {
    var assoc: String;
    var query: Query<Any>; // Will be eliminated when we add proper schema generics
}

/**
 * Query result from raw SQL
 */
typedef QueryResult = {
    var rows: Array<Array<QueryValue>>; // Type-safe row data instead of Dynamic
    var num_rows: Int;
    var columns: Array<String>;
}

/**
 * Repository configuration
 */
typedef RepoConfig = {
    var adapter: String;
    var database: String;
    var hostname: String;
    var port: Int;
    var username: String;
    var password: String;
    var pool_size: Int;
    var timeout: Int;
}

/**
 * Repository operation options - type-safe alternatives to Dynamic
 */
enum RepoOption {
    Timeout(ms: Int);
    Log(level: LogLevel);
    Telemetry(metadata: Map<String, String>);
    Prefix(schema: String);
    ReadOnly(readonly: Bool);
}

/**
 * Log levels for repository operations
 */
/**
 * Log level
 *
 * WHAT
 * - Compile to :debug/:info/:warning/:error atoms used in logging.
 */
@:elixirIdiomatic
enum LogLevel {
    Debug;
    Info;  
    Warning;
    Error;
}

// NOTE: Changeset type is in ecto.Changeset<T, P> - use that instead of
// defining a duplicate here. The ecto.Changeset abstract provides chainable
// validation methods and full type safety.

/**
 * Changeset actions
 */
/**
 * Changeset action
 *
 * WHAT
 * - Compile to :insert/:update/:delete/:replace/:ignore atoms to match Ecto semantics.
 */
@:elixirIdiomatic
enum ChangesetAction {
    Insert;
    Update;
    Delete;
    Replace;
    Ignore;
}

/**
 * Validation error definition
 */
typedef ValidationError = {
    var field: String;
    var message: String;
    var validation: String;
    var code: String;
}

/**
 * Schema field definition for macro usage
 */
typedef SchemaField = {
    var name: String;
    var type: FieldType;
    var options: FieldOptions;
}

/**
 * Ecto field types
 */
// Keep FieldType non-idiomatic: we convert to Ecto atoms at call sites; this enum is
// used in type-safe builder APIs spanning multiple targets.
enum FieldType {
    Id;
    Binary_id;
    Integer;
    Float;
    Boolean;
    String;
    Binary;
    Date;
    Time;
    Naive_datetime;
    Utc_datetime;
    Map;
    Array(itemType: FieldType);
    Decimal;
    Custom(typeName: String);
    // Association types
    BelongsTo;
    HasOne;
    HasMany;
    ManyToMany;
}

/**
 * Field options
 */
typedef FieldOptions = {
    var ?nullable: Bool;
    var ?defaultValue: Any;
    var ?primary_key: Bool;
    var ?autogenerate: Bool;
    var ?read_after_writes: Bool;
    var ?virtual: Bool;
    var ?redact: Bool;
    var ?source: String;
    var ?size: Int;
    var ?precision: Int;
    var ?scale: Int;
}

/**
 * Association options
 */
typedef AssociationOptions = {
    var ?foreign_key: String;
    var ?references: String;
    var ?on_delete: OnDeleteAction;
    var ?on_replace: OnReplaceAction;
    var ?defaults: ChangesetParams; // Type-safe defaults instead of Dynamic
    var ?where: QueryConditions; // Type-safe where conditions instead of Dynamic
    var ?preload_order: Array<OrderByClause>;
}

/**
 * Many-to-many association options
 */
typedef ManyToManyOptions = AssociationOptions & {
    var join_through: String;
    var ?join_keys: Array<String>;
    var ?on_delete_join: OnDeleteAction;
}

/**
 * Embed options
 */
typedef EmbedOptions = {
    var ?on_replace: OnReplaceAction;
    var ?strategy: EmbedStrategy;
}

/**
 * Embed strategies
 */
enum EmbedStrategy {
    Replace;
    Append;
}

/**
 * On delete actions
 */
/**
 * On delete actions for foreign keys
 *
 * WHAT
 * - Compile to :nothing/:restrict/:delete_all/:nilify_all atoms expected by Ecto.
 */
@:elixirIdiomatic
enum OnDeleteAction {
    Nothing;
    Restrict;
    Delete_all;
    Nilify_all;
}

/**
 * On replace actions
 */
/**
 * On replace actions for embeds/associations
 *
 * WHAT
 * - Compile to :raise/:mark_as_invalid/:nilify/:delete/:update atoms expected by Ecto.
 */
@:elixirIdiomatic
enum OnReplaceAction {
    Raise;
    Mark_as_invalid;
    Nilify;
    Delete;
    Update;
}

/**
 * Timestamps options
 */
typedef TimestampsOptions = {
    var ?inserted_at: String;
    var ?updated_at: String;
    var ?type: FieldType;
}

/**
 * Length validation options
 */
typedef LengthValidationOptions = {
    var ?min: Int;
    var ?max: Int;
    var ?is: Int;
    var ?message: String;
}

/**
 * Format validation options
 */
typedef FormatValidationOptions = {
    var ?message: String;
    var ?allow_nil: Bool;
}

/**
 * General validation options
 */
typedef ValidationOptions = {
    var ?message: String;
    var ?allow_nil: Bool;
    var ?allow_blank: Bool;
}

/**
 * Number validation options
 */
typedef NumberValidationOptions = {
    var ?greater_than: Float;
    var ?greater_than_or_equal_to: Float;
    var ?less_than: Float;
    var ?less_than_or_equal_to: Float;
    var ?equal_to: Float;
    var ?not_equal_to: Float;
    var ?message: String;
}

/**
 * Table builder for migrations
 */
typedef TableBuilder = {
    function add(name: String, type: String, ?options: FieldOptions): TableBuilder;
    function remove(name: String): TableBuilder;
    function modify(name: String, type: String, ?options: FieldOptions): TableBuilder;
    function timestamps(?options: TimestampsOptions): TableBuilder;
    function references(name: String, table: String, ?options: ReferenceOptions): TableBuilder;
}

/**
 * Drop table options
 */
typedef DropTableOptions = {
    var ?if_exists: Bool;
    var ?cascade: Bool;
}

/**
 * Reference options for foreign keys
 */
typedef ReferenceOptions = {
    var ?column: String;
    var ?type: String;
    var ?on_delete: OnDeleteAction;
    var ?on_update: OnUpdateAction;
}

/**
 * On update actions
 */
enum OnUpdateAction {
    Nothing;
    Restrict;
    Update_all;
    Nilify_all;
}

/**
 * Index options
 */
typedef IndexOptions = {
    var ?unique: Bool;
    var ?name: String;
    var ?concurrently: Bool;
    var ?usingIndex: String;
    var ?prefix: String;
    var ?where: String;
    var ?if_not_exists: Bool;
    var ?if_exists: Bool;
}

/**
 * Constraint definition
 */
enum ConstraintDefinition {
    Check(condition: String);
    Unique(columns: Array<String>);
    ForeignKey(columns: Array<String>, references: String);
    Exclude(condition: String);
}

/**
 * Query value types for parameterized queries
 */
enum QueryValue {
    String(value: String);
    Integer(value: Int);
    Float(value: Float);
    Boolean(value: Bool);
    Date(value: Dynamic);
    Binary(value: Dynamic);
    Array(values: Array<QueryValue>);
    Field(field: String);
    Fragment(sql: String, params: Array<QueryValue>);
}


/**
 * Order by directions
 */
/**
 * Sort order direction
 *
 * WHAT
 * - Compile to :asc/:desc atoms used in order_by DSL.
 */
@:elixirIdiomatic
enum OrderDirection {
    ASC;
    DESC;
}

/**
 * Import result/option types from standard library
 */
typedef Result<T,E> = haxe.functional.Result<T,E>;
typedef Option<T> = haxe.ds.Option<T>;

// Any type already defined in Phoenix.hx
