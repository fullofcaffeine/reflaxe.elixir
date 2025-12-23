# Ecto Database Migrations with Haxe

This example demonstrates the **typed migration DSL surface** in Haxe via the `@:migration` annotation.

> **Status (Alpha)**: The migration DSL compiles today, but it is **not yet wired into Ecto's executable
> migration runner** (`priv/repo/migrations/*.exs` + `mix ecto.migrate`). Treat this example as a
> compile-time/shape demo for now.

**Prerequisites**: [03-phoenix-app](../03-phoenix-app/) completed  
**Difficulty**: 🟡 Intermediate  
**Time**: 30 minutes

## What You'll Learn

- Define database schemas using `@:migration` annotation
- Create tables, columns, indexes, and foreign keys type-safely
- Integrate with Elixir's migration workflow
- Handle up/down migration patterns

## Features

- **Migration DSL**: Type-safe migration definitions in Haxe
- **Foreign Keys**: Automatic relationship creation and constraints  
- **Indexes**: Single and composite index creation
- **Constraints**: Check constraints and validation rules
- **Compile-time validation**: Registry-backed checks during macro expansion (alpha)

## Quick Start

```bash
cd examples/04-ecto-migrations

# Compile the Haxe migrations to Elixir output (for inspection)
haxe build.hxml

# Inspect the generated output under lib/
ls lib/migrations
```

## Migration Examples

### Basic Table Creation

**Haxe Source:**
```haxe
import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration
class CreateUsers extends Migration {
    public function up(): Void {
        createTable("users")
            .addId()
            .addColumn("name", ColumnType.String(), {nullable: false})
            .addColumn("email", ColumnType.String(), {nullable: false})
            .addTimestamps()
            .addIndex(["email"], {unique: true});
    }
    
    public function down(): Void {
        dropTable("users");  
    }
}
```

**Generated Elixir (current alpha shape):**

The compiler currently emits an **intermediate helper module** for the migration DSL (not a
timestamped `Ecto.Migration` under `priv/repo/migrations/`). After `haxe build.hxml`, see:

- `lib/migrations/create_users.ex`

### Advanced Features

**Foreign Keys:**
```haxe
createTable("posts").addReference("user_id", "users");
```

**Composite Indexes:**
```haxe
createTable("posts").addIndex(["published", "inserted_at"]);
```

**Check Constraints:**
```haxe
createTable("posts").addCheckConstraint("positive_view_count", "view_count >= 0");
```

## Workflow Integration

### With Mix Tasks
```bash
# Generate new migration
mix haxe.gen.migration CreateUsers

# This creates:
# - src_haxe/migrations/CreateUsers.hx (Haxe source skeleton)
#
# NOTE: For executable migrations today, use:
#   mix ecto.gen.migration create_users
# and keep the migration logic in Elixir (Ecto runs priv/repo/migrations/*.exs).
```

### Development Flow
1. Write migration in Haxe using `@:migration`
2. Compile with `haxe build.hxml`
3. Review the generated output under `lib/` (alpha)

## Benefits

- **Type Safety**: Compile-time validation of migration structure
- **Reusability**: Share migration logic across projects
- **Consistency**: Standardized migration patterns
- **Integration**: Works with existing Ecto tooling
