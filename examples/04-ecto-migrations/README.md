# Ecto Database Migrations with Haxe

This example demonstrates **Haxe-authored, type-safe Ecto migrations** via the `@:migration` annotation.

> **Status (Experimental)**: Migrations are executable by Ecto via an **opt-in migration build**
> (`build-migrations.hxml`) that emits timestamped `.exs` files under `priv/repo/migrations/`.
> The DSL is still evolving; treat `alterTable` support as experimental.

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
- **Compile-time validation**: Registry-backed checks during macro expansion (experimental)

## Quick Start

```bash
cd examples/04-ecto-migrations

# Compile the migrations to runnable Ecto `.exs` files
haxe build-migrations.hxml
# Or via Mix:
# mix haxe.compile.migrations

# Inspect the generated migrations
ls priv/repo/migrations

# (Optional) Compile the intermediate `.ex` output (useful for debugging the DSL transform)
haxe build.hxml

# Inspect the intermediate output under lib/
ls lib/migrations
```

## Migration Examples

### Basic Table Creation

**Haxe Source:**
```haxe
import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20240101120000"})
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

**Generated Elixir (runnable Ecto migration):**

After `haxe build-migrations.hxml`, see:

- `priv/repo/migrations/*_create_users.exs`

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
# - src_haxe/migrations/CreateUsers.hx (Haxe source skeleton with a timestamp)

# Compile runnable `.exs` migrations (use the migration-only build file)
haxe build-migrations.hxml
```

### Development Flow
1. Write migration in Haxe using `@:migration`
2. Compile runnable migrations with `haxe build-migrations.hxml`
3. Run `mix ecto.migrate` in a real project (Phoenix app) with a configured Repo
4. (Optional) Use `haxe build.hxml` to inspect intermediate `.ex` output when debugging transforms

## Benefits

- **Type Safety**: Compile-time validation of migration structure
- **Reusability**: Share migration logic across projects
- **Consistency**: Standardized migration patterns
- **Integration**: Works with existing Ecto tooling
