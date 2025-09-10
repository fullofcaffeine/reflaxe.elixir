# Type-Safe Query System Architecture

## Overview

The Reflaxe.Elixir Type-Safe Query System provides compile-time validation of database queries while maintaining full compatibility with Ecto's powerful query capabilities. This system consists of three integrated components:

1. **Typed Migration DSL** - Fluent API for defining database structure
2. **Automatic Schema Synchronization** - Migrations auto-generate/update schema types
3. **Type-Safe Query Builder** - Compile-time validated queries with escape hatches

## Problem Statement

Traditional Ecto queries have several limitations:
- **No compile-time field validation** - Typos in field names only caught at runtime
- **Manual schema synchronization** - Developers must manually update schemas after migrations
- **String-based queries** - No IntelliSense or type checking for query conditions
- **Disconnected systems** - Migrations, schemas, and queries are separate, unvalidated systems

## Solution Architecture

### 1. Typed Migration DSL (`std/ecto/Migration.hx`)

Provides a fluent, type-safe API for defining database migrations:

```haxe
@:migration
class CreateTodos extends Migration {
    public function up(): Void {
        createTable("todos")
            .addColumn("title", String(), {nullable: false})
            .addColumn("completed", Boolean, {defaultValue: false})
            .addColumn("due_date", DateTime)
            .addColumn("user_id", References("users"))
            .addTimestamps()
            .addIndex(["user_id"])
            .addUniqueConstraint(["title", "user_id"]);
    }
    
    public function down(): Void {
        dropTable("todos");
    }
}
```

**Benefits:**
- Compile-time validation of column types
- Type-safe options (no invalid option combinations)
- IntelliSense for available operations
- Generates idiomatic Ecto migrations

### 2. Migration-to-Schema Synchronization (`MigrationSyncMacro.hx`)

Automatically generates and updates schema types from migrations:

```haxe
// Before: Manual schema definition (error-prone)
@:schema
class Todo {
    public var id: Int;
    public var title: String;          // Must match migration
    public var completed: Bool;        // Easy to get out of sync
    public var due_date: Date;         // Type mismatches possible
    // ... manually maintained
}

// After: Auto-synchronized from migration
@:syncWithMigration("CreateTodos")
@:schema 
class Todo {
    // Fields auto-generated from migration at compile time!
    // Always in sync with database structure
}
```

**How it works:**
1. Macro scans migration files at compile time
2. Extracts table structure and column definitions
3. Generates corresponding Haxe fields with correct types
4. Preserves custom methods while updating fields
5. Adds appropriate metadata (`@:primary_key`, `@:default`, etc.)

### 3. Type-Safe Query Builder (`std/ecto/TypedQuery.hx`)

Provides compile-time validated queries with lambda-based field access:

```haxe
// Type-safe queries with compile-time validation
var query = TypedQuery.from(Todo)
    .where(todo -> todo.completed == true)           // ✅ Field exists, type matches
    .where(todo -> todo.priority == "high")          // ✅ String comparison valid
    .select(todo -> {                                // ✅ Projection type-checked
        id: todo.id,
        title: todo.title,
        dueDate: todo.dueDate
    })
    .orderBy(todo -> todo.dueDate, Desc)            // ✅ Field is sortable
    .limit(10);

// Compile-time errors for invalid queries
var bad = TypedQuery.from(Todo)
    .where(todo -> todo.nonexistent == true)        // ❌ Compile error: field doesn't exist
    .where(todo -> todo.completed == "yes")         // ❌ Compile error: Bool != String
    .orderBy(todo -> todo.tags, Asc);               // ❌ Compile error: Can't sort JSON field

// Escape hatches for complex queries
var complex = TypedQuery.from(Todo)
    .whereRaw("completed = ? AND due_date < NOW()", [true])
    .joinRaw("LEFT JOIN users u ON u.id = todos.user_id")
    .selectRaw("todos.*, u.name as user_name");

// Direct Ecto access when needed
var ectoQuery = typedQuery.toEctoQuery();  // Get underlying Ecto.Query
```

## Implementation Details

### Macro Processing Pipeline

1. **Build Phase**: When compiling a schema with `@:syncWithMigration`
   - Parse migration file to extract structure
   - Generate field definitions with proper types
   - Apply Ecto metadata for runtime

2. **Query Compilation**: When using TypedQuery
   - Lambda expressions parsed at macro time
   - Field access validated against schema type
   - Generate proper Ecto query calls

### Type Mapping

| Migration Type | Haxe Type | Ecto Type | SQL Type |
|---------------|-----------|-----------|----------|
| String() | String | :string | VARCHAR |
| Text | String | :text | TEXT |
| Integer | Int | :integer | INTEGER |
| Boolean | Bool | :boolean | BOOLEAN |
| DateTime | Date | :naive_datetime | TIMESTAMP |
| Json | Dynamic | :map | JSON/JSONB |
| References("table") | Int | :integer + FK | INTEGER |

### Field Validation Rules

1. **Existence**: Field must exist in schema
2. **Type compatibility**: Comparisons must be type-safe
3. **Nullability**: Null checks only on nullable fields
4. **Relationships**: Foreign keys validated against referenced tables

## Usage Patterns

### Basic CRUD with Type Safety

```haxe
// CREATE - Type-safe insertion
var todo = new Todo();
todo.title = "Implement type safety";  // ✅ Compile-time field validation
todo.completed = false;
Repo.insert(todo);

// READ - Type-safe queries
var completed = TypedQuery.from(Todo)
    .where(t -> t.completed == true)
    .orderBy(t -> t.updatedAt, Desc)
    .all();

// UPDATE - Type-safe updates
TypedQuery.from(Todo)
    .where(t -> t.id == todoId)
    .update(t -> {
        t.completed = true;
        t.updatedAt = Date.now();
    });

// DELETE - Type-safe deletion
TypedQuery.from(Todo)
    .where(t -> t.id == todoId)
    .delete();
```

### Complex Queries with Escape Hatches

```haxe
// Mix typed and raw for complex queries
var results = TypedQuery.from(Todo)
    // Type-safe where clause
    .where(t -> t.userId == currentUser.id)
    // Raw SQL for complex date logic
    .whereRaw("due_date BETWEEN ? AND ?", [startDate, endDate])
    // Type-safe join
    .join(t -> t.user)
    // Raw aggregation
    .selectRaw("""
        todos.*,
        users.name as user_name,
        COUNT(comments.id) as comment_count
    """)
    .groupBy(t -> t.id)
    .all();
```

### Migration-Driven Development

```haxe
// 1. Define migration (single source of truth)
@:migration
class AddPriorityToTodos extends Migration {
    public function up(): Void {
        alterTable("todos")
            .addColumn("priority", Enum(["low", "medium", "high"]), {
                defaultValue: "medium"
            });
    }
}

// 2. Schema auto-updates (no manual changes needed)
@:syncWithMigration("AddPriorityToTodos")
@:schema
class Todo {
    // priority field automatically added with correct type!
}

// 3. Queries immediately use new field (type-safe)
var highPriority = TypedQuery.from(Todo)
    .where(t -> t.priority == "high")  // ✅ Field exists, enum validated
    .all();
```

## Benefits

### Developer Experience
- **IntelliSense everywhere**: Full autocomplete for fields and operations
- **Compile-time safety**: Catch errors before runtime
- **Refactoring support**: Rename fields across entire codebase
- **Self-documenting**: Types serve as documentation

### Maintenance
- **Single source of truth**: Migrations define structure
- **No manual sync**: Schemas always match database
- **Less boilerplate**: Fluent APIs reduce code
- **Gradual adoption**: Can mix with existing Ecto code

### Performance
- **Zero runtime overhead**: All validation at compile time
- **Optimal queries**: Generates same Ecto queries
- **Escape hatches**: Can optimize when needed
- **Streaming support**: Handle large datasets efficiently

## Comparison with Raw Ecto

| Feature | Raw Ecto | Type-Safe Query System |
|---------|----------|------------------------|
| Field validation | Runtime | Compile-time |
| Type checking | None | Full |
| IntelliSense | Limited | Complete |
| Schema sync | Manual | Automatic |
| Complex queries | ✅ Native | ✅ Via escape hatches |
| Learning curve | Ecto only | Ecto + typed API |
| Migration safety | String-based | Type-safe |

## Future Enhancements

### Planned Features
1. **Relationship mapping**: Type-safe associations and preloading
2. **Query composition**: Reusable query fragments
3. **Migration diffing**: Auto-generate migrations from schema changes
4. **Query optimization hints**: Compile-time performance suggestions
5. **Multi-database support**: Type-safe queries across databases

### Experimental Ideas
- **Query visualization**: Generate query execution plans at compile time
- **Test generation**: Auto-generate tests from schema definitions
- **GraphQL integration**: Generate GraphQL schemas from Haxe types
- **Real-time subscriptions**: Type-safe Phoenix channels from queries

## Migration Guide

### From Raw Ecto to Type-Safe Queries

```haxe
// Before: Raw Ecto (no compile-time validation)
var query = from(t in "todos",
    where: t.completed == true and t.prority == "high",  // Typo! Runtime error
    select: t
);

// After: Type-safe (compile-time validation)  
var query = TypedQuery.from(Todo)
    .where(t -> t.completed == true)
    .where(t -> t.priority == "high")  // Typo caught at compile time!
    .all();
```

### Gradual Migration Strategy

1. **Phase 1**: Add `@:syncWithMigration` to existing schemas
2. **Phase 2**: Replace simple queries with TypedQuery
3. **Phase 3**: Convert complex queries using escape hatches
4. **Phase 4**: Refactor to use typed migrations

## Best Practices

### Do's
- ✅ Use typed queries by default
- ✅ Keep migrations as source of truth
- ✅ Use escape hatches for complex queries
- ✅ Test generated SQL in development
- ✅ Document why when using raw queries

### Don'ts
- ❌ Don't manually edit synchronized schemas
- ❌ Don't fight the type system - use escape hatches
- ❌ Don't over-optimize - profile first
- ❌ Don't mix migration tools
- ❌ Don't ignore compile warnings

## Troubleshooting

### Common Issues

**Issue**: "Field not found" compile error
**Solution**: Ensure migration has run and schema is synchronized

**Issue**: Type mismatch in query
**Solution**: Check migration column type matches query usage

**Issue**: Complex query doesn't fit typed API
**Solution**: Use `whereRaw()`, `selectRaw()`, or `toEctoQuery()` escape hatches

**Issue**: Schema out of sync with database
**Solution**: Re-run migrations and recompile with `--force`

## Conclusion

The Type-Safe Query System brings compile-time safety to database operations while preserving Ecto's power and flexibility. By treating migrations as the single source of truth and automatically synchronizing schemas, we eliminate entire classes of runtime errors while improving developer productivity through better tooling support.