package phoenix;

/**
 * Basic Ecto operations extern definitions for type-safe database interactions
 * Provides essential CRUD operations and query building interfaces
 */
extern class Ecto {
    
    /**
     * Ecto.Repo interface for database operations
     */
    extern class Repo {
        /**
         * Insert a struct or changeset into the database
         */
        static function insert<T>(struct_or_changeset: T): {ok: T} | {error: Dynamic};
        
        /**
         * Insert a struct or changeset, raising on error
         */
        static function insert!<T>(struct_or_changeset: T): T;
        
        /**
         * Get a single record by ID
         */
        static function get<T>(queryable: Class<T>, id: Dynamic): Null<T>;
        
        /**
         * Get a single record by ID, raising if not found
         */
        static function get!<T>(queryable: Class<T>, id: Dynamic): T;
        
        /**
         * Get a single record by query conditions
         */
        static function get_by<T>(queryable: Class<T>, clauses: Dynamic): Null<T>;
        
        /**
         * Update a record with changes
         */
        static function update<T>(changeset: T): {ok: T} | {error: Dynamic};
        
        /**
         * Update a record with changes, raising on error
         */
        static function update!<T>(changeset: T): T;
        
        /**
         * Delete a record
         */
        static function delete<T>(struct_or_changeset: T): {ok: T} | {error: Dynamic};
        
        /**
         * Delete a record, raising on error
         */
        static function delete!<T>(struct_or_changeset: T): T;
        
        /**
         * Execute a query and return all results
         */
        static function all<T>(query: Dynamic): Array<T>;
        
        /**
         * Execute a query and return one result
         */
        static function one<T>(query: Dynamic): Null<T>;
        
        /**
         * Execute a query and return one result, raising if not found
         */
        static function one!<T>(query: Dynamic): T;
    }
    
    /**
     * Ecto.Schema for defining database schemas
     */
    extern class Schema {
        /**
         * Define a schema with the given table name and fields
         */
        macro static function schema(table_name: String, fields: Dynamic): Dynamic;
        
        /**
         * Primary key field definition
         */
        static function field(name: String, type: Dynamic, ?opts: Dynamic): Dynamic;
        
        /**
         * Association definitions
         */
        static function belongs_to(name: String, schema: Dynamic, ?opts: Dynamic): Dynamic;
        static function has_one(name: String, schema: Dynamic, ?opts: Dynamic): Dynamic;
        static function has_many(name: String, schema: Dynamic, ?opts: Dynamic): Dynamic;
        static function many_to_many(name: String, schema: Dynamic, ?opts: Dynamic): Dynamic;
        
        /**
         * Timestamp fields (inserted_at, updated_at)
         */
        static function timestamps(?opts: Dynamic): Dynamic;
    }
    
    /**
     * Ecto.Changeset for data validation and casting
     */
    extern class Changeset {
        /**
         * Create a changeset for the given struct and params
         */
        static function cast<T>(struct: T, params: Dynamic, permitted: Array<String>): Dynamic;
        
        /**
         * Validate required fields
         */
        static function validate_required(changeset: Dynamic, fields: Array<String>): Dynamic;
        
        /**
         * Validate field length
         */
        static function validate_length(changeset: Dynamic, field: String, opts: Dynamic): Dynamic;
        
        /**
         * Validate field format (regex)
         */
        static function validate_format(changeset: Dynamic, field: String, format: Dynamic): Dynamic;
        
        /**
         * Validate field uniqueness
         */
        static function unique_constraint(changeset: Dynamic, field: String, ?opts: Dynamic): Dynamic;
        
        /**
         * Add a custom validation function
         */
        static function validate_change(changeset: Dynamic, field: String, validator: Dynamic): Dynamic;
        
        /**
         * Check if changeset is valid
         */
        static function valid?(changeset: Dynamic): Bool;
        
        /**
         * Apply changes from a changeset to a struct
         */
        static function apply_changes<T>(changeset: Dynamic): T;
    }
    
    /**
     * Ecto.Query for building database queries
     */
    extern class Query {
        /**
         * Create a query from a schema
         */
        static function from<T>(schema: Class<T>): Dynamic;
        
        /**
         * Add a where clause to a query
         */
        static function where(query: Dynamic, conditions: Dynamic): Dynamic;
        
        /**
         * Add a select clause to a query
         */
        static function select(query: Dynamic, fields: Dynamic): Dynamic;
        
        /**
         * Add ordering to a query
         */
        static function order_by(query: Dynamic, ordering: Dynamic): Dynamic;
        
        /**
         * Limit query results
         */
        static function limit(query: Dynamic, count: Int): Dynamic;
        
        /**
         * Offset query results
         */
        static function offset(query: Dynamic, count: Int): Dynamic;
        
        /**
         * Join with another table
         */
        static function join(query: Dynamic, join_type: String, table: Dynamic, ?on: Dynamic): Dynamic;
        
        /**
         * Preload associations
         */
        static function preload(query: Dynamic, associations: Dynamic): Dynamic;
    }
}