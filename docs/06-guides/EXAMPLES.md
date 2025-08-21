# Reflaxe.Elixir Examples Guide

This guide provides walkthroughs for all example projects, showing how to use Reflaxe.Elixir features in practice.

**✅ All Examples Now Runnable**: Every example directory now includes a complete `mix.exs` file and can be run as a standalone Mix project.

## Template System Integration

**Important**: Many of these examples serve as **project generator templates**:
- `examples/02-mix-project` → Basic project template
- `examples/03-phoenix-app` → Phoenix project template  
- `examples/06-user-management` → LiveView project template

Each template includes a `.template.json` configuration file describing features, requirements, and placeholders. See [PROJECT_GENERATOR_GUIDE.md](../PROJECT_GENERATOR_GUIDE.md#template-system) for complete details.

## ✅ Working Examples

### 01-simple-modules
**Status**: Production Ready  
**Purpose**: Basic compilation patterns and module generation

**Key Features Demonstrated**:
- Basic Haxe to Elixir compilation
- Module structure generation
- Function compilation
- Simple type mapping

**How to Run**:
```bash
cd examples/01-simple-modules
mix deps.get              # Install dependencies
npx haxe compile-all.hxml # Compile Haxe to Elixir
mix compile               # Compile Elixir project
```

**Files Generated**:
- `BasicModule.ex` - Simple module structure
- `MathHelper.ex` - Mathematical utility functions
- `UserUtil.ex` - User management utilities

### 02-mix-project
**Status**: Production Ready  
**Purpose**: Complete Mix project integration with utilities

**Key Features Demonstrated**:
- Mix project integration
- Multiple utility modules
- Package resolution
- Cross-module dependencies

**Modules Included**:
- `utils.StringUtils` - String processing utilities
- `utils.MathHelper` - Mathematical operations and validation
- `utils.ValidationHelper` - Input validation and sanitization
- `services.UserService` - Business logic and user management

**How to Run**:
```bash
cd examples/02-mix-project
npx haxe build.hxml
mix test
```

### 03-phoenix-app
**Status**: Production Ready  
**Purpose**: Phoenix application structure generation

**Key Features Demonstrated**:
- Phoenix application module compilation
- Application startup configuration
- Phoenix framework integration

**How to Run**:
```bash
cd examples/03-phoenix-app
npx haxe build.hxml
```

### 04-ecto-migrations
**Status**: Production Ready  
**Purpose**: Real migration DSL with table operations

**Key Features Demonstrated**:
- @:migration annotation usage
- Real DSL helper functions (createTable, addColumn, addIndex, addForeignKey)
- TableBuilder fluent interface
- Migration rollback support

**Migration Examples**:
- `CreateUsers.hx` - Basic table creation with indexes
- `CreatePosts.hx` - Advanced migration with foreign keys and constraints

**Generated DSL Example**:
```elixir
create table(:users) do
  add :id, :serial, primary_key: true
  add :name, :string, null: false
  add :email, :string, null: false
  add :age, :integer
  timestamps()
end

create unique_index(:users, [:email])
```

**How to Run**:
```bash
cd examples/04-ecto-migrations
npx haxe build.hxml
```

### 05-heex-templates  
**Status**: Production Ready ✨ **ENHANCED**
**Purpose**: HXX (Haxe JSX) template processing with Phoenix HEEx generation

**Key Features Demonstrated**:
- **HXX Template Processing**: JSX-like syntax for type-safe Phoenix templates
- **Raw String Extraction**: Advanced AST processing preserving HTML attributes
- **Multiline Template Support**: Complex templates with string interpolation
- **HEEx Format Generation**: Proper ~H sigil output with {} interpolation syntax
- **Phoenix LiveView Integration**: Seamless template compilation for LiveView components
- **Component Generation**: Automatic Phoenix component structure

**HXX Syntax Examples**:
```haxe
// Basic HXX template
function userProfile(user: User): String {
    return HXX('
        <div class="user-profile">
            <h2>${user.name}</h2>
            <p class="email">${user.email}</p>
            <button phx-click="edit">Edit</button>
        </div>
    ');
}

// Conditional rendering
function statusBadge(user: User): String {
    return HXX('
        <span class="badge ${user.active ? "active" : "inactive"}">
            ${user.active ? "Active" : "Inactive"}
        </span>
    ');
}
```

**Generated HEEx Output**:
```elixir
def user_profile(user) do
  ~H"""
  <div class="user-profile">
      <h2>{user.name}</h2>
      <p class="email">{user.email}</p>
      <button phx-click="edit">Edit</button>
  </div>
  """
end
```

**How to Run**:
```bash
cd examples/05-heex-templates
npx haxe build.hxml        # Compile HXX templates to HEEx
mix compile                # Compile generated Elixir
```

**Files Generated**:
- `templates_UserProfile.ex` - User profile HXX template compilation
- `templates_FormComponents.ex` - Form component HXX templates
- Proper HEEx format with HTML attribute preservation

### 06-user-management
**Status**: Production Ready  
**Purpose**: Multi-annotation integration showcase

**Key Features Demonstrated**:
- Multiple annotation usage on single project
- @:schema + @:changeset integration
- @:liveview real-time components
- @:genserver background processes
- Cross-module communication

**Components**:
- `Users.hx` (@:schema + @:changeset) - Ecto schema and validation
- `UserGenServer.hx` (@:genserver) - OTP background processes
- `UserLive.hx` (@:liveview) - Phoenix real-time interface

**How to Run**:
```bash
cd examples/06-user-management
npx haxe build.hxml
```

### test-integration
**Status**: Production Ready  
**Purpose**: Package resolution and basic compilation verification

**Key Features Demonstrated**:
- Package structure alignment
- Import resolution
- Basic compilation testing

**How to Run**:
```bash
cd examples/test-integration
npx haxe build.hxml
```

## Common Patterns

### Annotation Usage
All examples demonstrate proper annotation usage:
```haxe
@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
}
```

### Build Configuration
Standard build configuration pattern:
```hxml
-cp src_haxe
-cp ../../src
-cp ../../std
-lib reflaxe
-D reflaxe_runtime
--no-output

# List all modules to compile
ModuleName
AnotherModule
```

### Testing Integration
All examples include proper testing setup:
- Individual compilation testing
- Integration with comprehensive test suite
- Performance validation

## Development Workflow

1. **Create Haxe source files** in `src_haxe/` directory
2. **Add appropriate annotations** (@:schema, @:liveview, etc.)
3. **Configure build.hxml** with proper classpaths and modules
4. **Compile with** `npx haxe build.hxml`
5. **Test generated code** in Elixir/Phoenix environment

## Troubleshooting

### Common Issues
- **"Type not found"**: Check package structure matches directory structure
- **Function visibility**: Ensure utility functions are `public static`
- **Annotation conflicts**: Use annotation system to detect incompatible combinations
- **Build failures**: Check classpath configuration and dependencies

### 07-protocols  
**Status**: Production Ready  
**Purpose**: Elixir protocol definitions and implementations for polymorphic dispatch

**Key Features Demonstrated**:
- `@:protocol` annotation for defining protocols
- `@:impl` annotation for protocol implementations  
- Multiple implementations per protocol (String, Int, Float)
- Type-safe polymorphic dispatch
- Fallback implementations with `Any` type

**Files Included**:
- `protocols/Drawable.hx` - Protocol definition with draw() and area() methods
- `implementations/NumberDrawable.hx` - Int and Float implementations
- `implementations/StringDrawable.hx` - String implementation

**How to Run**:
```bash
cd examples/07-protocols
npx haxe build.hxml
```

**Generated Elixir**:
- `Drawable` protocol with proper @spec definitions
- `defimpl Drawable, for: String/Integer/Float` implementations
- Type-safe dispatch resolution

### 08-behaviors
**Status**: Production Ready  
**Purpose**: OTP behavior definitions with callback contracts and GenServer integration

**Key Features Demonstrated**:
- `@:behaviour` annotation for defining behaviors
- `@:callback` and `@:optional_callback` specifications
- `@:use` annotation for behavior adoption
- Compile-time validation of required callbacks
- Integration with GenServer and OTP patterns

**Files Included**:
- `behaviors/DataProcessor.hx` - Behavior definition with processing contract
- `implementations/StreamProcessor.hx` - GenServer + behavior implementation
- `implementations/BatchProcessor.hx` - Alternative implementation strategy

**How to Run**:
```bash
cd examples/08-behaviors
npx haxe build.hxml
```

**Generated Elixir**:
- `DataProcessor` behavior module with @callback specifications
- `@optional_callbacks` directives for flexible contracts
- `StreamProcessor` and `BatchProcessor` modules with @behaviour directives
- Complete OTP integration with GenServer callbacks

### todo-app (Real-World Example)
**Status**: Production Ready ✨ **ENHANCED WITH HXX**
**Purpose**: Complete Phoenix LiveView application demonstrating HXX template processing

**Key Features Demonstrated**:
- **Complete Phoenix App**: Runnable todo application with LiveView
- **HXX Template Processing**: Real-world usage of JSX-like syntax for Phoenix templates
- **LiveView Integration**: Full LiveView component with HXX-generated templates
- **User Management**: Complete CRUD operations with Ecto integration
- **Type-Safe Templates**: Compile-time validated template generation
- **Phoenix Conventions**: Generated code follows Phoenix directory structure exactly

**HXX Templates in Action**:
```haxe
@:liveview
class TodoLive {
    function render(assigns: Dynamic): String {
        return HXX('
            <div class="todo-app">
                <h1>Todo List</h1>
                <div class="todo-form">
                    <form phx-submit="add-todo">
                        <input type="text" name="title" placeholder="Add new todo...">
                        <button type="submit">Add</button>
                    </form>
                </div>
                <ul class="todo-list">
                    ${renderTodos(assigns.todos)}
                </ul>
            </div>
        ');
    }
    
    function renderTodos(todos: Array<Todo>): String {
        return todos.map(todo -> HXX('
            <li class="todo-item ${todo.completed ? "completed" : ""}">
                <input type="checkbox" 
                       phx-click="toggle" 
                       phx-value-id="${todo.id}"
                       ${todo.completed ? "checked" : ""}>
                <span>${todo.title}</span>
                <button phx-click="delete" phx-value-id="${todo.id}">
                    Delete
                </button>
            </li>
        ')).join("");
    }
}
```

**Generated LiveView Module**:
```elixir
defmodule TodoApp.TodoLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div class="todo-app">
        <h1>Todo List</h1>
        <div class="todo-form">
            <form phx-submit="add-todo">
                <input type="text" name="title" placeholder="Add new todo...">
                <button type="submit">Add</button>
            </form>
        </div>
        <ul class="todo-list">
            {render_todos(assigns.todos)}
        </ul>
    </div>
    """
  end
end
```

**How to Run**:
```bash
cd examples/todo-app
mix deps.get               # Install Phoenix dependencies
npx haxe build.hxml        # Compile Haxe to Elixir (includes HXX processing)
mix compile                # Compile generated Elixir
mix phx.server            # Start Phoenix development server
```

**Features Showcased**:
- Real-time todo management with LiveView
- Type-safe HXX template compilation
- Proper Phoenix directory structure
- Ecto schema and changeset integration
- Event handling with Phoenix events
- State management with socket assigns

**Files Generated**:
- `lib/todo_app_web/live/todo_live.ex` - Main LiveView with HXX templates
- `lib/todo_app_web/live/user_live.ex` - User management LiveView
- `lib/todo_app/schemas/user.ex` - User Ecto schema
- All files follow Phoenix conventions exactly

### Abstract Types Example
**Status**: Production Ready ✨ NEW  
**Purpose**: Type-safe wrappers with operator overloading

**Key Features Demonstrated**:
- Abstract type compilation to `_Impl_` modules
- Operator overloading with @:op metadata
- Constructor and conversion functions
- Type-safe arithmetic operations
- Implicit casting with from/to declarations

**Example Usage**:
```haxe
// Simple abstract type wrapping Int
abstract UserId(Int) from Int to Int {
    public function new(id: Int) {
        this = id;
    }
    
    @:op(A + B) public static function add(a: UserId, b: UserId): UserId {
        return new UserId(a.toInt() + b.toInt());
    }
    
    public function toInt(): Int {
        return this;
    }
}

// Complex abstract with multiple operators
abstract Money(Int) from Int {
    @:op(A + B) public static function add(a: Money, b: Money): Money;
    @:op(A * B) public static function multiply(a: Money, multiplier: Int): Money;
    @:to public function toDollars(): Float;
}
```

**Generated Elixir**:
```elixir
defmodule UserId_Impl_ do
  def _new(arg0) do
    arg0
  end
  
  def add(arg0, arg1) do
    UserId_Impl_._new(UserId_Impl_.to_int(arg0) + UserId_Impl_.to_int(arg1))
  end
  
  def to_int(arg0) do
    arg0
  end
end
```

**Usage in Main Code**:
```haxe
var user1 = new UserId(100);
var user2 = new UserId(200);
var combined = user1 + user2;  // Uses add operator
trace("Combined: " + combined.toString());
```

**Test Location**: `test/tests/abstract_types/`

### Performance Tips
- Use unified compilation instead of `--next` approach
- All modules compile in <1ms typically
- Leverage caching for repeated builds

For more detailed technical information, see FEATURES.md and ANNOTATIONS.md.