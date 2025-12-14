# Migration Validation System

## Overview

The Migration validation system provides compile-time validation for Ecto migrations, ensuring database schema integrity before runtime. This system catches common migration errors at compilation time, preventing runtime failures and database inconsistencies.

## Architecture

### Components

1. **MigrationBuilder Macro** (`src/reflaxe/elixir/macros/MigrationBuilder.hx`)
   - Build macro that processes @:migration classes
   - Analyzes up() and down() methods for schema operations
   - Tracks migration dependencies and ordering

2. **MigrationRegistry** (`src/reflaxe/elixir/macros/MigrationBuilder.hx`)
   - Compile-time schema state tracking
   - Validates table and column references
   - Ensures foreign key integrity

3. **Migration DSL** (`std/ecto/Migration.hx`)
   - Type-safe fluent API for defining migrations
   - TableBuilder for creating tables with columns
   - AlterTableBuilder for modifying existing tables

## How It Works

### 1. Migration Declaration

```haxe
@:migration
class CreateTodosTable extends Migration {
    override function up(): Void {
        createTable("todos")
            .addColumn("title", String, {nullable: false})
            .addColumn("completed", Boolean, {default: false})
            .addColumn("user_id", References("users"))
            .addTimestamps();
    }
    
    override function down(): Void {
        dropTable("todos");
    }
}
```

### 2. Compile-Time Processing

When the Haxe compiler encounters a `@:migration` class:

1. **MigrationBuilder.build()** is invoked as a build macro
2. The macro analyzes the `up()` and `down()` methods
3. Each operation is tracked in the MigrationRegistry
4. References are validated against the registry

### 3. Registry Operations

The MigrationRegistry maintains compile-time state:

```haxe
// When createTable("todos") is encountered:
MigrationRegistry.registerTable("todos", position);

// When addColumn() is called in TableBuilder:
MigrationRegistry.registerColumn("todos", "title", "String", false, position);

// When addReference() creates a foreign key:
MigrationRegistry.validateTableExists("users", position);
```

### 4. Validation Examples

#### Table Existence Validation

```haxe
// This will cause a compile error if "users" table doesn't exist:
createTable("posts")
    .addColumn("author_id", References("users"));
// Error: Table "users" does not exist. Make sure the migration that creates it runs first.
```

#### Column Existence Validation

```haxe
// This will cause a compile error if columns don't exist:
createIndex("todos", ["user_id", "nonexistent_column"]);
// Error: Column "nonexistent_column" does not exist in table "todos"
```

#### Circular Reference Detection

```haxe
// The system detects and prevents circular foreign key references
createTable("users")
    .addColumn("profile_id", References("profiles"));

createTable("profiles")
    .addColumn("user_id", References("users"));
// Warning: Circular reference detected between tables
```

## Benefits

### 1. Early Error Detection
- **Compile-time validation**: Errors caught before deployment
- **No runtime surprises**: Invalid migrations won't compile
- **Faster development**: Immediate feedback on schema changes

### 2. Schema Integrity
- **Foreign key validation**: References are checked at compile time
- **Type consistency**: Column types validated across migrations
- **Dependency ordering**: Ensures migrations run in correct order

### 3. Better Developer Experience
- **Clear error messages**: Precise location of schema violations
- **IntelliSense support**: Full IDE support for migration DSL
- **Self-documenting**: Type signatures show available options

## Implementation Details

### TableBuilder Pattern

The TableBuilder uses a fluent API with compile-time column registration:

```haxe
public function addColumn<T>(name: String, type: ColumnType<T>, ?options: ColumnOptions<T>): TableBuilder {
    columns.push({
        name: name,
        type: type,
        options: options
    });
    
    #if macro
    // Register column at compile time for validation
    MigrationRegistry.registerColumn(tableName, name, typeStr, nullable, Context.currentPos());
    #end
    
    return this;
}
```

### Foreign Key Validation

Foreign keys are validated immediately at compile time:

```haxe
public function addForeignKey(columnName: String, referencedTable: String, ?options: ReferenceOptions): TableBuilder {
    #if macro
    // Validate that the referenced table exists
    MigrationRegistry.validateTableExists(referencedTable, Context.currentPos());
    
    // Validate that the column we're creating exists
    MigrationRegistry.validateColumnExists(tableName, columnName, Context.currentPos());
    #end
    
    return addReference(columnName, referencedTable, options);
}
```

### Error Reporting

The system provides clear, actionable error messages:

```haxe
public static function validateTableExists(name: String, pos: Position): Void {
    if (!tables.exists(name)) {
        Context.error('Table "$name" does not exist. Make sure the migration that creates it runs first.', pos);
    }
}
```

## Usage Guidelines

### Best Practices

1. **Order migrations correctly**: Create referenced tables before dependent tables
2. **Use typed column definitions**: Leverage the ColumnType<T> system
3. **Validate constraints**: Add check constraints for data integrity
4. **Document migrations**: Include comments explaining schema decisions

### Common Patterns

#### Adding Indexes

```haxe
createTable("posts")
    .addColumn("user_id", References("users"))
    .addColumn("published_at", DateTime)
    .addIndex(["user_id", "published_at"]); // Composite index
```

#### Altering Tables

```haxe
alterTable("users")
    .addColumn("avatar_url", String)
    .modifyColumn("email", String, {unique: true})
    .renameColumn("name", "full_name");
```

#### Complex Constraints

```haxe
createTable("orders")
    .addColumn("total", Decimal(10, 2))
    .addColumn("status", Enum(["pending", "paid", "shipped"]))
    .addCheckConstraint("positive_total", "total > 0");
```

## Future Enhancements

### Planned Features

1. **Migration rollback validation**: Ensure down() correctly reverses up()
2. **Data migration support**: Type-safe data transformation helpers
3. **Schema diffing**: Automatic migration generation from schema changes
4. **Multi-database support**: Validate against different database adapters

### Integration Points

1. **Mix task integration**: `mix haxe.gen.migration` for scaffolding
2. **Schema introspection**: Compare compile-time schema with runtime database
3. **Documentation generation**: Auto-generate schema documentation

## Technical Implementation

### Macro-Time vs Runtime

The validation system operates entirely at macro-time (compile-time):

- **Macro-time**: All validation happens during Haxe compilation
- **No runtime overhead**: Zero performance impact on migrations
- **Static analysis**: Complete schema graph available for optimization

### Metadata Storage

Migration metadata is stored using Haxe's metadata system:

```haxe
// Migration name stored as metadata
localClass.meta.add(":migrationName", [macro $v{migrationName}], localClass.pos);

// Timestamp for file naming
localClass.meta.add(":migrationTimestamp", [macro $v{timestamp}], localClass.pos);
```

## Troubleshooting

### Common Issues

#### "Table does not exist" Error
- **Cause**: Referencing a table before it's created
- **Solution**: Reorder migrations or create tables in correct sequence

#### "Column does not exist" Error
- **Cause**: Indexing or referencing non-existent columns
- **Solution**: Ensure columns are added before being referenced

#### Missing @:migration Annotation
- **Cause**: Migration class not marked with @:migration
- **Solution**: Add `@:migration` to the class declaration

## Summary

The Migration validation system transforms database schema management from a runtime concern to a compile-time guarantee. By catching schema errors before deployment, it provides confidence in database migrations and reduces production incidents related to schema inconsistencies.