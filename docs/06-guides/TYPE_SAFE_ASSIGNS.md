# Type-Safe Phoenix Assigns Guide

This guide covers the new type-safe Phoenix abstractions introduced in Reflaxe.Elixir: `Assigns<T>`, `LiveViewSocket<T>`, `FlashMessage`, and `RouteParams<T>`. These abstractions provide compile-time type checking for Phoenix APIs while maintaining full runtime compatibility.

## Overview

Traditional Phoenix development relies on dynamic assigns maps and runtime type checking. With Reflaxe.Elixir's type-safe abstractions, you get:

- **Compile-time type checking** for all template variables and socket operations
- **IDE autocomplete and navigation** for assigns and socket state
- **Runtime compatibility** with existing Phoenix patterns
- **Gradual adoption** - migrate from Dynamic to typed abstractions incrementally

## Type-Safe Assigns

### Basic Usage Pattern

**Traditional Dynamic Approach:**
```haxe
function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
    return socket.assign({
        user: getCurrentUser(session),
        posts: [],
        loading: true
    });
}
```

**Type-Safe Approach:**
```haxe
import phoenix.types.Assigns;

typedef UserPageAssigns = {
    user: User,
    posts: Array<Post>,
    loading: Bool,
    ?flash: FlashMessage  // Optional field
}

function mount(params: Dynamic, session: Dynamic, socket: LiveViewSocket<UserPageAssigns>): LiveViewSocket<UserPageAssigns> {
    return socket.assign({
        user: getCurrentUser(session),
        posts: [],
        loading: true
    });
}
```

### Creating Typed Assigns

#### From Dynamic Values (Phoenix Integration)
```haxe
// When receiving assigns from Phoenix
function handleAssigns(rawAssigns: Dynamic): Assigns<UserPageAssigns> {
    return Assigns.fromDynamic(rawAssigns);
}
```

#### From Typed Objects (Haxe Code)
```haxe
// When building assigns in Haxe code
function buildUserAssigns(user: User, posts: Array<Post>): Assigns<UserPageAssigns> {
    return Assigns.fromObject({
        user: user,
        posts: posts,
        loading: false
    });
}
```

### Field Access Patterns

#### Type-Safe Field Access
```haxe
function renderUserInfo(assigns: Assigns<UserPageAssigns>): String {
    // Compile-time type checking
    var userName = assigns.user.name;        // String
    var postCount = assigns.posts.length;   // Int
    var isLoading = assigns.loading;         // Bool
    
    return 'Welcome ${userName}! You have ${postCount} posts.';
}
```

#### Dynamic Field Access (when needed)
```haxe
function handleDynamicAssign(assigns: Assigns<UserPageAssigns>, key: String): Dynamic {
    // Use array access syntax for dynamic keys
    return assigns[key];
}
```

#### Optional Field Handling
```haxe
function renderFlash(assigns: Assigns<UserPageAssigns>): String {
    return switch(assigns.flash) {
        case null: '';
        case flash: '<div class="alert">${flash.message}</div>';
    };
}
```

## LiveView Socket Type Safety

### Socket State Management

**Define Socket State Type:**
```haxe
typedef TodoSocketState = {
    todos: Array<Todo>,
    filter: TodoFilter,
    editingId: Null<Int>
}
```

**Type-Safe Socket Operations:**
```haxe
import phoenix.types.LiveViewSocket;

function mount(params: Dynamic, session: Dynamic, socket: LiveViewSocket<TodoSocketState>): LiveViewSocket<TodoSocketState> {
    return socket
        .assign({
            todos: TodoRepo.list(),
            filter: All,
            editingId: null
        })
        .subscribe("todo_updates");
}

function handleEvent(event: String, params: Dynamic, socket: LiveViewSocket<TodoSocketState>): LiveViewSocket<TodoSocketState> {
    return switch(event) {
        case "add_todo":
            var newTodo = Todo.create(params["title"]);
            socket.assign({
                todos: socket.assigns.todos.concat([newTodo])
            });
            
        case "toggle_filter":
            socket.assign({
                filter: TodoFilter.fromString(params["filter"])
            });
            
        case _: socket;
    };
}
```

### Socket Helper Methods

```haxe
function getCurrentUser(socket: LiveViewSocket<UserPageAssigns>): User {
    return socket.assigns.user;
}

function updateLoadingState(socket: LiveViewSocket<UserPageAssigns>, loading: Bool): LiveViewSocket<UserPageAssigns> {
    return socket.assign({loading: loading});
}

function pushUserUpdate(socket: LiveViewSocket<UserPageAssigns>, user: User): LiveViewSocket<UserPageAssigns> {
    return socket
        .assign({user: user})
        .pushEvent("user_updated", {id: user.id});
}
```

## Flash Messages

### FlashMessage Type Definition
```haxe
typedef FlashMessage = {
    type: FlashType,
    message: String,
    ?title: String,
    ?dismissible: Bool
}

enum FlashType {
    Info;
    Success;
    Warning;
    Error;
}
```

### Flash Message Patterns
```haxe
import phoenix.types.Flash;

function setSuccessFlash(socket: LiveViewSocket<TodoSocketState>, message: String): LiveViewSocket<TodoSocketState> {
    return socket.putFlash("info", Flash.success(message));
}

function setErrorFlash(socket: LiveViewSocket<TodoSocketState>, message: String, title: String): LiveViewSocket<TodoSocketState> {
    return socket.putFlash("error", Flash.error(message, title));
}

function renderFlashMessage(flash: FlashMessage): String {
    var alertClass = switch(flash.type) {
        case Info: "alert-info";
        case Success: "alert-success";
        case Warning: "alert-warning";
        case Error: "alert-danger";
    };
    
    var titleHtml = flash.title != null ? '<h4>${flash.title}</h4>' : '';
    var dismissButton = flash.dismissible == true ? '<button class="close" data-dismiss="alert">×</button>' : '';
    
    return '<div class="alert ${alertClass}">${dismissButton}${titleHtml}${flash.message}</div>';
}
```

## Route Parameters

### Type-Safe Route Parameters
```haxe
import phoenix.types.RouteParams;

typedef UserShowParams = {
    id: Int,
    ?tab: String  // Optional query parameter
}

typedef PostEditParams = {
    user_id: Int,
    id: Int
}

function mount(params: RouteParams<UserShowParams>, session: Dynamic, socket: LiveViewSocket<UserPageAssigns>): LiveViewSocket<UserPageAssigns> {
    var userId = params.id;  // Type-safe Int access
    var activeTab = params.tab ?? "profile";  // Optional with default
    
    return socket.assign({
        user: UserRepo.get(userId),
        activeTab: activeTab,
        loading: false
    });
}
```

### Parameter Validation
```haxe
function validateUserParams(rawParams: Dynamic): Result<UserShowParams, String> {
    return try {
        var params: UserShowParams = cast rawParams;
        if (params.id <= 0) {
            Error("Invalid user ID");
        } else {
            Ok(params);
        }
    } catch (e: Dynamic) {
        Error("Invalid parameters format");
    };
}
```

## Migration Strategies

### 1. Gradual Type Introduction

**Start with Dynamic, Add Types Incrementally:**
```haxe
// Phase 1: Keep existing Dynamic
function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
    return socket.assign({user: getUser()});
}

// Phase 2: Add return type
function mount(params: Dynamic, session: Dynamic, socket: Dynamic): LiveViewSocket<Dynamic> {
    return socket.assign({user: getUser()});
}

// Phase 3: Add assigns type  
function mount(params: Dynamic, session: Dynamic, socket: Dynamic): LiveViewSocket<UserAssigns> {
    return socket.assign({user: getUser()});
}

// Phase 4: Full type safety
function mount(params: RouteParams<UserParams>, session: Dynamic, socket: LiveViewSocket<UserAssigns>): LiveViewSocket<UserAssigns> {
    return socket.assign({user: getUser()});
}
```

### 2. Interface Compatibility

**Maintains Phoenix Compatibility:**
```haxe
// Generated Elixir maintains Phoenix patterns
def mount(params, session, socket) do
  socket
  |> assign(:user, get_user())
  |> assign(:loading, false)
end
```

**But with compile-time guarantees:**
```haxe
// Haxe source has full type checking
socket.assign({
    user: getUser(),     // Must return User type
    loading: false       // Must be Bool type
});
```

### 3. Template Integration

**Type-Safe Template Variables:**
```haxe
// HXX template with type checking
return HXX.hxx('
    <div>
        <h1>Welcome, ${assigns.user.name}!</h1>
        <p>Posts: ${assigns.posts.length}</p>
        {assigns.loading ? 
            <div class="spinner">Loading...</div> : 
            <div>Content loaded!</div>
        }
    </div>
');
```

**Generates Phoenix HEEx:**
```elixir
~H"""
<div>
    <h1>Welcome, <%= @user.name %>!</h1>
    <p>Posts: <%= length(@posts) %></p>
    <%= if @loading do %>
        <div class="spinner">Loading...</div>
    <% else %>
        <div>Content loaded!</div>
    <% end %>
</div>
"""
```

## Best Practices

### 1. Define Clear Assign Types
```haxe
// ✅ GOOD: Explicit, documented types
typedef DashboardAssigns = {
    /** Current authenticated user */
    user: User,
    /** List of user's projects */
    projects: Array<Project>,
    /** Currently selected project ID */
    ?selectedProjectId: Int,
    /** Loading state for async operations */
    loading: Bool
}
```

### 2. Use Optional Fields Appropriately
```haxe
// ✅ GOOD: Optional for truly optional data
typedef UserProfileAssigns = {
    user: User,                    // Always required
    ?avatar: String,              // Optional profile image
    ?lastLoginDate: Date          // May not exist for new users
}
```

### 3. Provide Type-Safe Helpers
```haxe
// ✅ GOOD: Type-safe helper functions
class SocketHelpers {
    public static function setUser<T>(socket: LiveViewSocket<T>, user: User): LiveViewSocket<T> {
        return socket.assign({user: user});
    }
    
    public static function setLoading<T>(socket: LiveViewSocket<T>, loading: Bool): LiveViewSocket<T> {
        return socket.assign({loading: loading});
    }
}
```

### 4. Handle Errors Gracefully
```haxe
// ✅ GOOD: Graceful error handling
function safeAssignUser(socket: LiveViewSocket<UserAssigns>, userId: Int): LiveViewSocket<UserAssigns> {
    return switch(UserRepo.find(userId)) {
        case Ok(user): 
            socket.assign({user: user, loading: false});
        case Error(reason):
            socket
                .assign({loading: false})
                .putFlash("error", 'Failed to load user: ${reason}');
    };
}
```

## Troubleshooting

### Common Issues

**1. Type Mismatch Errors:**
```haxe
// ❌ ERROR: Type mismatch
socket.assign({user: "invalid"}); // String instead of User

// ✅ FIX: Use correct type
socket.assign({user: User.fromString("username")});
```

**2. Missing Optional Fields:**
```haxe
// ❌ ERROR: flash is required but not provided
typedef MyAssigns = {
    user: User,
    flash: FlashMessage  // Not optional
}

// ✅ FIX: Make optional if not always present
typedef MyAssigns = {
    user: User,
    ?flash: FlashMessage  // Optional
}
```

**3. Dynamic Access When Type Available:**
```haxe
// ❌ SUBOPTIMAL: Using dynamic access
var userName = assigns["user"]["name"];

// ✅ BETTER: Use typed access
var userName = assigns.user.name;
```

### Debugging Tips

1. **Check assign type definitions** - Ensure your typedef matches actual data structure
2. **Use gradual typing** - Start with Dynamic and add types incrementally  
3. **Leverage compiler errors** - Type errors guide you to correct usage
4. **Test with Phoenix** - Ensure generated Elixir works correctly at runtime

## Related Documentation

- [`phoenix/types/Assigns.hx`](/std/phoenix/types/Assigns.hx) - Assigns<T> source code
- [`phoenix/types/SocketState.hx`](/std/phoenix/types/SocketState.hx) - LiveViewSocket<T> implementation
- [`phoenix/types/Flash.hx`](/std/phoenix/types/Flash.hx) - Flash message types
- [`documentation/guides/HAXE_OPERATOR_OVERLOADING.md`](HAXE_OPERATOR_OVERLOADING.md) - Operator overloading patterns used
- [`documentation/paradigms/PARADIGM_BRIDGE.md`](/documentation/paradigms/PARADIGM_BRIDGE.md) - Understanding functional patterns

**See also**: [`std/AGENTS.md`](/std/AGENTS.md) for standard library development patterns and architectural guidance.