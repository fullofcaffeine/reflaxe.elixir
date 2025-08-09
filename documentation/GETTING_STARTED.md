# Getting Started with Reflaxe.Elixir

This guide will help you set up and start using Reflaxe.Elixir to compile Haxe code to Elixir/Phoenix applications.

## Prerequisites

Before you begin, ensure you have:

- **Node.js** (16+ recommended) for lix package manager
- **Elixir** (1.14+ recommended) for running generated code
- **Phoenix** (1.7+ recommended) if using Phoenix features
- **PostgreSQL** (optional, for database examples)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/YourUsername/haxe.elixir
cd haxe.elixir
```

### 2. Install Dependencies

**Install Haxe dependencies with lix**:
```bash
npm install        # Installs lix locally
npx lix download   # Downloads Haxe libraries
```

**Install Elixir dependencies**:
```bash
mix deps.get       # Installs Elixir dependencies
```

### 3. Verify Installation

Run the comprehensive test suite:
```bash
npm test
```

You should see output like:
```
🧪 === COMPREHENSIVE REFLAXE.ELIXIR TEST SUITE ===
📋 Testing Haxe→Elixir Compiler...
🎉 ALL HAXE COMPILER TESTS PASSING!
📋 Testing Generated Elixir Code & Mix Tasks...
🎉 ALL TESTS PASSING!
```

## Your First Example

Let's start with the simplest example to understand the basic workflow.

### 1. Create a Simple Module

Create a file `MyModule.hx`:
```haxe
package myapp;

class MyModule {
    public static function greet(name: String): String {
        return "Hello, " + name + "!";
    }
    
    public static function main(): Void {
        trace("MyModule compiled successfully!");
    }
}
```

### 2. Create Build Configuration

Create `build.hxml`:
```hxml
-cp .
-cp node_modules/reflaxe.elixir/src
-lib reflaxe
-D reflaxe_runtime
--no-output

myapp.MyModule
```

### 3. Compile

```bash
npx haxe build.hxml
```

Success! Your Haxe code has been compiled to Elixir patterns.

## Working with Annotations

Reflaxe.Elixir's power comes from annotations that generate specific Elixir patterns.

### Ecto Schema Example

```haxe
@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "string", nullable: false}) 
    public var email: String;
    
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
}
```

This generates a complete Ecto.Schema module with proper field definitions and validations.

### Phoenix LiveView Example

```haxe
@:liveview
class UserLive {
    var users: Array<User> = [];
    
    function mount(params: Dynamic, session: Dynamic, socket: Dynamic) {
        return {
            status: "ok",
            socket: assign(socket, "users", Users.list_users())
        };
    }
    
    function handle_event(event: String, params: Dynamic, socket: Dynamic) {
        return switch(event) {
            case "refresh":
                {status: "noreply", socket: assign(socket, "users", Users.list_users())};
            default:
                {status: "noreply", socket: socket};
        }
    }
    
    function render(assigns: Dynamic): String {
        return hxx('<div>User management interface</div>');
    }
}
```

This generates a complete Phoenix LiveView module with real-time capabilities.

## Exploring Examples

The project includes comprehensive examples demonstrating different features:

### 1. Simple Modules (01-simple-modules)
```bash
cd examples/01-simple-modules
npx haxe compile-all.hxml
```

**What you'll learn**:
- Basic compilation patterns
- Module structure generation
- Function compilation

### 2. Mix Project Integration (02-mix-project)
```bash
cd examples/02-mix-project
npx haxe build.hxml
mix test
```

**What you'll learn**:
- Mix project integration
- Multiple utility modules
- Testing generated code

### 3. Ecto Migrations (04-ecto-migrations)
```bash
cd examples/04-ecto-migrations
npx haxe build.hxml
```

**What you'll learn**:
- Database migration generation
- Table operations with DSL
- Migration rollback support

### 4. User Management (06-user-management)
```bash
cd examples/06-user-management
npx haxe build.hxml
```

**What you'll learn**:
- Multi-annotation integration
- Schema + Changeset + LiveView + GenServer
- Real-world application patterns

## Development Workflow

### 1. Project Structure

Organize your Haxe code following these conventions:
```
src_haxe/
├── contexts/          # @:schema and @:changeset classes
│   ├── Users.hx
│   └── Posts.hx
├── live/             # @:liveview classes
│   ├── UserLive.hx
│   └── PostLive.hx
├── services/         # @:genserver classes
│   └── CacheService.hx
├── migrations/       # @:migration classes
│   ├── CreateUsers.hx
│   └── CreatePosts.hx
└── templates/        # @:template classes
    └── Components.hx
```

### 2. Build Configuration

Create a `build.hxml` that includes all necessary classpaths:
```hxml
# Source paths
-cp src_haxe
-cp path/to/reflaxe.elixir/src  
-cp path/to/reflaxe.elixir/std

# Libraries
-lib reflaxe

# Compilation flags
-D reflaxe_runtime
--no-output

# Modules to compile
contexts.Users
live.UserLive
services.CacheService
```

### 3. Compilation and Testing

**Compile Haxe to Elixir**:
```bash
npx haxe build.hxml
```

**Test generated code**:
```bash
mix test
```

**Run comprehensive validation**:
```bash
npm test
```

## Common Patterns

### 1. Utility Functions

Make utility functions `public static`:
```haxe
class StringUtils {
    public static function slugify(text: String): String {
        // Implementation
        return text.toLowerCase();
    }
    
    public static function main(): Void {
        trace("StringUtils compiled successfully!");
    }
}
```

### 2. Error Handling

Use Elixir-style error tuples:
```haxe
public static function createUser(attrs: Dynamic): {status: String, ?user: User, ?error: String} {
    if (isValid(attrs)) {
        return {status: "ok", user: newUser};
    } else {
        return {status: "error", error: "Invalid data"};
    }
}
```

### 3. Pattern Matching

Use Haxe switch for Elixir pattern matching:
```haxe
function handle_event(event: String, params: Dynamic, socket: Dynamic) {
    return switch(event) {
        case "create": handleCreate(params, socket);
        case "update": handleUpdate(params, socket);
        case "delete": handleDelete(params, socket);
        default: {status: "noreply", socket: socket};
    }
}
```

## Troubleshooting

### "Type not found" Error
**Problem**: Package structure doesn't match directory structure
**Solution**: Ensure directory structure matches package declarations

### Function Visibility Issues  
**Problem**: Functions not accessible from other modules
**Solution**: Use `public static` for utility functions

### Annotation Conflicts
**Problem**: Incompatible annotations on same class
**Solution**: Check annotation compatibility in [ANNOTATIONS.md](ANNOTATIONS.md)

### Build Configuration Issues
**Problem**: Classpath errors or missing dependencies
**Solution**: Verify all `-cp` paths and library installations

## Next Steps

1. **Explore Examples**: Work through each example in order
2. **Read Documentation**: Check [FEATURES.md](FEATURES.md) for current capabilities
3. **Learn Annotations**: Master annotation usage with [ANNOTATIONS.md](ANNOTATIONS.md)
4. **Build Your Application**: Start with simple modules and gradually add complexity
5. **Join Community**: Contribute feedback and improvements

## Performance Tips

- **Compilation Speed**: All features compile in <1ms typically
- **Build Optimization**: Use unified compilation instead of `--next` approach
- **Caching**: Leverage lix caching for faster repeated builds
- **Testing**: Use `npm test` for comprehensive validation

For detailed feature status and technical implementation notes, see [FEATURES.md](FEATURES.md) and the project's CLAUDE.md file.