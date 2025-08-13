package phoenix;

/**
 * Basic Ecto operations extern definitions for type-safe database interactions
 * Provides essential CRUD operations and query building interfaces
 */

/**
 * Ecto.Repo interface for database operations
 */
@:native("Ecto.Repo")
extern class EctoRepo {
        /**
         * Insert a struct or changeset into the database
         */
        static function insert<T>(struct_or_changeset: T): Dynamic;
        
        /**
         * Insert a struct or changeset, raising on error
         */
        @:native("insert!")
        static function insertBang<T>(struct_or_changeset: T): T;
        
        /**
         * Get a single record by ID
         */
        static function get<T>(queryable: Class<T>, id: Dynamic): Null<T>;
        
        /**
         * Get a single record by ID, raising if not found
         */
        @:native("get!")
        static function getBang<T>(queryable: Class<T>, id: Dynamic): T;
        
        /**
         * Get a single record by query conditions
         */
        static function get_by<T>(queryable: Class<T>, clauses: Dynamic): Null<T>;
        
        /**
         * Update a record with changes
         */
        static function update<T>(changeset: T): Dynamic;
        
        /**
         * Update a record with changes, raising on error
         */
        @:native("update!")
        static function updateBang<T>(changeset: T): T;
        
        /**
         * Delete a record
         */
        static function delete<T>(struct_or_changeset: T): Dynamic;
        
        /**
         * Delete a record, raising on error
         */
        @:native("delete!")
        static function deleteBang<T>(struct_or_changeset: T): T;
        
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
        @:native("one!")
        static function oneBang<T>(query: Dynamic): T;
}

/**
 * Ecto.Schema for defining database schemas
 */
@:native("Ecto.Schema")
extern class EctoSchema {
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
@:native("Ecto.Changeset")
extern class EctoChangeset {
        /**
         * Create a changeset for the given struct and params (renamed to avoid 'cast' keyword)
         */
        @:native("Ecto.Changeset.cast")
        static function changeset_cast<T>(struct: T, params: Dynamic, permitted: Array<String>): Dynamic;
        
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
         * Validates that a field value is in a list of options
         */
        static function validate_inclusion(changeset: Dynamic, field: String, list: Array<String>): Dynamic;
        
        /**
         * Adds a foreign key constraint validation
         * @param changeset The changeset to add constraint to
         * @param field The field name containing the foreign key
         * @param opts Optional configuration (name, message)
         */
        static function foreign_key_constraint(changeset: Dynamic, field: String, ?opts: Dynamic): Dynamic;
        
        /**
         * Check if changeset is valid
         */
        @:native("valid?")
        static function isValid(changeset: Dynamic): Bool;
        
        /**
         * Apply changes from a changeset to a struct
         */
        static function apply_changes<T>(changeset: Dynamic): T;
}

/**
 * Ecto.Query for building database queries
 */
@:native("Ecto.Query")
extern class EctoQuery {
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

// Ecto namespace class removed - use extern classes directly
// Access via: phoenix.Ecto.EctoRepo, phoenix.Ecto.EctoChangeset, etc.