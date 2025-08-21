# Mix Task Generators Documentation

This document provides comprehensive documentation for the Mix task generators available in Reflaxe.Elixir, enabling rapid development of Ecto-backed Phoenix applications with Haxe's type safety.

## Table of Contents
- [Overview](#overview)
- [Available Generators](#available-generators)
- [Mix.Tasks.Haxe.Gen.Schema](#mixtaskshaxegenschema)
- [Mix.Tasks.Haxe.Gen.Context](#mixtaskshaxegencontext)
- [Mix.Tasks.Haxe.Gen.Migration](#mixtaskshaxegenmigration)
- [Mix.Tasks.Haxe.Gen.Project](#mixtaskshaxegenproject)
- [Integration Workflow](#integration-workflow)
- [Best Practices](#best-practices)

## Overview

Reflaxe.Elixir provides a comprehensive suite of Mix task generators that bridge Haxe's compile-time type safety with Phoenix's proven patterns. These generators create both Haxe source files with proper annotations AND corresponding Elixir modules, ensuring seamless integration with existing Phoenix applications.

### Key Benefits
- **Type Safety**: Compile-time validation of Ecto operations through Haxe
- **Rapid Development**: Generate complete Phoenix contexts in seconds
- **Convention Compliance**: Automatic adherence to Phoenix patterns
- **Dual Output**: Both Haxe source and compiled Elixir modules
- **Zero Dependencies**: No external libraries required

## Available Generators

| Generator | Purpose | Command |
|-----------|---------|---------|
| `haxe.gen.schema` | Generate Ecto schema modules | `mix haxe.gen.schema User users` |
| `haxe.gen.context` | Generate Phoenix contexts with CRUD | `mix haxe.gen.context Accounts User users` |
| `haxe.gen.migration` | Generate database migrations | `mix haxe.gen.migration CreateUsers` |
| `haxe.gen.project` | Add Reflaxe.Elixir to existing project | `mix haxe.gen.project` |

## Mix.Tasks.Haxe.Gen.Schema

Generates Ecto schema modules from Haxe @:schema classes with comprehensive field and association support.

### Basic Usage

```bash
mix haxe.gen.schema User
```

### Advanced Usage

```bash
mix haxe.gen.schema User \
  --table users \
  --fields "name:string,email:string:unique,age:integer,active:boolean" \
  --belongs-to "Account:account" \
  --has-many "Post:posts" \
  --has-one "Profile:profile" \
  --timestamps \
  --changeset
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--table` | Database table name | Pluralized schema name |
| `--fields` | Field definitions (name:type:options) | name:string,description:text |
| `--primary-key` | Primary key field name | id |
| `--belongs-to` | belongs_to associations | None |
| `--has-many` | has_many associations | None |
| `--has-one` | has_one associations | None |
| `--timestamps` | Include timestamps | true |
| `--changeset` | Generate changeset function | true |
| `--haxe-dir` | Haxe source directory | src_haxe/schemas |
| `--elixir-dir` | Elixir output directory | lib |

### Field Type Mappings

| Haxe Type | Elixir/Ecto Type | SQL Type |
|-----------|------------------|----------|
| `String` | `:string` | VARCHAR |
| `String` | `:text` | TEXT |
| `Int` | `:integer` | INTEGER |
| `Bool` | `:boolean` | BOOLEAN |
| `Float` | `:float` | FLOAT |
| `Float` | `:decimal` | DECIMAL |
| `Date` | `:datetime` | TIMESTAMP |
| `Date` | `:naive_datetime` | TIMESTAMP |
| `Dynamic` | `:map` | JSONB |

### Generated Files

#### Haxe Schema (src_haxe/schemas/User.hx)
```haxe
@:schema(table: "users")
@:changeset
class User {
  @:primary_key
  public var id: Int;
  
  @:field({type: "string", nullable: false})
  public var name: String;
  
  @:field({type: "string", nullable: false, unique: true})
  public var email: String;
  
  @:belongs_to("account", "Account")
  public var account: Account;
  
  @:has_many("posts", "Post")
  public var posts: Array<Post>;
  
  @:timestamps
  public var insertedAt: String;
  public var updatedAt: String;
}
```

#### Elixir Schema (lib/user.ex)
```elixir
defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "users" do
    field :name, :string, null: false
    field :email, :string, unique: true, null: false
    belongs_to :account, Account
    has_many :posts, Post
    timestamps()
  end

  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
  end
end
```

## Mix.Tasks.Haxe.Gen.Context

Generates complete Phoenix context modules with CRUD operations, business logic, and proper error handling.

### Basic Usage

```bash
mix haxe.gen.context Accounts User users
```

### Advanced Usage

```bash
mix haxe.gen.context Blog Post posts \
  --schema-attrs "title:string,content:text,published:boolean,views:integer" \
  --belongs-to "User:author,Category:category" \
  --has-many "Comment:comments" \
  --changeset \
  --repo MyApp.Repo
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--schema-attrs` | Schema field attributes | name:string,description:text |
| `--context-attrs` | Additional context attributes | None |
| `--belongs-to` | belongs_to associations | None |
| `--has-many` | has_many associations | None |
| `--has-one` | has_one associations | None |
| `--no-schema` | Skip schema generation | false |
| `--changeset` | Include changeset | true |
| `--repo` | Repository module | Repo |
| `--haxe-dir` | Haxe source directory | src_haxe/contexts |
| `--elixir-dir` | Elixir output directory | lib |

### Generated Context Methods

#### Standard CRUD Operations
- `list_posts/0` - Get all records
- `get_post!/1` - Get record by ID (raises on not found)
- `get_post/1` - Get record by ID (returns nil on not found)
- `create_post/1` - Create new record
- `update_post/2` - Update existing record
- `delete_post/1` - Delete record
- `change_post/1` - Create changeset for forms

#### Business Logic Methods
- `list_posts_paginated/2` - Paginated listing
- `search_posts/1` - Text search across fields
- `get_post_with_assocs/1` - Preload associations
- `list_posts_by_author/1` - Filter by association
- `get_post_stats/0` - Statistical aggregations

### Generated Files Structure

```
src_haxe/contexts/
├── Blog.hx              # Haxe context with business logic
│   ├── Post (schema)    # Embedded schema definition
│   ├── PostChangeset    # Validation logic
│   └── Blog (context)   # CRUD and business methods

lib/
├── blog.ex              # Elixir context module
│   └── Complete Phoenix context with Ecto.Query
```

## Mix.Tasks.Haxe.Gen.Migration

Generates database migration files based on Haxe @:migration annotations.

### Basic Usage

```bash
mix haxe.gen.migration CreateUsers
```

### Advanced Usage

```bash
mix haxe.gen.migration CreatePosts \
  --table posts \
  --columns "title:string,content:text,published:boolean,user_id:references" \
  --index "user_id,published" \
  --unique "slug"
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--table` | Table name | Inferred from name |
| `--columns` | Column definitions | name:string,description:text |
| `--index` | Fields to index | None |
| `--unique` | Unique constraints | None |
| `--haxe-dir` | Haxe migrations directory | src_haxe/migrations |
| `--elixir-dir` | Elixir migrations directory | priv/repo/migrations |

## Mix.Tasks.Haxe.Gen.Project

Adds Reflaxe.Elixir support to an existing Elixir/Phoenix project.

### Usage

```bash
mix haxe.gen.project
```

### What It Generates

1. **Project Structure**:
   ```
   src_haxe/           # Haxe source files
   ├── Main.hx         # Entry point
   └── schemas/        # Schema definitions
   
   build.hxml          # Haxe build configuration
   haxelib.json        # Haxe dependencies
   ```

2. **Mix Configuration**: Updates `mix.exs` with Haxe compilation hooks

3. **VS Code Integration**: `.vscode/` settings for Haxe development

## Integration Workflow

### Complete Development Cycle

1. **Generate Schema**:
   ```bash
   mix haxe.gen.schema User users --fields "name:string,email:string:unique"
   ```

2. **Generate Context**:
   ```bash
   mix haxe.gen.context Accounts User users --no-schema
   ```

3. **Generate Migration**:
   ```bash
   mix haxe.gen.migration CreateUsers
   ```

4. **Run Migration**:
   ```bash
   mix ecto.migrate
   ```

5. **Compile Haxe to Elixir**:
   ```bash
   mix compile
   ```

6. **Use in Phoenix**:
   ```elixir
   defmodule MyAppWeb.UserController do
     use MyAppWeb, :controller
     alias MyApp.Accounts
     
     def index(conn, _params) do
       users = Accounts.list_users()
       render(conn, "index.html", users: users)
     end
   end
   ```

## Best Practices

### 1. Schema Design
- Use descriptive field names
- Add proper nullable constraints
- Include timestamps for audit trails
- Define associations explicitly

### 2. Context Organization
- One context per business domain
- Keep contexts focused and cohesive
- Use contexts as your API boundary
- Avoid cross-context database joins

### 3. Type Safety
- Leverage Haxe's type system
- Define proper return types
- Use null-safety annotations
- Create type aliases for complex types

### 4. Testing
- Generate tests alongside code
- Test both Haxe compilation and Elixir runtime
- Validate changeset rules
- Test association preloading

### 5. Performance
- Use preloading for associations
- Implement pagination for large datasets
- Add database indexes via migrations
- Profile generated queries

## Troubleshooting

### Common Issues

1. **Compilation Errors**
   - Ensure `reflaxe.elixir` is installed: `haxelib install reflaxe.elixir`
   - Check Haxe version compatibility (4.3.6+)
   - Verify annotation syntax

2. **Missing Modules**
   - Run `mix deps.get` after generation
   - Ensure Ecto is in dependencies
   - Check module naming conventions

3. **Association Errors**
   - Verify foreign key fields exist
   - Check association module names
   - Ensure bidirectional associations match

## Examples

### Blog Application
```bash
# Generate User schema
mix haxe.gen.schema User users \
  --fields "username:string:unique,email:string:unique,bio:text"

# Generate Post schema with associations
mix haxe.gen.schema Post posts \
  --fields "title:string,content:text,published:boolean" \
  --belongs-to "User:author"

# Generate Blog context
mix haxe.gen.context Blog Post posts --no-schema

# Generate migration
mix haxe.gen.migration CreatePostsTable
```

### E-commerce Application
```bash
# Generate Product schema
mix haxe.gen.schema Product products \
  --fields "name:string,description:text,price:decimal,stock:integer"

# Generate Order context with full CRUD
mix haxe.gen.context Shop Order orders \
  --schema-attrs "total:decimal,status:string" \
  --belongs-to "User:customer" \
  --has-many "OrderItem:items"
```

## Conclusion

The Mix task generators in Reflaxe.Elixir provide a powerful bridge between Haxe's type safety and Phoenix's proven patterns. By generating both Haxe source and Elixir modules, developers can leverage compile-time validation while maintaining full compatibility with the Phoenix ecosystem.

For more information, see:
- [Phoenix Integration Guide](PHOENIX_INTEGRATION_GUIDE.md)
- [Ecto Integration Patterns](ECTO_INTEGRATION_PATTERNS.md)
- [Project Generator Guide](PROJECT_GENERATOR_GUIDE.md)