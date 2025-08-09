# Reflaxe.Elixir Annotations Reference

Complete guide to using annotations in Reflaxe.Elixir for generating Elixir/Phoenix code.

## Overview

Reflaxe.Elixir uses Haxe metadata annotations to control code generation. Annotations tell the compiler how to transform Haxe classes into specific Elixir modules and patterns.

## Supported Annotations

### @:schema - Ecto Schema Generation

Generates Ecto.Schema modules for database models.

**Basic Usage**:
```haxe
@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "string", nullable: false})
    public var email: String;
    
    @:field({type: "integer"})
    public var age: Int;
    
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
}
```

**Generated Elixir**:
```elixir
defmodule User do
  use Ecto.Schema
  
  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    
    timestamps()
  end
end
```

**Field Annotations**:
- `@:primary_key` - Primary key field
- `@:field({options})` - Regular field with options
- `@:timestamps` - Automatic timestamp fields
- `@:has_many(field, module, key)` - Has many association
- `@:belongs_to(field, module)` - Belongs to association

### @:changeset - Ecto Changeset Validation

Generates Ecto.Changeset modules for data validation.

**Basic Usage**:
```haxe
@:changeset
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", "email_regex")
    @:validate_length("name", {min: 2, max: 100})
    public static function changeset(user: User, attrs: Dynamic): Dynamic {
        return null; // Implementation generated automatically
    }
}
```

**Validation Annotations**:
- `@:validate_required([fields])` - Required field validation
- `@:validate_format(field, pattern)` - Format validation
- `@:validate_length(field, {min, max})` - Length validation
- `@:validate_number(field, {greater_than, less_than})` - Number validation

### @:liveview - Phoenix LiveView Components

Generates Phoenix LiveView modules for real-time web components.

**Basic Usage**:
```haxe
@:liveview
class UserLive {
    var users: Array<User> = [];
    var selectedUser: Null<User> = null;
    
    function mount(params: Dynamic, session: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        return {
            status: "ok",
            socket: assign_multiple(socket, {
                users: Users.list_users(),
                selectedUser: null
            })
        };
    }
    
    function handle_event(event: String, params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        return switch(event) {
            case "new_user":
                handleNewUser(params, socket);
            default:
                {status: "noreply", socket: socket};
        }
    }
    
    function render(assigns: Dynamic): String {
        return hxx('<div>LiveView content</div>');
    }
}
```

**LiveView Functions**:
- `mount()` - Component initialization
- `handle_event()` - Event handling with pattern matching
- `render()` - Template rendering
- `assign()` / `assign_multiple()` - Socket state management

### @:genserver - OTP GenServer Processes

Generates OTP GenServer modules for background processes and state management.

**Basic Usage**:
```haxe
@:genserver
class UserGenServer {
    var userCache: Map<Int, User> = new Map();
    
    function init(initialState: Dynamic): {status: String, state: Dynamic} {
        return {
            status: "ok",
            state: {userCache: userCache}
        };
    }
    
    function handle_call(request: String, from: Dynamic, state: Dynamic): CallResponse {
        return switch(request) {
            case "get_user":
                handleGetUser(from, state);
            default:
                {status: "reply", response: "unknown_request", state: state};
        }
    }
    
    function handle_cast(message: String, state: Dynamic): {status: String, state: Dynamic} {
        return {status: "noreply", state: state};
    }
}
```

**GenServer Callbacks**:
- `init()` - Server initialization
- `handle_call()` - Synchronous requests
- `handle_cast()` - Asynchronous messages
- `handle_info()` - System messages

### @:migration - Ecto Migration DSL

Generates Ecto migration modules with table operations.

**Basic Usage**:
```haxe
@:migration
class CreateUsers {
    public static function up(): String {
        return MigrationDSL.createTable("users", function(t) {
            t.addColumn("name", "string", {"null": false});
            t.addColumn("email", "string", {"null": false});
            t.addColumn("age", "integer");
            
            t.addIndex(["email"], {unique: true});
            t.addIndex(["name", "active"]);
        });
    }
    
    public static function down(): String {
        return MigrationDSL.dropTable("users");
    }
}
```

**Migration Operations**:
- `createTable(name, callback)` - Create new table
- `dropTable(name)` - Drop existing table
- `addColumn(name, type, options)` - Add table column
- `addIndex(columns, options)` - Add index
- `addForeignKey(column, table, reference)` - Add foreign key constraint
- `addCheckConstraint(condition, name)` - Add check constraint

### @:template - HEEx Template Processing

Generates Phoenix templates with component integration.

**Basic Usage**:
```haxe
@:template
class FormComponents {
    public static function user_form(assigns: Dynamic): String {
        return hxx('
        <.form for={@changeset} phx-submit="save_user">
            <.input field={@changeset[:name]} type="text" label="Name" />
            <.input field={@changeset[:email]} type="email" label="Email" />
            <.button type="submit">Save User</.button>
        </.form>
        ');
    }
}
```

### @:query - Ecto Query DSL (Future)

**Status**: Planned for future release
**Purpose**: Type-safe Ecto query compilation

## Annotation Validation

### Exclusive Groups

Some annotations cannot be used together on the same class:

**Behavior vs Component**:
- `@:genserver` and `@:liveview` are mutually exclusive

**Data vs Validation**:
- `@:schema` and `@:changeset` are mutually exclusive

**Migration vs Runtime**:
- `@:migration` cannot be used with `@:schema` or `@:changeset`

### Compatible Combinations

These annotation combinations are supported:

- `@:liveview + @:template` - LiveView with custom templates
- `@:schema + @:query` - Schema with custom queries (future)
- `@:changeset + @:query` - Changeset with custom queries (future)

### Error Handling

The annotation system provides helpful error messages:

```
Error: Annotations [:genserver, :liveview] cannot be used together - they are mutually exclusive
```

## Best Practices

### 1. Use Appropriate Annotations
- `@:schema` for database models
- `@:changeset` for validation logic
- `@:liveview` for real-time UI components
- `@:genserver` for background processes
- `@:migration` for database schema changes

### 2. Follow Naming Conventions
- Use snake_case for table names in `@:schema("table_name")`
- Use PascalCase for class names
- Use snake_case for field names

### 3. Organize Code Structure
```
src_haxe/
├── contexts/          # @:schema and @:changeset classes
├── live/             # @:liveview classes  
├── services/         # @:genserver classes
├── migrations/       # @:migration classes
└── templates/        # @:template classes
```

### 4. Import Required Dependencies
Always import the necessary helpers:
```haxe
import reflaxe.elixir.helpers.MigrationDSL;
import reflaxe.elixir.helpers.MigrationDSL.TableBuilder;
```

### 5. Test Generated Code
- Compile individual modules to test annotation processing
- Use `npm test` for comprehensive validation
- Check generated Elixir code for correctness

## Troubleshooting

### Common Issues

**Invalid Annotation Combinations**:
```
Solution: Check annotation compatibility in FEATURES.md
```

**Missing Dependencies**:
```
Solution: Add proper imports for helper functions
```

**Keyword Conflicts**:
```haxe
// Wrong
{null: false}

// Correct
{"null": false}
```

**Function Visibility**:
```haxe
// Wrong
function myUtility() {}

// Correct  
public static function myUtility() {}
```

For implementation details and development context, see CLAUDE.md.