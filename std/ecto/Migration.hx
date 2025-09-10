package ecto;

import ecto.DatabaseAdapter;

/**
 * Type-safe Ecto Migration DSL for database schema management
 * 
 * Provides a fluent, typed API for defining database migrations with full
 * compile-time validation. Replaces string-based field definitions with
 * strongly-typed operations.
 * 
 * ## Usage Example
 * 
 * ```haxe
 * @:migration
 * class CreateTodosTable extends Migration {
 *     override function up(): Void {
 *         createTable("todos")
 *             .addColumn("title", String, {nullable: false})
 *             .addColumn("description", Text)
 *             .addColumn("completed", Boolean, {default: false})
 *             .addColumn("priority", String)
 *             .addColumn("due_date", DateTime)
 *             .addColumn("tags", JsonArray)
 *             .addColumn("user_id", References("users"))
 *             .addTimestamps()
 *             .addIndex(["user_id"])
 *             .addIndex(["completed", "due_date"]);
 *     }
 *     
 *     override function down(): Void {
 *         dropTable("todos");
 *     }
 * }
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Column types validated at compile-time**: Can't use invalid types
 * - **Options validated per type**: Only valid options for each column type
 * - **Fluent API with IntelliSense**: Full IDE support for available operations
 * - **Reference integrity**: Foreign keys validated against existing tables
 * - **No string-based errors**: All operations are typed
 * 
 * ## Migration Execution
 * 
 * Migrations compile to standard Ecto migration files that work with Mix:
 * ```bash
 * mix ecto.migrate        # Run pending migrations
 * mix ecto.rollback      # Rollback last migration
 * mix ecto.reset         # Drop, create, and migrate
 * ```
 */
@:autoBuild(reflaxe.elixir.macros.MigrationBuilder.build())
abstract class Migration {
    /**
     * Define forward migration operations
     * Override this method to specify database changes
     */
    abstract public function up(): Void;
    
    /**
     * Define rollback operations
     * Override this method to reverse the changes made in up()
     */
    abstract public function down(): Void;
    
    /**
     * Create a new table with typed column definitions
     */
    public function createTable(name: String, ?options: TableOptions): TableBuilder {
        return new TableBuilder(name, options);
    }
    
    /**
     * Drop an existing table
     */
    public function dropTable(name: String, ?options: DropOptions): Void {
        // Generates: drop table(:table_name)
    }
    
    /**
     * Alter an existing table structure
     */
    public function alterTable(name: String): AlterTableBuilder {
        return new AlterTableBuilder(name);
    }
    
    /**
     * Create an index for performance optimization
     */
    public function createIndex(table: String, columns: Array<String>, ?options: IndexOptions): Void {
        // Generates: create index(:table, [:col1, :col2], options)
    }
    
    /**
     * Drop an existing index
     */
    public function dropIndex(table: String, columns: Array<String>): Void {
        // Generates: drop index(:table, [:col1, :col2])
    }
    
    /**
     * Execute raw SQL for advanced operations
     * Use sparingly - prefer typed operations when possible
     */
    public function execute(sql: String): Void {
        // Generates: execute(sql)
    }
    
    /**
     * Create a database constraint
     */
    public function createConstraint(table: String, name: String, check: String): Void {
        // Generates: create constraint(:table, :name, check: expr)
    }
    
    /**
     * Drop a database constraint
     */
    public function dropConstraint(table: String, name: String): Void {
        // Generates: drop constraint(:table, :name)
    }
}

/**
 * Fluent table builder for creating tables with typed columns
 */
class TableBuilder {
    private var tableName: String;
    private var columns: Array<ColumnDefinition>;
    private var indexes: Array<IndexDefinition>;
    private var constraints: Array<ConstraintDefinition>;
    private var options: TableOptions;
    
    public function new(name: String, ?options: TableOptions) {
        this.tableName = name;
        this.columns = [];
        this.indexes = [];
        this.constraints = [];
        this.options = options != null ? options : {};
        
        #if macro
        // Register this table at compile time for validation
        reflaxe.elixir.macros.MigrationRegistry.registerTable(name, haxe.macro.Context.currentPos());
        #end
    }
    
    /**
     * Add a typed column to the table
     */
    public function addColumn<T>(name: String, type: ColumnType<T>, ?options: ColumnOptions<T>): TableBuilder {
        columns.push({
            name: name,
            type: type,
            options: options
        });
        
        #if macro
        // Register this column at compile time for validation
        var typeStr = Std.string(type);  // Convert enum to string for registry
        var nullable = options != null && options.nullable == true;
        reflaxe.elixir.macros.MigrationRegistry.registerColumn(
            tableName, 
            name, 
            typeStr, 
            nullable, 
            haxe.macro.Context.currentPos()
        );
        #end
        
        return this;
    }
    
    /**
     * Add id column (auto-incrementing primary key)
     */
    public function addId(?name: String = "id", ?type: IdType = AutoIncrement): TableBuilder {
        if (type == AutoIncrement) {
            return addColumn(name, Integer, {
                primaryKey: true,
                autoGenerate: true
            });
        } else {
            return addColumn(name, UUID, {
                primaryKey: true,
                autoGenerate: true
            });
        }
    }
    
    /**
     * Add created_at and updated_at timestamp columns
     */
    public function addTimestamps(): TableBuilder {
        addColumn("inserted_at", DateTime, {nullable: false});
        addColumn("updated_at", DateTime, {nullable: false});
        return this;
    }
    
    /**
     * Add a foreign key reference to another table
     */
    public function addReference(columnName: String, referencedTable: String, ?options: ReferenceOptions): TableBuilder {
        // Cast the reference options to column options
        var columnOptions: ColumnOptions<Int> = null;
        if (options != null) {
            columnOptions = {
                nullable: false,
                onDelete: options.onDelete,
                onUpdate: options.onUpdate
            };
        }
        addColumn(columnName, References(referencedTable), columnOptions);
        return this;
    }
    
    /**
     * Add a foreign key constraint (alias for addReference with constraint syntax)
     */
    public function addForeignKey(columnName: String, referencedTable: String, ?options: ReferenceOptions): TableBuilder {
        #if macro
        // Validate that the referenced table exists at compile time
        reflaxe.elixir.macros.MigrationRegistry.validateTableExists(
            referencedTable, 
            haxe.macro.Context.currentPos()
        );
        
        // Also validate that the column we're creating exists
        reflaxe.elixir.macros.MigrationRegistry.validateColumnExists(
            tableName,
            columnName,
            haxe.macro.Context.currentPos()
        );
        #end
        
        return addReference(columnName, referencedTable, options);
    }
    
    /**
     * Add an index for query performance
     */
    public function addIndex(columns: Array<String>, ?options: IndexOptions): TableBuilder {
        #if macro
        // Validate that all indexed columns exist in the table
        reflaxe.elixir.macros.MigrationRegistry.validateColumnsExist(
            tableName,
            columns,
            haxe.macro.Context.currentPos()
        );
        #end
        
        indexes.push({
            columns: columns,
            options: options
        });
        return this;
    }
    
    /**
     * Add a unique constraint
     */
    public function addUniqueConstraint(columns: Array<String>, ?name: String): TableBuilder {
        constraints.push({
            type: Unique,
            columns: columns,
            name: name,
            expression: null
        });
        return this;
    }
    
    /**
     * Add a check constraint with custom expression
     */
    public function addCheckConstraint(name: String, expression: String): TableBuilder {
        constraints.push({
            type: Check,
            name: name,
            expression: expression,
            columns: null
        });
        return this;
    }
}

/**
 * Fluent builder for altering existing tables
 */
class AlterTableBuilder {
    private var tableName: String;
    private var operations: Array<AlterOperation>;
    
    public function new(name: String) {
        this.tableName = name;
        this.operations = [];
    }
    
    /**
     * Add a new column to existing table
     */
    public function addColumn<T>(name: String, type: ColumnType<T>, ?options: ColumnOptions<T>): AlterTableBuilder {
        operations.push(AddColumn(name, type, options));
        return this;
    }
    
    /**
     * Remove a column from the table
     */
    public function removeColumn(name: String): AlterTableBuilder {
        operations.push(RemoveColumn(name));
        return this;
    }
    
    /**
     * Modify an existing column's type or options
     */
    public function modifyColumn<T>(name: String, type: ColumnType<T>, ?options: ColumnOptions<T>): AlterTableBuilder {
        operations.push(ModifyColumn(name, type, options));
        return this;
    }
    
    /**
     * Rename a column
     */
    public function renameColumn(oldName: String, newName: String): AlterTableBuilder {
        operations.push(RenameColumn(oldName, newName));
        return this;
    }
}

/**
 * Strongly-typed column types for migrations
 * Each type maps to appropriate database types based on adapter
 */
enum ColumnType<T> {
    // Numeric types
    Integer: ColumnType<Int>;
    BigInteger: ColumnType<haxe.Int64>;
    Float: ColumnType<Float>;
    Decimal(precision: Int, scale: Int): ColumnType<Float>;
    
    // String types
    String(?length: Int): ColumnType<String>;
    Text: ColumnType<String>;
    UUID: ColumnType<String>;
    
    // Boolean
    Boolean: ColumnType<Bool>;
    
    // Date/Time types
    Date: ColumnType<Date>;
    Time: ColumnType<Date>;
    DateTime: ColumnType<Date>;
    Timestamp: ColumnType<Date>;
    
    // Binary
    Binary: ColumnType<haxe.io.Bytes>;
    
    // JSON types
    Json: ColumnType<Dynamic>;
    JsonArray: ColumnType<Array<Dynamic>>;
    
    // Array types (PostgreSQL)
    Array(itemType: ColumnType<Dynamic>): ColumnType<Array<T>>;
    
    // Special types
    References(table: String): ColumnType<Int>;
    Enum(values: Array<String>): ColumnType<String>;
}

/**
 * Column options that apply based on column type
 */
typedef ColumnOptions<T> = {
    @:optional var nullable: Bool;
    @:optional var defaultValue: T;
    @:optional var primaryKey: Bool;
    @:optional var autoGenerate: Bool;
    @:optional var unique: Bool;
    @:optional var index: Bool;
    
    // Foreign key options (only for References type)
    @:optional var onDelete: OnDeleteAction;
    @:optional var onUpdate: OnUpdateAction;
}

/**
 * Table creation options
 */
typedef TableOptions = {
    @:optional var primaryKey: Bool;  // false to skip auto-id
    @:optional var engine: String;    // MySQL: InnoDB, MyISAM
    @:optional var charset: String;   // Character set
    @:optional var collation: String; // Collation rules
    @:optional var comment: String;   // Table comment
    @:optional var temporary: Bool;   // Temporary table
}

/**
 * Table dropping options
 */
typedef DropOptions = {
    @:optional var cascade: Bool;     // CASCADE to drop dependent objects
    @:optional var ifExists: Bool;    // IF EXISTS clause
}

/**
 * Index creation options
 */
typedef IndexOptions = {
    @:optional var unique: Bool;
    @:optional var name: String;
    @:optional var method: IndexMethod;  // btree, hash, gin, gist (PostgreSQL)
    @:optional var where: String;       // Partial index condition
    @:optional var concurrently: Bool;  // CREATE INDEX CONCURRENTLY
}

/**
 * Index methods for different databases
 */
enum IndexMethod {
    BTree;
    Hash;
    Gin;   // PostgreSQL: Generalized Inverted Index
    Gist;  // PostgreSQL: Generalized Search Tree
    Brin;  // PostgreSQL: Block Range Index
}

/**
 * Foreign key reference options
 */
typedef ReferenceOptions = {
    @:optional var column: String;      // Referenced column (default: id)
    @:optional var onDelete: OnDeleteAction;
    @:optional var onUpdate: OnUpdateAction;
}

/**
 * Actions for foreign key constraints
 */
enum OnDeleteAction {
    Restrict;   // Prevent deletion if references exist
    Cascade;    // Delete dependent records
    SetNull;    // Set foreign key to NULL
    NoAction;   // Database default behavior
}

/**
 * Actions for foreign key updates
 */
enum OnUpdateAction {
    Restrict;   // Prevent update if references exist
    Cascade;    // Update dependent records
    SetNull;    // Set foreign key to NULL
    NoAction;   // Database default behavior
}

/**
 * ID column types
 */
enum IdType {
    AutoIncrement;  // Integer auto-increment
    UUID;          // UUID primary key
}

/**
 * Internal: Column definition structure
 */
private typedef ColumnDefinition = {
    var name: String;
    var type: ColumnType<Dynamic>;
    var options: Null<ColumnOptions<Dynamic>>;
}

/**
 * Internal: Index definition structure
 */
private typedef IndexDefinition = {
    var columns: Array<String>;
    var options: Null<IndexOptions>;
}

/**
 * Internal: Constraint definition structure
 */
private typedef ConstraintDefinition = {
    var type: ConstraintType;
    var name: Null<String>;
    var columns: Null<Array<String>>;
    var expression: Null<String>;
}

/**
 * Constraint types
 */
private enum ConstraintType {
    Unique;
    Check;
    Exclusion;
}

/**
 * Alter table operations
 */
private enum AlterOperation {
    AddColumn(name: String, type: ColumnType<Dynamic>, options: Null<ColumnOptions<Dynamic>>);
    RemoveColumn(name: String);
    ModifyColumn(name: String, type: ColumnType<Dynamic>, options: Null<ColumnOptions<Dynamic>>);
    RenameColumn(oldName: String, newName: String);
}

