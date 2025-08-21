# HXX Template Guide

## What is HXX?

HXX (Haxe JSX) brings JSX-like syntax to Haxe for creating Phoenix HEEx templates. It provides a familiar, type-safe way to write templates that **compile to proper Phoenix LiveView HEEx format**.

**Important**: HXX is a **compile-time transformation tool**, not a runtime library. Templates are processed during Haxe→Elixir compilation and generate standard Phoenix ~H sigils with no runtime dependencies.

## Getting Started

### Project Setup

To use HXX in your project, create a local `HXX.hx` file in your source directory:

```haxe
// src_haxe/HXX.hx
class HXX {
    public static function hxx(templateStr: String): String {
        // Placeholder function for type checking
        // The Reflaxe.Elixir compiler transforms calls to this function
        return templateStr;
    }
}
```

**Why needed**: This provides the function signature for Haxe type checking. The actual template processing is handled by the Reflaxe.Elixir compiler during compilation.

### Basic Syntax

HXX templates use familiar JSX-like syntax with Haxe string interpolation:

```haxe
function render(assigns: Dynamic): String {
    return HXX('
        <div class="container">
            <h1>Welcome, ${assigns.user.name}!</h1>
        </div>
    ');
}
```

This compiles to:

```elixir
def render(assigns) do
  ~H"""
  <div class="container">
      <h1>Welcome, {assigns.user.name}!</h1>
  </div>
  """
end
```

### Template Interpolation

HXX uses `${}` syntax for interpolation, which automatically converts to HEEx `{}` format:

```haxe
// Haxe HXX
HXX('<p>Count: ${assigns.count}</p>')

// Generated HEEx
~H"""<p>Count: {assigns.count}</p>"""
```

## Phoenix LiveView Integration

### LiveView Components

HXX integrates seamlessly with Phoenix LiveView components:

```haxe
@:liveview
class UserProfile {
    function render(assigns: Dynamic): String {
        return HXX('
            <div class="user-profile">
                <img src="${assigns.user.avatar}" alt="Avatar">
                <div class="info">
                    <h2>${assigns.user.name}</h2>
                    <p class="email">${assigns.user.email}</p>
                    <button phx-click="edit">Edit Profile</button>
                </div>
            </div>
        ');
    }
}
```

### Event Handling

Phoenix events work naturally with HXX:

```haxe
function todoItem(todo: Todo): String {
    return HXX('
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
    ');
}
```

## Advanced Features

### Conditional Rendering

Use Haxe's ternary operator for conditional content:

```haxe
function statusBadge(user: User): String {
    return HXX('
        <span class="badge ${user.active ? "badge-success" : "badge-danger"}">
            ${user.active ? "Active" : "Inactive"}
        </span>
    ');
}
```

### Multiline Templates

HXX handles complex multiline templates with proper formatting:

```haxe
function userCard(user: User): String {
    return HXX('
        <div class="card">
            <div class="card-header">
                <h3>${user.name}</h3>
                <span class="role">${user.role}</span>
            </div>
            <div class="card-body">
                <p>${user.bio}</p>
                <div class="actions">
                    <button phx-click="message" phx-value-user="${user.id}">
                        Message
                    </button>
                    <button phx-click="view-profile" phx-value-user="${user.id}">
                        View Profile
                    </button>
                </div>
            </div>
        </div>
    ');
}
```

### Component Composition

Break down complex templates into reusable functions:

```haxe
function userList(assigns: Dynamic): String {
    var users = assigns.users;
    var userItems = users.map(user -> userListItem(user)).join("");
    
    return HXX('
        <div class="user-list">
            <h2>Users (${users.length})</h2>
            <ul class="users">
                ${userItems}
            </ul>
        </div>
    ');
}

function userListItem(user: User): String {
    return HXX('
        <li class="user-item">
            <img src="${user.avatar}" class="avatar">
            <div class="details">
                <span class="name">${user.name}</span>
                <span class="email">${user.email}</span>
            </div>
        </li>
    ');
}
```

### Phoenix Helper Functions ✨ **NEW**

HXX seamlessly integrates with Phoenix helper functions through the **@:templateHelper metadata system**, providing automatic detection and proper compilation of Phoenix template utilities.

#### Automatic Phoenix.Component Integration

Phoenix.Component functions are automatically detected and compiled properly:

```haxe
import phoenix.Component;

function renderSecureForm(assigns: Dynamic): String {
    return HXX('
        <form method="post">
            <meta name="csrf-token" content={Component.get_csrf_token()}/>
            <div class="field">
                <input type="text" name="title" required/>
            </div>
            <button type="submit">Submit</button>
        </form>
    ');
}
```

**Generated Phoenix HEEx:**
```elixir
~H"""
<form method="post">
    <meta name="csrf-token" content={get_csrf_token()}/>
    <div class="field">
        <input type="text" name="title" required/>
    </div>
    <button type="submit">Submit</button>
</form>
"""
```

#### How It Works: @:templateHelper Metadata

The HXX compiler uses metadata-driven detection instead of hardcoded function lists:

```haxe
// In phoenix/Component.hx
@:templateHelper
extern class Component {
    @:templateHelper
    static function get_csrf_token(): String;
    
    @:templateHelper  
    static function form_for(changeset: Dynamic, action: String): String;
    
    @:templateHelper
    static function text_input(form: Dynamic, field: String): String;
}
```

**Benefits of Metadata System:**
- **Extensible** - Add new helper functions without modifying compiler
- **Type-Safe** - Full compile-time validation of helper usage
- **Maintainable** - Clear declaration of template-compatible functions
- **Future-Proof** - Easy to add custom Phoenix libraries

#### Creating Custom Template Helpers

You can create your own template helper functions using the @:templateHelper annotation:

```haxe
// Custom helper module
class MyHelpers {
    @:templateHelper
    public static function formatCurrency(amount: Float): String {
        return '$${Math.fround(amount * 100) / 100}';
    }
    
    @:templateHelper
    public static function timeAgo(date: Date): String {
        var now = Date.now();
        var diff = now.getTime() - date.getTime();
        var minutes = Math.floor(diff / 60000);
        
        return if (minutes < 1) "just now";
        else if (minutes < 60) '${minutes} minutes ago';
        else if (minutes < 1440) '${Math.floor(minutes/60)} hours ago';
        else '${Math.floor(minutes/1440)} days ago';
    }
}
```

**Usage in Templates:**
```haxe
function renderProduct(assigns: Dynamic): String {
    return HXX('
        <div class="product">
            <h3>${assigns.product.name}</h3>
            <p class="price">{MyHelpers.formatCurrency(assigns.product.price)}</p>
            <p class="updated">Updated {MyHelpers.timeAgo(assigns.product.updatedAt)}</p>
        </div>
    ');
}
```

**Generated HEEx:**
```elixir
~H"""
<div class="product">
    <h3><%= @product.name %></h3>
    <p class="price">{format_currency(@product.price)}</p>
    <p class="updated">Updated {time_ago(@product.updated_at)}</p>
</div>
"""
```

#### Function Name Conversion

Template helper functions automatically convert from camelCase to snake_case in HTML attributes:

```haxe
// Haxe HXX
<div class={MyHelpers.getStatusClass(status)} 
     id={MyHelpers.generateElementId("item", index)}>
</div>

// Generated HEEx  
<div class={get_status_class(status)}
     id={generate_element_id("item", index)}>
</div>
```

#### Advanced Template Helper Patterns

**Conditional Helper Usage:**
```haxe
function renderUser(assigns: Dynamic): String {
    var user = assigns.user;
    return HXX('
        <div class="user">
            <img src={user.avatar ?? Component.default_avatar_url()} 
                 alt="Avatar"/>
            <span class="status {user.isOnline ? Component.online_class() : Component.offline_class()}">
                {user.isOnline ? "Online" : "Offline"}
            </span>
        </div>
    ');
}
```

**Helper Function Chaining:**
```haxe
function renderTimestamp(assigns: Dynamic): String {
    return HXX('
        <time datetime={DateHelpers.toIsoString(assigns.date)}
              title={DateHelpers.formatLong(assigns.date)}>
            {DateHelpers.formatRelative(assigns.date)}
        </time>
    ');
}
```

## Best Practices

### 1. Keep Templates Readable

Use proper indentation and spacing:

```haxe
// Good
return HXX('
    <div class="form-group">
        <label for="email">Email</label>
        <input type="email" 
               id="email" 
               name="email" 
               value="${assigns.user.email}">
    </div>
');

// Avoid
return HXX('<div class="form-group"><label for="email">Email</label><input type="email" id="email" name="email" value="${assigns.user.email}"></div>');
```

### 2. Extract Complex Logic

Move complex logic outside of templates:

```haxe
function render(assigns: Dynamic): String {
    // Extract logic first
    var user = assigns.user;
    var isAdmin = user.role == "admin";
    var statusClass = user.active ? "status-active" : "status-inactive";
    
    return HXX('
        <div class="user-dashboard">
            <h1>Welcome, ${user.name}</h1>
            <div class="${statusClass}">
                Status: ${user.active ? "Active" : "Inactive"}
            </div>
            ${isAdmin ? adminPanel() : userPanel()}
        </div>
    ');
}
```

### 3. Use Type-Safe Data Access

Leverage Haxe's type system for safe data access:

```haxe
typedef UserAssigns = {
    user: User,
    todos: Array<Todo>,
    stats: UserStats
}

function render(assigns: UserAssigns): String {
    return HXX('
        <div class="dashboard">
            <h1>${assigns.user.name}</h1>
            <p>Todos: ${assigns.todos.length}</p>
            <p>Completed: ${assigns.stats.completed}</p>
        </div>
    ');
}
```

### 4. Component Organization

Organize templates by feature or component type:

```
src_haxe/
├── templates/
│   ├── UserTemplates.hx    # User-related templates
│   ├── TodoTemplates.hx    # Todo-related templates
│   └── CommonTemplates.hx  # Shared templates
└── live/
    ├── UserLive.hx         # LiveView with render()
    └── TodoLive.hx         # LiveView with render()
```

## Migration from Manual HEEx

### Before: Manual HEEx Templates

```elixir
def render(assigns) do
  ~H"""
  <div class="user-card">
      <h3>{@user.name}</h3>
      <p>{@user.email}</p>
  </div>
  """
end
```

### After: HXX Templates

```haxe
function render(assigns: Dynamic): String {
    return HXX('
        <div class="user-card">
            <h3>${assigns.user.name}</h3>
            <p>${assigns.user.email}</p>
        </div>
    ');
}
```

### Benefits of Migration

1. **Type Safety**: Catch template errors at compile time
2. **Code Sharing**: Reuse template logic across different targets
3. **Better IDE Support**: Syntax highlighting and autocomplete in Haxe
4. **Consistent Syntax**: Same interpolation syntax as the rest of your Haxe code

## Troubleshooting

### Common Issues

#### 1. HTML Attribute Escaping

**Problem**: Attributes are being escaped incorrectly.

**Solution**: This is handled automatically by HXX. If you see escaping issues, ensure you're using the latest version.

#### 2. Interpolation Not Working

**Problem**: `${}` interpolation not converting to `{}`.

**Solution**: Ensure you're using `HXX()` function call and not just string literals.

#### 3. Multiline Template Issues

**Problem**: Complex multiline templates not compiling correctly.

**Solution**: Ensure proper string concatenation and avoid mixing string types.

### Getting Help

- Check the [HXX Implementation Guide](../HXX_IMPLEMENTATION.md) for technical details
- See [Troubleshooting Guide](../TROUBLESHOOTING.md) for general issues
- Review the [examples](../../examples/) for working patterns

## Next Steps

- Try the [Todo App Example](../../examples/todo-app/) to see HXX in action
- Read the [Phoenix Integration Guide](../PHOENIX_INTEGRATION_GUIDE.md) for more LiveView patterns
- Explore [Advanced Patterns](../guides/DEVELOPER_PATTERNS.md) for complex use cases