# HXX Migration Guide

This guide helps you migrate from manual HEEx templates to HXX (Haxe JSX) template processing in Reflaxe.Elixir.

## Migration Overview

### What is HXX?

HXX brings JSX-like syntax to Haxe for creating Phoenix HEEx templates. It provides:
- Type-safe template compilation 
- Familiar JSX-like syntax
- Compile-time validation
- Seamless Phoenix LiveView integration

### Migration Benefits

**Before HXX (Manual HEEx):**
- Templates written directly in Elixir
- No compile-time validation
- Separate concerns between logic and presentation
- Manual string interpolation management

**After HXX (Haxe Templates):**
- Templates co-located with component logic
- Compile-time template validation
- Type-safe data access
- Automatic HEEx format generation
- Consistent syntax with the rest of your Haxe code

## Migration Paths

### Path 1: Incremental Migration (Recommended)

Migrate one component at a time to minimize risk and allow gradual adoption.

### Path 2: Full Migration

Migrate all templates at once for complete consistency.

### Path 3: Hybrid Approach

Keep some templates in HEEx for specific needs while migrating core components to HXX.

## Step-by-Step Migration

### Step 1: Identify Migration Candidates

**Good candidates for migration:**
- LiveView render functions
- Reusable template components
- Complex conditional templates
- Templates with significant logic

**Consider keeping in HEEx:**
- Simple, static templates
- Third-party library templates
- Legacy templates with complex Elixir-specific logic

### Step 2: Backup Existing Templates

```bash
# Create backup of existing templates
cp -r lib/my_app_web/templates lib/my_app_web/templates.backup
cp -r lib/my_app_web/live lib/my_app_web/live.backup
```

### Step 3: Convert Template Syntax

#### Basic Template Migration

**Before (Manual HEEx):**
```elixir
defmodule MyAppWeb.UserLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div class="user-profile">
        <h2>{@user.name}</h2>
        <p class="email">{@user.email}</p>
        <button phx-click="edit">Edit</button>
    </div>
    """
  end
end
```

**After (HXX):**
```haxe
@:liveview
class UserLive {
    function render(assigns: Dynamic): String {
        return HXX('
            <div class="user-profile">
                <h2>${assigns.user.name}</h2>
                <p class="email">${assigns.user.email}</p>
                <button phx-click="edit">Edit</button>
            </div>
        ');
    }
}
```

#### Conditional Rendering Migration

**Before (HEEx):**
```elixir
~H"""
<div class="status">
    <%= if @user.active do %>
        <span class="badge badge-success">Active</span>
    <% else %>
        <span class="badge badge-danger">Inactive</span>
    <% end %>
</div>
"""
```

**After (HXX):**
```haxe
return HXX('
    <div class="status">
        <span class="badge ${assigns.user.active ? "badge-success" : "badge-danger"}">
            ${assigns.user.active ? "Active" : "Inactive"}
        </span>
    </div>
');
```

#### Loop Migration

**Before (HEEx):**
```elixir
~H"""
<ul class="todo-list">
    <%= for todo <- @todos do %>
        <li class="todo-item">
            <span>{todo.title}</span>
        </li>
    <% end %>
</ul>
"""
```

**After (HXX):**
```haxe
function render(assigns: Dynamic): String {
    var todoItems = assigns.todos.map(todo -> 
        HXX('<li class="todo-item"><span>${todo.title}</span></li>')
    ).join("");
    
    return HXX('
        <ul class="todo-list">
            ${todoItems}
        </ul>
    ');
}
```

### Step 4: Migrate Event Handlers

**Before (Elixir):**
```elixir
def handle_event("increment", _params, socket) do
  count = socket.assigns.count + 1
  {:noreply, assign(socket, :count, count)}
end
```

**After (Haxe):**
```haxe
function handleEvent(event: String, params: Dynamic, socket: Socket): SocketResult {
    return switch (event) {
        case "increment":
            var count = socket.assigns.count + 1;
            {:noreply, assign(socket, "count", count)};
        default:
            {:noreply, socket};
    };
}
```

### Step 5: Update Build Configuration

Add HXX compilation to your build process:

**build.hxml:**
```hxml
-cp src_haxe
-lib reflaxe.elixir
-D reflaxe_runtime
-D elixir_output=lib
Main
```

**mix.exs:**
```elixir
def project do
  [
    compilers: [:haxe] ++ Mix.compilers(),
    # ... other config
  ]
end
```

### Step 6: Test Migration

```bash
# Compile Haxe to Elixir
npx haxe build.hxml

# Check generated files
ls lib/generated/

# Run tests
mix test

# Start Phoenix server
mix phx.server
```

## Common Migration Patterns

### Pattern 1: Variable Access

**HEEx → HXX Variable Migration:**
```elixir
# Before: HEEx
{@user.name}           → ${assigns.user.name}
{assigns.count}        → ${assigns.count}
{@posts |> length()}   → ${assigns.posts.length}
```

### Pattern 2: Attribute Binding

**HEEx → HXX Attribute Migration:**
```elixir
# Before: HEEx
class={@css_class}                    → class="${assigns.css_class}"
disabled={@is_disabled}               → ${assigns.is_disabled ? "disabled" : ""}
phx-value-id={@item.id}              → phx-value-id="${assigns.item.id}"
```

### Pattern 3: Conditional Classes

**HEEx → HXX Conditional Classes:**
```elixir
# Before: HEEx
class={"btn #{if @active, do: "btn-primary", else: "btn-secondary"}"}

# After: HXX  
class="btn ${assigns.active ? "btn-primary" : "btn-secondary"}"
```

### Pattern 4: Form Helpers

**HEEx → HXX Form Migration:**
```elixir
# Before: HEEx
<.input type="text" field={@form[:name]} />

# After: HXX (manual form creation)
<input type="text" 
       name="user[name]" 
       value="${assigns.form.data.name}"
       phx-debounce="300">
```

### Pattern 5: Component Composition

**HEEx → HXX Component Migration:**
```elixir
# Before: HEEx with function components
<.header title={@page_title} />
<.card></.card>

# After: HXX with function calls
${header(assigns.page_title)}
${card(assigns.content)}
```

## Advanced Migration Scenarios

### Migrating Complex Components

**Multi-part Component Migration:**

**Before (Elixir):**
```elixir
defmodule UserCardComponent do
  use Phoenix.Component

  def user_card(assigns) do
    ~H"""
    <div class="user-card">
        <.header user={@user} />
        <.body user={@user} />
        <.actions user={@user} />
    </div>
    """
  end

  defp header(assigns) do
    ~H"""
    <div class="card-header">
        <h3>{@user.name}</h3>
        <span class="role">{@user.role}</span>
    </div>
    """
  end
end
```

**After (Haxe):**
```haxe
class UserCardComponent {
    public static function userCard(user: User): String {
        return HXX('
            <div class="user-card">
                ${header(user)}
                ${body(user)}
                ${actions(user)}
            </div>
        ');
    }
    
    static function header(user: User): String {
        return HXX('
            <div class="card-header">
                <h3>${user.name}</h3>
                <span class="role">${user.role}</span>
            </div>
        ');
    }
    
    static function body(user: User): String {
        return HXX('
            <div class="card-body">
                <p>${user.bio}</p>
            </div>
        ');
    }
    
    static function actions(user: User): String {
        return HXX('
            <div class="actions">
                <button phx-click="edit" phx-value-id="${user.id}">Edit</button>
                <button phx-click="delete" phx-value-id="${user.id}">Delete</button>
            </div>
        ');
    }
}
```

### Migrating LiveView with Multiple Templates

**Before (Elixir LiveView):**
```elixir
defmodule TodoLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div class="todo-app">
        <%= case @view do %>
            <% :list -> %>
                <.todo_list todos={@todos} />
            <% :form -> %>
                <.todo_form changeset={@changeset} />
            <% :edit -> %>
                <.todo_edit todo={@current_todo} />
        <% end %>
    </div>
    """
  end
end
```

**After (Haxe LiveView):**
```haxe
@:liveview
class TodoLive {
    function render(assigns: Dynamic): String {
        var content = switch (assigns.view) {
            case "list": todoList(assigns.todos);
            case "form": todoForm(assigns.changeset);
            case "edit": todoEdit(assigns.current_todo);
            default: "";
        };
        
        return HXX('
            <div class="todo-app">
                ${content}
            </div>
        ');
    }
    
    function todoList(todos: Array<Todo>): String {
        var items = todos.map(todo -> HXX('
            <li class="todo-item">
                <span>${todo.title}</span>
                <button phx-click="edit" phx-value-id="${todo.id}">Edit</button>
            </li>
        ')).join("");
        
        return HXX('<ul class="todos">${items}</ul>');
    }
    
    function todoForm(changeset: Dynamic): String {
        return HXX('
            <form phx-submit="save">
                <input type="text" name="todo[title]" placeholder="New todo...">
                <button type="submit">Add</button>
            </form>
        ');
    }
    
    function todoEdit(todo: Todo): String {
        return HXX('
            <form phx-submit="update" phx-value-id="${todo.id}">
                <input type="text" name="todo[title]" value="${todo.title}">
                <button type="submit">Update</button>
                <button phx-click="cancel">Cancel</button>
            </form>
        ');
    }
}
```

## Migration Checklist

### Pre-Migration Checklist

- [ ] Backup existing templates
- [ ] Update build configuration 
- [ ] Install/update Reflaxe.Elixir with HXX support
- [ ] Identify migration candidates
- [ ] Plan migration order (dependencies first)

### During Migration Checklist

- [ ] Convert template syntax (`{@var}` → `${assigns.var}`)
- [ ] Update conditional logic (`<%= if %>` → ternary operators)
- [ ] Migrate loops (comprehensions → map/join)
- [ ] Update event handlers (Elixir → Haxe)
- [ ] Update variable assignments (`@var` → `assigns.var`)
- [ ] Test each component individually

### Post-Migration Checklist

- [ ] All templates compile without errors
- [ ] Generated HEEx syntax is correct
- [ ] LiveView events work properly
- [ ] No runtime errors in browser
- [ ] Performance is acceptable
- [ ] Clean up backup files

## Rollback Strategy

If migration issues occur:

### Quick Rollback
```bash
# Restore backups
rm -rf lib/my_app_web/live
cp -r lib/my_app_web/live.backup lib/my_app_web/live

# Remove generated files
rm -rf lib/generated/
```

### Partial Rollback
```bash
# Keep working HXX components, restore problematic ones
cp lib/my_app_web/live.backup/problematic_live.ex lib/my_app_web/live/
```

### Gradual Rollback
```bash
# Temporarily disable HXX compilation
# Comment out in build.hxml:
# MyProblematicLive
```

## Troubleshooting Migration

### Common Migration Issues

**1. Template Interpolation Not Working**
```haxe
// Wrong: Regular string
return '<div>${user.name}</div>';

// Correct: HXX function call  
return HXX('<div>${user.name}</div>');
```

**2. Variable Access Errors**
```haxe
// Wrong: Direct access
return HXX('<div>${user.name}</div>');

// Correct: Through assigns
return HXX('<div>${assigns.user.name}</div>');
```

**3. Event Handler Mismatches**
```haxe
// Ensure event names match exactly
// Template: phx-click="save"
// Handler: case "save": ...
```

**4. Type Safety Issues**
```haxe
// Add type safety gradually
function render(assigns: UserAssigns): String {
    // Now you get compile-time validation
}

typedef UserAssigns = {
    user: User,
    todos: Array<Todo>
}
```

## Performance Considerations

### Template Compilation Performance

**HXX compilation is very fast**, but for large applications:

1. **Break large templates into components**
2. **Use static template caching where possible**
3. **Minimize dynamic content in inner loops**

### Runtime Performance

HXX templates generate standard HEEx, so runtime performance is identical to hand-written templates.

### Memory Usage

HXX may use slightly more memory during compilation due to AST processing, but this is negligible for normal projects.

## Migration Timeline Examples

### Small Project (5-10 components)
- **Planning**: 1 hour
- **Migration**: 4-6 hours  
- **Testing**: 2-3 hours
- **Total**: 1 day

### Medium Project (20-50 components)
- **Planning**: 2-3 hours
- **Migration**: 1-2 days
- **Testing**: 0.5-1 day
- **Total**: 2-3 days

### Large Project (100+ components)
- **Planning**: 0.5-1 day
- **Migration**: 3-5 days (incremental)
- **Testing**: 1-2 days
- **Total**: 1-2 weeks

## Best Practices

### 1. Start Small
Begin with simple, isolated components before tackling complex ones.

### 2. Test Incrementally
Test each migrated component before moving to the next.

### 3. Maintain Type Safety
Use typed assigns where possible for better IDE support and validation.

### 4. Document Patterns
Create internal documentation for your team's specific migration patterns.

### 5. Keep Templates Readable
Don't sacrifice readability for brevity - HXX should make templates more maintainable.

## Getting Help

If you encounter issues during migration:

1. **Check the [HXX Guide](HXX_GUIDE.md)** for syntax examples
2. **Review [Troubleshooting](../TROUBLESHOOTING.md)** for common issues
3. **Examine working examples** in `examples/` directory
4. **Ask for help** by creating a GitHub issue with your specific migration challenge

## Conclusion

HXX migration provides significant benefits in type safety, maintainability, and developer experience. While the initial migration requires some effort, the long-term benefits make it worthwhile for most Phoenix projects using Reflaxe.Elixir.

The key to successful migration is planning, testing incrementally, and having a clear rollback strategy. Start with simple components and gradually work toward more complex ones as you become comfortable with the HXX syntax and patterns.