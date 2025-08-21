# Router DSL Migration Guide

## Migrating from Manual Functions to Declarative Syntax

This guide helps you migrate from the legacy manual router functions to the modern declarative `@:routes` syntax.

## Before and After Comparison

### Legacy Manual Syntax (Before)

```haxe
@:router
class TodoAppRouter {
    @:route({method: "LIVE", path: "/", controller: "TodoLive", action: "index"})
    public static function root(): Void {}
    
    @:route({method: "LIVE", path: "/todos", controller: "TodoLive", action: "index"})
    public static function todosIndex(): Void {}
    
    @:route({method: "LIVE", path: "/todos/:id", controller: "TodoLive", action: "show"})
    public static function todosShow(): Void {}
    
    @:route({method: "GET", path: "/api/users", controller: "UserController", action: "index"})
    public static function apiUsers(): Void {}
    
    @:route({method: "LIVE_DASHBOARD", path: "/dev/dashboard"})
    public static function dashboard(): Void {}
}
```

### Modern Declarative Syntax (After)

```haxe
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
    {name: "root", method: "LIVE", path: "/", controller: "TodoLive", action: "index"},
    {name: "todosIndex", method: "LIVE", path: "/todos", controller: "TodoLive", action: "index"},
    {name: "todosShow", method: "LIVE", path: "/todos/:id", controller: "TodoLive", action: "show"},
    {name: "apiUsers", method: "GET", path: "/api/users", controller: "UserController", action: "index"},
    {name: "dashboard", method: "LIVE_DASHBOARD", path: "/dev/dashboard"}
])
class TodoAppRouter {
    // Functions auto-generated - no manual code needed!
}
```

## Migration Benefits

### ✅ What You Gain

1. **No Empty Functions** - Eliminates meaningless placeholder functions
2. **Better IDE Experience** - Generated functions provide better autocomplete
3. **Type-Safe Helpers** - Functions return String paths for route construction
4. **Cleaner Code** - Declarative array is more readable than scattered functions
5. **Compile-Time Validation** - Build macro catches errors during compilation
6. **Consistent Formatting** - All routes defined in standardized object format

### ❌ What You Lose

1. **Per-Function Annotations** - Individual route annotations move to array objects
2. **Mixed Metadata** - All route metadata must be in the @:routes array
3. **Gradual Definition** - All routes must be defined upfront in the array

## Step-by-Step Migration Process

### Step 1: Prepare Your Build Configuration

Ensure your `build.hxml` includes the macro source path:

```hxml
-cp src
-cp std
-lib reflaxe

# Required for build macro
-D reflaxe_runtime

# Your router classes
TodoAppRouter
```

### Step 2: Add Build Macro Annotation

Add the build macro to your router class:

```haxe
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())  // ADD THIS LINE
class TodoAppRouter {
    // ... existing functions
}
```

### Step 3: Extract Route Data

Convert each function to an array object. For each function:

```haxe
// FROM: Function with annotation
@:route({method: "LIVE", path: "/todos/:id", controller: "TodoLive", action: "show"})
public static function todosShow(): Void {}

// TO: Object in array
{name: "todosShow", method: "LIVE", path: "/todos/:id", controller: "TodoLive", action: "show"}
```

### Step 4: Create @:routes Array

Combine all route objects into the `@:routes` annotation:

```haxe
@:routes([
    {name: "root", method: "LIVE", path: "/", controller: "TodoLive", action: "index"},
    {name: "todosIndex", method: "LIVE", path: "/todos", controller: "TodoLive", action: "index"},
    {name: "todosShow", method: "LIVE", path: "/todos/:id", controller: "TodoLive", action: "show"},
    // ... etc
])
```

### Step 5: Remove Manual Functions

Delete all the empty function implementations:

```haxe
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([...])
class TodoAppRouter {
    // Clean! No manual functions needed
}
```

### Step 6: Test Compilation

Verify the migration works correctly:

```bash
npx haxe build.hxml
```

You should see macro output like:
```
RouterBuildMacro: Found 5 route definitions in TodoAppRouter
RouterBuildMacro: Generated function root for route LIVE /
RouterBuildMacro: Generated function todosIndex for route LIVE /todos
RouterBuildMacro: Successfully generated 5 route functions
```

### Step 7: Verify Generated Output

Check that the generated `router.ex` file is identical to before:

```elixir
defmodule TodoAppWeb.Router do
  # ... same Phoenix routes as before
  live "/", TodoLive, :root
  live "/todos", TodoLive, :todosIndex
  live "/todos/:id", TodoLive, :todosShow
  # ...
end
```

## Common Migration Patterns

### Pattern 1: Simple Route

```haxe
// FROM
@:route({method: "GET", path: "/users", controller: "UserController", action: "index"})
public static function users(): Void {}

// TO  
{name: "users", method: "GET", path: "/users", controller: "UserController", action: "index"}
```

### Pattern 2: LiveView Route

```haxe
// FROM
@:route({method: "LIVE", path: "/todos/:id/edit", controller: "TodoLive", action: "edit"})
public static function editTodo(): Void {}

// TO
{name: "editTodo", method: "LIVE", path: "/todos/:id/edit", controller: "TodoLive", action: "edit"}
```

### Pattern 3: LiveDashboard Route

```haxe
// FROM
@:route({method: "LIVE_DASHBOARD", path: "/dev/dashboard"})
public static function dashboard(): Void {}

// TO
{name: "dashboard", method: "LIVE_DASHBOARD", path: "/dev/dashboard"}
```

### Pattern 4: API Routes

```haxe
// FROM
@:route({method: "POST", path: "/api/todos", controller: "TodoController", action: "create"})
public static function createTodo(): Void {}

// TO
{name: "createTodo", method: "POST", path: "/api/todos", controller: "TodoController", action: "create"}
```

## Validation and Error Handling

### Compile-Time Validation

The build macro validates routes and provides helpful errors:

```haxe
// ERROR: Missing required field
{method: "GET", path: "/users"}  // Missing 'name'
// → "Route missing required 'name' field"

// ERROR: Duplicate names
{name: "users", method: "GET", path: "/users"},
{name: "users", method: "POST", path: "/users"}  // Duplicate name
// → "Duplicate route name: users"

// WARNING: Unknown method
{name: "test", method: "INVALID", path: "/test"}
// → "Unknown HTTP method: INVALID. Valid: GET, POST, PUT, DELETE, PATCH, LIVE, LIVE_DASHBOARD"
```

### Runtime Behavior

Generated functions behave identically to manual functions:

```haxe
// Both work the same way
var path1 = TodoAppRouter.root();        // "/"
var path2 = TodoAppRouter.todosShow();   // "/todos/:id"

// Generated functions have proper @:route metadata
// RouterCompiler processes them identically
```

## IDE Support Improvements

### Before Migration (Manual Functions)

```haxe
public static function root(): Void {}  // IDE shows: () -> Void
```

- ❌ Function returns `Void` (not useful)
- ❌ No meaningful return value
- ❌ Function body is empty placeholder

### After Migration (Generated Functions)

```haxe
// Generated by macro:
public static function root(): String { return "/"; }  // IDE shows: () -> String
```

- ✅ Function returns `String` (the route path)
- ✅ Useful return value for route construction
- ✅ Function body contains actual logic

## Troubleshooting Migration Issues

### Issue: Build Macro Not Running

**Symptoms**: No functions generated, compilation succeeds without macro output

**Solutions**:
1. Ensure `@:build()` annotation is present
2. Check that macro source is in classpath (`-cp src`)
3. Verify `reflaxe_runtime` compilation flag is set

### Issue: Functions Not Found After Migration

**Symptoms**: Compilation errors about missing route functions

**Solutions**:
1. Check function names in array match previous function names
2. Ensure all functions are included in `@:routes` array
3. Verify macro ran successfully (check for trace output)

### Issue: Generated Routes Don't Match

**Symptoms**: Phoenix router.ex has different routes than expected

**Solutions**:
1. Compare route objects to original `@:route` annotations carefully
2. Check for typos in controller/action names
3. Verify path patterns are identical

### Issue: IDE Autocomplete Not Working

**Symptoms**: Generated functions don't appear in code completion

**Solutions**:
1. Restart IDE to refresh build macro results
2. Ensure project is configured with proper classpath
3. Check that Haxe language server recognizes macro-generated fields

## Best Practices for Migration

### 1. Migrate Incrementally

If you have multiple router classes, migrate one at a time:

```haxe
// Migrate in stages
class AppRouter { /* migrate first */ }
class ApiRouter { /* migrate second */ }  
class AdminRouter { /* migrate last */ }
```

### 2. Keep Function Names Consistent

Maintain existing function names to avoid breaking route usage:

```haxe
// Keep same function name
@:route({method: "GET", path: "/profile", controller: "UserController", action: "profile"})
public static function userProfile(): Void {}

// TO
{name: "userProfile", method: "GET", path: "/profile", controller: "UserController", action: "profile"}
```

### 3. Group Related Routes

Organize routes logically in the array:

```haxe
@:routes([
    // Authentication
    {name: "login", method: "LIVE", path: "/login", controller: "AuthLive", action: "login"},
    {name: "register", method: "LIVE", path: "/register", controller: "AuthLive", action: "register"},
    
    // User management
    {name: "profile", method: "LIVE", path: "/profile", controller: "UserLive", action: "show"},
    {name: "editProfile", method: "LIVE", path: "/profile/edit", controller: "UserLive", action: "edit"},
    
    // API endpoints
    {name: "apiLogin", method: "POST", path: "/api/login", controller: "AuthController", action: "login"}
])
```

### 4. Validate Before Committing

Always test compilation and generated output:

```bash
# Test compilation
npx haxe build.hxml

# Check generated routes
cat lib/your_app_web/router.ex

# Run any existing router tests
mix test test/your_app_web/router_test.exs
```

## Migration Checklist

- [ ] Add `@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())` annotation
- [ ] Create `@:routes([...])` array with all route definitions
- [ ] Remove all manual function implementations
- [ ] Test compilation succeeds with macro output
- [ ] Verify generated `router.ex` matches expected Phoenix routes
- [ ] Check that route helper functions still work correctly
- [ ] Update any documentation referencing old syntax
- [ ] Test IDE autocomplete and navigation work properly

## Further Resources

- [`documentation/ROUTER_DSL.md`](../ROUTER_DSL.md) - Complete Router DSL documentation
- [`examples/todo-app/src_haxe/TodoAppRouterNew.hx`](../../examples/todo-app/src_haxe/TodoAppRouterNew.hx) - Modern syntax example
- [`test/tests/RouterBuildMacro/Main.hx`](../../test/tests/RouterBuildMacro/Main.hx) - Build macro test case
- [`src/reflaxe/elixir/macros/RouterBuildMacro.hx`](../../src/reflaxe/elixir/macros/RouterBuildMacro.hx) - Build macro implementation