# Cross-Migration Validation PRD

## Product Requirements Document: Cross-Migration Compile-Time Validation

**Version**: 1.0  
**Date**: 2025-01-10  
**Author**: Reflaxe.Elixir Team  
**Status**: Proposed

---

## Executive Summary

Currently, our compile-time migration validation only works within a single migration class. This PRD outlines how to extend the validation system to work across multiple migration files, enabling comprehensive schema validation across an entire application's migration history.

## Current Implementation Status

### What's Already Implemented ✅

As of 2025-01-10, we have successfully implemented **single-migration validation** with the following components:

#### 1. **MigrationRegistry.hx**
- Maintains compile-time registry of tables and columns
- Validates table existence for foreign keys
- Validates column existence for indexes
- Provides typo suggestions using Levenshtein distance
- Location: `/src/reflaxe/elixir/macros/MigrationRegistry.hx`

#### 2. **MigrationValidator.hx**
- Build macro that analyzes migration AST at compile time
- Extracts table and column operations from up() methods
- Integrates with MigrationRegistry for validation
- Location: `/src/reflaxe/elixir/macros/MigrationValidator.hx`

#### 3. **Migration.hx Integration**
- `@:autoBuild` macro on base Migration class
- Automatic validation for all migration subclasses
- Location: `/std/ecto/Migration.hx`

#### 4. **Fixed Column Type Generation**
- Enum constructors now generate proper atoms (`{:Integer}`) instead of indices (`{0}`)
- Fix location: `/src/reflaxe/elixir/ast/ElixirASTBuilder.hx` line 1383-1392

### How Current Validation Works

```haxe
@:migration
class CreateTables extends Migration {
    public function up(): Void {
        // This table is registered when createTable is called
        createTable("users")
            .addColumn("id", ColumnType.Integer, {primaryKey: true})
            .addColumn("email", ColumnType.String())
            .addTimestamps();
        
        // This WORKS - validates within same migration
        createTable("posts")
            .addColumn("user_id", ColumnType.Integer)
            .addForeignKey("user_id", "users");  // ✅ Validates "users" exists
    }
}
```

### Current Validation Capabilities

| Feature | Status | Notes |
|---------|--------|-------|
| Column type generation | ✅ Working | Generates proper Elixir atoms |
| Table registration | ✅ Working | Within single migration |
| Column registration | ✅ Working | Within single migration |
| Foreign key validation | ✅ Working | Within single migration |
| Index column validation | ✅ Working | Within single migration |
| Typo suggestions | ✅ Working | Levenshtein distance algorithm |
| Cross-migration validation | ❌ Not implemented | This PRD addresses this |

## Problem Statement

### Current Limitations Beyond Single Migration

#### Example: What Doesn't Work Today

```haxe
// Migration 1: CreateUsers.hx
@:migration
class CreateUsers extends Migration {
    public function up(): Void {
        createTable("users")
            .addColumn("id", ColumnType.Integer, {primaryKey: true})
            .addColumn("email", ColumnType.String());
    }
}

// Migration 2: CreatePosts.hx (different file)
@:migration  
class CreatePosts extends Migration {
    public function up(): Void {
        createTable("posts")
            .addColumn("id", ColumnType.Integer, {primaryKey: true})
            .addColumn("user_id", ColumnType.Integer)
            // ❌ This DOES NOT validate currently - "users" table is in different migration
            .addForeignKey("user_id", "users");  // No compile error, but fails at runtime!
    }
}
```

#### Specific Limitations

1. **Single Migration Scope**: Validation only works within one migration class
   - Cannot validate foreign keys to tables created in different migrations
   - Cannot detect if a table already exists from a previous migration
   - Cannot validate column references across migration boundaries
   - **Current workaround**: Developers must manually ensure correctness

2. **Migration Order Dependency**: No awareness of migration execution order
   - Cannot determine which tables exist at any point in time
   - Cannot validate rollback safety across migrations
   - **Risk**: Migrations may fail in production due to wrong order

3. **Schema Evolution Tracking**: No holistic view of schema changes
   - Cannot detect conflicting alterations to the same table
   - Cannot validate that drops are safe (no dependent tables)
   - **Risk**: Schema inconsistencies only discovered at runtime

### Impact

- Developers still encounter runtime errors for cross-migration issues
- No compile-time guarantee of migration sequence validity
- Potential for production migration failures

## Proposed Solution

### High-Level Architecture

```
┌─────────────────────────────────────────┐
│         Migration Scanner                │
│  (Discovers all migration files)         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      Migration Order Resolver            │
│  (Determines execution sequence)         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│    Incremental Schema Builder            │
│  (Builds schema state at each step)      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│     Cross-Migration Validator            │
│  (Validates references & constraints)    │
└─────────────────────────────────────────┘
```

### Implementation Strategy

**Note**: This builds upon our existing infrastructure (MigrationRegistry, MigrationValidator) by extending their scope from single-migration to cross-migration validation.

#### Phase 1: Migration Discovery & Ordering

**1.1 Migration Scanner Macro**
```haxe
class MigrationScanner {
    /**
     * Scan project for all @:migration classes
     * Use Haxe's type system to discover migrations at compile time
     */
    public static function discoverMigrations(): Array<MigrationInfo> {
        var migrations = [];
        
        // Use Context.onGenerate to process all types
        for (type in Context.getAllModuleTypes()) {
            switch(type) {
                case TInst(classRef, _):
                    var cls = classRef.get();
                    if (cls.meta.has(":migration")) {
                        migrations.push(extractMigrationInfo(cls));
                    }
                default:
            }
        }
        
        return migrations;
    }
}
```

**1.2 Timestamp-Based Ordering**
```haxe
typedef MigrationInfo = {
    var className: String;
    var timestamp: String;  // Extract from class name or metadata
    var filePath: String;
    var operations: Array<SchemaOperation>;
}

// Sort migrations by timestamp to determine execution order
migrations.sort((a, b) -> Reflect.compare(a.timestamp, b.timestamp));
```

#### Phase 2: Incremental Schema Building

**2.1 Schema State Tracking**
```haxe
class SchemaState {
    var tables: Map<String, TableState>;
    var executedMigrations: Array<String>;
    
    /**
     * Apply a migration's operations to the current schema state
     */
    public function applyMigration(migration: MigrationInfo): ValidationResult {
        var result = new ValidationResult();
        
        for (op in migration.operations) {
            switch(op) {
                case CreateTable(name, columns):
                    if (tables.exists(name)) {
                        result.addError('Table $name already exists');
                    }
                    tables.set(name, {name: name, columns: columns});
                    
                case AddColumn(table, column):
                    if (!tables.exists(table)) {
                        result.addError('Cannot add column to non-existent table $table');
                    }
                    
                case AddForeignKey(table, column, referencedTable):
                    if (!tables.exists(referencedTable)) {
                        result.addError('Foreign key references non-existent table $referencedTable');
                    }
                    
                // ... other operations
            }
        }
        
        return result;
    }
}
```

**2.2 Rollback Validation**
```haxe
/**
 * Validate that down() methods can safely rollback
 */
public function validateRollback(migration: MigrationInfo): ValidationResult {
    // Check for dependent tables before drops
    // Ensure foreign keys are removed before referenced tables
    // Validate that rollback leaves schema in consistent state
}
```

#### Phase 3: Integration Points

**3.1 Compiler Integration**

Option A: **Initialize Hook**
```haxe
class CompilerInit {
    public static function Start() {
        // Before any compilation, run cross-migration validation
        var validator = new CrossMigrationValidator();
        var results = validator.validateAll();
        
        if (results.hasErrors()) {
            for (error in results.errors) {
                Context.error(error.message, error.position);
            }
        }
        
        // Continue with normal compilation
        ElixirCompiler.compile();
    }
}
```

Option B: **Build Macro on Base Migration Class**
```haxe
@:autoBuild(CrossMigrationValidator.validateProject())
abstract class Migration {
    // Validation runs once when first Migration is processed
    // Results cached for subsequent migrations
}
```

**3.2 Persistent Schema Cache**

```haxe
class SchemaCache {
    static final CACHE_FILE = ".haxe/migration-schema.json";
    
    /**
     * Save schema state to disk for incremental compilation
     */
    public static function save(state: SchemaState): Void {
        var json = haxe.Json.stringify(state);
        sys.io.File.saveContent(CACHE_FILE, json);
    }
    
    /**
     * Load cached schema state
     */
    public static function load(): Null<SchemaState> {
        if (!sys.FileSystem.exists(CACHE_FILE)) return null;
        var json = sys.io.File.getContent(CACHE_FILE);
        return haxe.Json.parse(json);
    }
    
    /**
     * Invalidate cache when migrations change
     */
    public static function invalidateIfChanged(migrations: Array<MigrationInfo>): Bool {
        var cached = load();
        if (cached == null) return true;
        
        // Compare timestamps, check for new/modified migrations
        return hasChanges(cached, migrations);
    }
}
```

#### Phase 4: Enhanced Error Reporting

**4.1 Migration Timeline Visualization**
```
Error: Foreign key to table "users" in migration CreatePosts (2024_01_15_120000)
       but table "users" is not created until CreateUsers (2024_01_20_140000)

Migration Timeline:
  2024_01_10_100000  CreateSettings    ✓
  2024_01_15_120000  CreatePosts       ✗ (references non-existent "users")
  2024_01_20_140000  CreateUsers       ✓
  2024_01_25_160000  AddIndexes        ✓

Suggestion: Move CreateUsers migration before CreatePosts
```

**4.2 Dependency Graph Generation**
```haxe
class MigrationDependencyGraph {
    /**
     * Generate DOT graph showing migration dependencies
     */
    public static function generateDotGraph(migrations: Array<MigrationInfo>): String {
        var dot = "digraph Migrations {\n";
        
        for (migration in migrations) {
            for (dep in migration.dependencies) {
                dot += '  "${migration.name}" -> "${dep}";\n';
            }
        }
        
        dot += "}";
        return dot;
    }
}
```

### Configuration

**haxe.json / compile.hxml options:**
```hxml
# Enable cross-migration validation
-D migration_validation=cross

# Set migration directory (default: src/migrations)
-D migration_path=src/db/migrations

# Cache location
-D migration_cache=.haxe/migrations

# Validation strictness
-D migration_strict=true  # Fail on warnings
```

### Migration Metadata Enhancement

```haxe
@:migration({
    timestamp: "2024_01_15_120000",
    depends: ["CreateUsers", "CreateRoles"],  // Explicit dependencies
    description: "Create posts table with user references"
})
class CreatePosts extends Migration {
    // ...
}
```

## Benefits

1. **Complete Compile-Time Safety**: Catch all schema issues before runtime
2. **Migration Order Validation**: Ensure migrations can execute in sequence
3. **Rollback Safety**: Validate down() methods won't break schema
4. **Better Developer Experience**: Clear errors with timeline visualization
5. **CI/CD Integration**: Fail builds early for migration issues

## Implementation Phases

### Phase 1: Core Infrastructure (2 weeks)
- Migration scanner
- Schema state tracker
- Basic cross-migration validation

### Phase 2: Advanced Validation (1 week)
- Rollback validation
- Dependency resolution
- Circular reference detection

### Phase 3: Developer Experience (1 week)
- Enhanced error messages
- Timeline visualization
- Dependency graph generation

### Phase 4: Optimization (1 week)
- Caching system
- Incremental validation
- Performance tuning

## Technical Considerations

### Performance Impact
- **Compile Time**: Additional 100-500ms for typical projects
- **Memory**: ~1MB for schema state of 50 tables
- **Caching**: Reduces recompilation overhead by 80%

### Compatibility
- **Backwards Compatible**: Existing migrations work unchanged
- **Opt-in**: Feature flag enables cross-validation
- **Gradual Adoption**: Can be enabled per-project

### Edge Cases

1. **Conditional Migrations**: Handle migrations with runtime conditions
2. **External Schemas**: Support references to pre-existing tables
3. **Multi-Database**: Handle migrations across multiple databases
4. **Raw SQL**: Detect and warn about unchecked execute() statements

## Alternative Approaches Considered

### 1. Runtime Validation
- **Pros**: Simpler implementation, handles dynamic cases
- **Cons**: Doesn't prevent deployment issues, slower feedback

### 2. External Tool
- **Pros**: Language agnostic, could analyze .sql files
- **Cons**: Loses type safety, requires separate toolchain

### 3. AST Rewriting
- **Pros**: Could auto-fix some issues
- **Cons**: Too magical, harder to debug

## Success Metrics

- **Zero runtime migration errors** in projects using cross-validation
- **90% of schema issues** caught at compile time
- **< 500ms** compile time overhead for average project
- **100% backwards compatibility** with existing migrations

## Future Enhancements

1. **Auto-generate migrations** from schema changes
2. **Migration squashing** for long histories
3. **Schema diffing** between branches
4. **Database-specific validation** (PostgreSQL vs MySQL)
5. **Integration with database schema dumps**

## Conclusion

Cross-migration validation transforms Reflaxe.Elixir's migration system from a single-file validator to a comprehensive schema management solution. By analyzing all migrations together at compile time, we can provide guarantees that the entire migration sequence will execute successfully, catching issues that would otherwise only appear in production.

This enhancement maintains our philosophy of compile-time safety while respecting Elixir's migration patterns, resulting in a system that's both powerful and familiar to Elixir developers.