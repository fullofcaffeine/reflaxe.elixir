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
@:migration
class CreateUsers {
    public static function up() {
        createTable("users", function(t) {
            t.addColumn("name", "string", {null: false});
            t.addColumn("email", "string", {null: false});
            t.addIndex(["email"], {unique: true});
        });
    }
    
    public static function down() {
        dropTable("users");  
    }
}
```

**Generated Elixir:**
```elixir
defmodule CreateUsers do
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
t.addForeignKey("user_id", "users", "id");
```

**Composite Indexes:**
```haxe
t.addIndex(["published", "inserted_at"]);
```

**Check Constraints:**
```haxe
t.addCheckConstraint("view_count >= 0", "positive_view_count");
```

## Workflow Integration

### With Mix Tasks
```bash
# Generate new migration
mix haxe.gen.migration CreateUsers

# This creates both:
# - src_haxe/migrations/CreateUsers.hx (Haxe source)
# - priv/repo/migrations/20231201120000_create_users.exs (compiled Elixir)
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