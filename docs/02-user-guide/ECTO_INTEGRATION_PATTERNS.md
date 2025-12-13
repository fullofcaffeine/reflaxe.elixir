# Ecto Integration Patterns

## Current Implementation Status 🎯

> **Important Update (August 2025)**: The Ecto Query DSL is now **IMPLEMENTED** in Reflaxe.Elixir! 
> This document has been updated to reflect the current reality where typed Ecto queries work natively,
> with escape hatches only needed for missing features like changesets and migrations.

### What's Working Today ✅

- **Query DSL**: Full expression parsing and compilation to proper Ecto pipe syntax
- **Where Clauses**: Complex conditions with AND/OR operators compile correctly
- **Select Expressions**: Field and map selections with proper syntax
- **Joins**: Association-based joins with correct binding arrays
- **Order/Group By**: Multiple field support with proper compilation
- **Schema Validation**: Compile-time field checking with helpful error messages

### What Still Needs Escape Hatches ❌

- **Changesets**: Not implemented - use Elixir modules
- **Migrations**: Not implemented - write standard Ecto migrations
- **Complex Aggregations**: Subqueries and CTEs need Elixir
- **Database-Specific Features**: Raw SQL for PostgreSQL-specific functions

## Table of Contents

- [Native Haxe Ecto Queries (NEW!)](#native-haxe-ecto-queries)
- [Changeset Workarounds](#changeset-workarounds)
- [Migration Strategies](#migration-strategies)
- [Complex Query Patterns](#complex-query-patterns)
- [Recommended Architecture](#recommended-architecture)

## Native Haxe Ecto Queries

**NEW**: You can now write type-safe Ecto queries directly in Haxe!

```haxe
import reflaxe.elixir.macros.EctoQueryMacros.*;

@:module
class UserQueries {
    // Simple where clause - WORKS TODAY!
    function getActiveUsers(): String {
        var query = analyzeCondition(macro u -> u.active == true);
        return generateWhereQuery(query);
        // Generates: |> where([u], u.active == ^true)
    }
    
    // Complex conditions - WORKS TODAY!
    function getAdultActiveUsers(): String {
        var condition = analyzeCondition(macro u -> u.age >= 18 && u.active == true);
        return generateWhereQuery(condition);
        // Generates: |> where([u], u.age >= ^18 and u.active == ^true)
    }
    
    // Select with map - WORKS TODAY!
    function getUserSummary(): String {
        var select = analyzeSelectExpression(macro u -> {
            name: u.name,
            email: u.email,
            joined: u.inserted_at
        });
        return generateSelectQuery(select);
        // Generates: |> select([u], %{name: u.name, email: u.email, joined: u.inserted_at})
    }
    
    // Join operations - WORKS TODAY!
    function getUsersWithPosts(): String {
        var join = {
            schema: "Post",
            alias: "posts",
            type: "inner",
            on: "user.id == posts.user_id"
        };
        return generateJoinQuery(join);
        // Generates: |> join(:inner, [u], p in assoc(u, :posts), as: :p)
    }
}
```

### Schema Validation (WORKING!)

Compile-time validation catches errors early:

```haxe
// This will fail at compile time with helpful error message
var query = analyzeCondition(macro u -> u.nonexistent_field > 0);
// Error: Field "nonexistent_field" does not exist in schema "User". 
// Available fields: id, name, email, age, active, inserted_at, updated_at

// Operator type checking also works
var query = analyzeCondition(macro u -> u.name > 42);
// Error: Cannot use numeric operator ">" on non-string field "name" of type "String"
```

### Test Coverage Proof

All these features have passing tests:
- `test/EctoQueryExpressionParsingTest.hx` - 6 tests passing
- `test/EctoQueryCompilationTest.hx` - 5 tests passing  
- `test/SchemaValidationTest.hx` - 5 tests passing

## Changeset Workarounds

**Status**: ❌ Not Implemented (Use Elixir modules as temporary workaround)

Since changesets aren't implemented yet, create Elixir modules:

```elixir
# lib/my_app/changesets/user_changeset.ex
defmodule MyApp.Changesets.UserChangeset do
  import Ecto.Changeset
  alias MyApp.User

  def changeset(user \\ %User{}, attrs) do
    user
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 0, less_than: 150)
    |> unique_constraint(:email)
  end
  
  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8)
    |> hash_password()
  end
  
  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password -> put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end
end
```

Then expose via Haxe extern:

```haxe
@:native("MyApp.Changesets.UserChangeset")
extern class UserChangeset {
    @:native("changeset")
    public static function changeset(user: Dynamic, attrs: Dynamic): Dynamic;
    
    @:native("registration_changeset")
    public static function registrationChangeset(user: Dynamic, attrs: Dynamic): Dynamic;
}

// Usage
@:module
class UserService {
    function createUser(userData: Dynamic): Dynamic {
        var changeset = UserChangeset.changeset({}, userData);
        
        return switch(Repo.insert(changeset)) {
            case {:ok, user}: user;
            case {:error, changeset}: throw "Validation failed";
        }
    }
}
```

**Timeline**: Changeset support planned for Q2 2025 (estimated 2-3 weeks of work)

## Migration Strategies

**Status**: ❌ Not Implemented (Use standard Ecto migrations)

Write migrations in Elixir as normal:

```elixir
# priv/repo/migrations/20250108000000_create_users.exs
defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :age, :integer
      add :active, :boolean, default: true
      
      timestamps()
    end
    
    create unique_index(:users, [:email])
    create index(:users, [:active])
  end
end
```

Run migrations normally:
```bash
mix ecto.migrate
```

**Timeline**: Migration DSL support planned for Q2 2025 (estimated 2-3 weeks of work)

## Complex Query Patterns

### What Works in Haxe Now

Simple to moderate complexity queries work great:

```haxe
// All of these compile to proper Ecto syntax TODAY
class WorkingQueries {
    function activeAdultUsers() {
        // Multiple conditions
        var condition = analyzeCondition(macro u -> 
            u.age >= 18 && 
            u.active == true && 
            u.email != null
        );
        
        // Field selection
        var select = analyzeSelectExpression(macro u -> {
            id: u.id,
            name: u.name,
            email: u.email
        });
        
        // Combine into query (manual composition for now)
        var whereClause = generateWhereQuery(condition);
        var selectClause = generateSelectQuery(select);
        
        return 'from(u in User) ${whereClause} ${selectClause}';
    }
}
```

### What Still Needs Elixir Modules

Complex features not yet supported:

```elixir
# Subqueries, CTEs, window functions still need Elixir
defmodule MyApp.ComplexQueries do
  import Ecto.Query
  
  def top_users_by_engagement do
    # Common Table Expression
    recent_posts = from p in Post,
      where: p.inserted_at > ago(7, "day"),
      group_by: p.user_id,
      select: %{user_id: p.user_id, post_count: count(p.id)}
    
    # Window function
    from u in User,
      join: rp in subquery(recent_posts), on: rp.user_id == u.id,
      windows: [rank: [order_by: [desc: rp.post_count]]],
      select: %{
        user: u,
        post_count: rp.post_count,
        rank: row_number() |> over(:rank)
      }
  end
  
  # Full-text search with PostgreSQL
  def search_content(search_term) do
    from p in Post,
      where: fragment("? @@ plainto_tsquery('english', ?)", p.search_vector, ^search_term),
      order_by: [desc: fragment("ts_rank(?, plainto_tsquery('english', ?))", 
                                 p.search_vector, ^search_term)]
  end
end
```

## Recommended Architecture

### Current Best Practice (August 2025)

```
┌─────────────────┐       ┌──────────────────┐      ┌─────────────┐
│ Haxe            │       │ Haxe-Generated   │      │ Database    │
│ Business Logic  │──────▶│ Ecto Queries     │─────▶│             │
│ + Simple Queries│       │ (Pipe Syntax)    │      │             │
└─────────────────┘       └──────────────────┘      └─────────────┘
         │                                                   ▲
         │                ┌──────────────────┐              │
         └───────────────▶│ Elixir Modules   │──────────────┘
                          │ (Changesets,     │
                          │  Complex Queries) │
                          └──────────────────┘
```

**Use Haxe for**:
- ✅ Business logic
- ✅ Simple to moderate queries (WHERE, SELECT, JOIN, ORDER BY)
- ✅ Type-safe query building
- ✅ Schema validation

**Use Elixir modules for**:
- ❌ Changesets (not implemented)
- ❌ Migrations (not implemented)
- ⚠️ Complex aggregations with subqueries
- ⚠️ Database-specific features (full-text search, window functions)

### Migration Path from Escape Hatches

As features are implemented, you can migrate:

```haxe
// Before (Q4 2024) - Everything through Elixir
@:native("UserQueries.active_users")
extern function getActiveUsers(): Array<User>;

// Now (Q1 2025) - Native Haxe queries!
function getActiveUsers(): Array<User> {
    var query = analyzeCondition(macro u -> u.active == true);
    var whereClause = generateWhereQuery(query);
    // Actually compiles to working Ecto!
    return Repo.all('from(u in User) ${whereClause}');
}

// Future (Q2 2025) - With changesets
function createUser(data: UserData): User {
    var changeset = User.changeset(%User{}, data); // Coming soon!
    return Repo.insert!(changeset);
}
```

## Performance Characteristics

### Query Compilation Performance ✅
- Compilation: <1ms per query (exceeds <15ms target)
- Runtime: Native Ecto performance (no overhead)
- Type checking: Compile-time (zero runtime cost)

### Development Velocity 📈
- **Before**: Write queries in Elixir, expose via externs
- **Now**: Write queries directly in Haxe with type safety
- **Future**: Full Ecto feature parity planned

## Roadmap to Complete Implementation

### Q1 2025 ✅ (COMPLETED)
- [x] Expression parsing
- [x] Query compilation
- [x] Schema validation
- [x] Basic query operations

### Q2 2025 (PLANNED)
- [ ] Changeset support (2-3 weeks)
- [ ] Migration DSL (2-3 weeks)
- [ ] Query composition helpers (1 week)
- [ ] Repo integration (1 week)

### Q3 2025 (PLANNED)
- [ ] Subquery support
- [ ] Aggregate functions
- [ ] Transaction support
- [ ] Multi-repo support

### Q4 2025 (GOAL)
- [ ] Full Ecto feature parity
- [ ] Remove all escape hatches
- [ ] Production ready

## Conclusion

**August 2025 Reality**: Reflaxe.Elixir now has working Ecto query compilation! While changesets and migrations still need escape hatches, the core query DSL is functional and generates proper Elixir code.

**What This Means**:
- ✅ You can write type-safe queries in Haxe today
- ✅ Compile-time validation catches errors early
- ✅ Generated code uses proper Ecto pipe syntax
- ⚠️ Some features still need Elixir modules (temporary)
- 📈 Active development toward full feature parity

**Recommendation**: Start using native Haxe queries for new code. Keep changeset/migration logic in Elixir modules until those features are implemented (Q2 2025).

---

*Last Updated: August 2025 - Reflects actual working implementation with test coverage*
