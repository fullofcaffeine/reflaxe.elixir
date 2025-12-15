# Ecto Database Migrations with Haxe

This example demonstrates how to write Ecto database migrations using Haxe with the `@:migration` annotation.

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
- **Mix Integration**: Works with standard `mix ecto.migrate` workflow

## Quick Start

```bash
cd examples/04-ecto-migrations

# Compile Haxe migrations to Elixir
npx haxe build.hxml

# Run migrations (if you have a database configured)
mix ecto.migrate

# Rollback migrations  
mix ecto.rollback
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

**Generated Elixir:**
```elixir
defmodule <YourApp>.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def up do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      timestamps()
    end
    
    create unique_index(:users, [:email])
  end

  def down do
    drop table(:users)
  end
end
```

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

# This creates both:
# - src_haxe/migrations/CreateUsers.hx (Haxe source skeleton)
# - priv/repo/migrations/<timestamp>_create_users.exs (Elixir migration file)
```

### Development Flow
1. Write migration in Haxe using `@:migration`
2. Compile with `npx haxe build.hxml`
3. Run with `mix ecto.migrate`
4. Rollback with `mix ecto.rollback` if needed

## Benefits

- **Type Safety**: Compile-time validation of migration structure
- **Reusability**: Share migration logic across projects
- **Consistency**: Standardized migration patterns
- **Integration**: Works with existing Ecto tooling
