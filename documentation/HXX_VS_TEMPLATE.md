# HXX vs @:template: Two Complementary Template Approaches

This document explains the architectural distinction between HXX inline templates and @:template file references in Reflaxe.Elixir.

## Overview: Two Different Use Cases

Reflaxe.Elixir provides **two distinct but complementary** approaches for working with Phoenix HEEx templates:

1. **HXX**: Inline JSX-like templates compiled to ~H sigils (primary method)
2. **@:template**: References to external .heex files (escape hatch)

## HXX: Inline Template Compilation (Primary Method)

### What It Is
HXX allows you to write JSX-like template syntax directly in your Haxe code, which gets compiled to idiomatic Phoenix HEEx templates with ~H sigils.

### Usage Pattern
```haxe
import HXX;

@:liveview
class UserLive {
    function render(assigns: Dynamic): String {
        return HXX.hxx('
            <div class="user-profile">
                <h1>${assigns.user.name}</h1>
                <p class="email">${assigns.user.email}</p>
                <.button phx-click="edit">Edit Profile</.button>
            </div>
        ');
    }
}
```

### Compiles To
```elixir
def render(assigns) do
  ~H"""
  <div class="user-profile">
    <h1>{assigns.user.name}</h1>
    <p class="email">{assigns.user.email}</p>
    <.button phx-click="edit">Edit Profile</.button>
  </div>
  """
end
```

### Key Features
- ✅ **Compile-time validation** - Syntax errors caught during Haxe compilation
- ✅ **Type-safe interpolation** - Variables checked against Haxe's type system
- ✅ **JSX-like syntax** - Familiar for developers from React/JS backgrounds
- ✅ **Phoenix integration** - Automatic conversion to HEEx format with proper ~H sigils
- ✅ **LiveView components** - Full support for Phoenix component syntax (<.button>)
- ✅ **No runtime dependencies** - Pure compile-time transformation

### When to Use HXX
- ✅ **Small to medium templates** embedded in LiveView modules
- ✅ **Dynamic templates** with lots of Haxe variable interpolation
- ✅ **Type-safe templates** where compile-time validation is important
- ✅ **React-style development** where template and logic are co-located

## @:template: External File References (Escape Hatch)

### What It Is
The @:template annotation creates references to existing Phoenix .heex template files, allowing integration with manually written HEEx templates.

### Usage Pattern
```haxe
@:template("user_profile.html.heex")
class UserProfileTemplate {
    public static function render(assigns: Dynamic): String {
        // This function will reference the external template file
        return "";  // Placeholder - actual rendering handled by Phoenix
    }
}
```

### Generated Code
```elixir
defmodule UserProfileTemplate do
  use Phoenix.Component
  
  def render(assigns) do
    # References user_profile.html.heex template file
    render("user_profile.html", assigns)
  end
end
```

### Key Features
- ✅ **External file integration** - Works with existing .heex files
- ✅ **Designer-friendly** - Non-programmers can edit .heex files directly
- ✅ **Large template support** - Better for complex, multi-screen templates
- ✅ **Phoenix tooling** - Full Phoenix template tooling and syntax highlighting
- ✅ **Gradual migration** - Integrate existing Phoenix templates into Haxe projects

### When to Use @:template
- ✅ **Large, complex templates** better managed as separate files
- ✅ **Designer collaboration** - when non-programmers need to edit templates
- ✅ **Existing Phoenix projects** - migrate gradually by referencing existing templates
- ✅ **Template reuse** - share templates across multiple Haxe modules

## Architectural Philosophy

### HXX: "Template as Code"
```haxe
// Template logic and presentation co-located
@:liveview
class TodoLive {
    function render(assigns: Dynamic): String {
        return HXX.hxx('
            <div class="todo-list">
                ${assigns.todos.map(todo -> 
                    '<div class="todo ${todo.completed ? "done" : ""}">${todo.title}</div>'
                ).join("")}
            </div>
        ');
    }
}
```

**Philosophy**: Template is part of the component logic. Changes to data structure require changes to both logic and template, so keep them together for easier maintenance.

### @:template: "Separation of Concerns"
```haxe
// Logic in Haxe
@:template("todo_list.html.heex")
class TodoListTemplate {
    public static function renderTodos(assigns: Dynamic): String {
        // Complex business logic here
        var processedTodos = TodoProcessor.process(assigns.todos);
        return renderTemplate(processedTodos);
    }
}
```

```heex
<!-- Presentation in .heex file -->
<div class="todo-list">
  <%= for todo <- @todos do %>
    <div class={"todo #{if todo.completed, do: "done", else: ""}"}>
      <%= todo.title %>
    </div>
  <% end %>
</div>
```

**Philosophy**: Separate business logic (Haxe) from presentation (HEEx). Allows designers to work on templates while developers work on logic.

## Migration Strategies

### Starting New: HXX-First
1. **Begin with HXX** for all templates
2. **Extract to @:template** only when templates become large or need designer collaboration
3. **Keep simple templates** in HXX for maintainability

### Migrating Existing Phoenix: @:template Bridge
1. **Start with @:template** to reference existing .heex files
2. **Gradually convert small templates** to HXX for better type safety
3. **Keep large templates** as @:template for designer workflow

## Technical Implementation Details

### HXX Compilation Process
```
Haxe Source (.hx)
    ↓
HXX.hxx() calls detected
    ↓
HxxCompiler.compileHxxTemplate()
    ↓
AST → TemplateNode tree
    ↓
Phoenix-specific transformations
    ↓
~H sigil generation
    ↓
Elixir Code (.ex)
```

### @:template Compilation Process
```
Haxe Source (.hx)
    ↓
@:template annotation detected
    ↓
TemplateCompiler.compileFullTemplate()
    ↓
External file reference generation
    ↓
Phoenix.Component integration
    ↓
Elixir Code (.ex)
```

## Best Practices

### Use HXX When:
- Template is < 50 lines
- Heavy use of Haxe variables/logic
- Component-style development preferred
- Type safety is critical

### Use @:template When:
- Template is > 100 lines
- Designer collaboration needed
- Existing .heex files to integrate
- Template is mostly static HTML

### Hybrid Approach:
```haxe
@:liveview 
class AppLive {
    // Small dynamic templates: HXX
    function renderUserBadge(user: User): String {
        return HXX.hxx('<span class="badge">${user.name}</span>');
    }
    
    // Large static template: @:template reference
    @:template("app_layout.html.heex")
    function renderLayout(assigns: Dynamic): String;
}
```

## Summary

| Feature | HXX | @:template |
|---------|-----|------------|
| **Type Safety** | ✅ Full compile-time | ⚠️ Runtime only |
| **Syntax** | JSX-like | Native HEEx |
| **File Management** | Inline | External files |
| **Designer Friendly** | ❌ Requires Haxe knowledge | ✅ Pure HEEx |
| **Size Limit** | Best for small templates | Better for large templates |
| **Migration** | New projects | Existing Phoenix projects |
| **Compile Time** | Validates interpolation | Validates file existence |
| **Runtime Deps** | None (pure compilation) | Phoenix template system |

Both approaches are **fully supported** and **production-ready**. Choose based on your team's workflow, project requirements, and template complexity. Many projects benefit from using both approaches strategically.