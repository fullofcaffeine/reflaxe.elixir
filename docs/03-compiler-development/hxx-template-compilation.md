# HXX Deep Dive: From JSX to HEEx Template Compilation

## Table of Contents
1. [Overview](#overview)
2. [Architecture Layers](#architecture-layers)
3. [Compilation Pipeline](#compilation-pipeline)
4. [Parsing Phase](#parsing-phase)
5. [AST Transformation](#ast-transformation)
6. [HEEx Generation](#heex-generation)
7. [Integration Points](#integration-points)
8. [Examples and Patterns](#examples-and-patterns)
9. [Debugging HXX Compilation](#debugging-hxx-compilation)

## Overview

HXX (Haxe XML eXpressions) is a sophisticated template compilation system that transforms JSX-like syntax written in Haxe into Phoenix HEEx (HTML+EEx) templates. It provides type-safe, compile-time template generation for Phoenix LiveView applications.

### Key Features
- **JSX-like syntax** in Haxe source files
- **Compile-time transformation** to HEEx templates
- **Type safety** for template variables and components
- **Phoenix Component** integration
- **Automatic sigil wrapping** (~H for HEEx)

## Architecture Layers

```
┌─────────────────────────────────┐
│      Haxe Source (.hx)          │  HXX.hxx('<div>{@user}</div>')
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│      HXX Macro (HXXMacro.hx)    │  Macro-time parsing
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│    HXX Parser (HXXParser.hx)    │  JSX → AST conversion
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│   HXX Compiler (HxxCompiler.hx) │  AST reconstruction
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│    Elixir Compiler Output       │  ~H sigil generation
└─────────────────────────────────┘
             │
┌────────────▼────────────────────┐
│      Generated .ex file         │  Phoenix HEEx template
└─────────────────────────────────┘
```

## Compilation Pipeline

### Stage 1: Macro Invocation
When you write `HXX.hxx('<div>...</div>')` in Haxe, it triggers the macro system at compile time.

**File: `src/reflaxe/elixir/HXX.hx`**
```haxe
public static macro function hxx(templateStr: Expr): Expr {
    return switch (templateStr.expr) {
        case EConst(CString(s, _)):
            var processed = HXXParser.process(s);
            macro $v{processed};
        case _:
            Context.error("hxx() expects a string literal", templateStr.pos);
    }
}
```

### Stage 2: Template Parsing
The HXXParser processes the JSX string and identifies Phoenix-specific patterns.

**File: `src/reflaxe/elixir/macro/HXXParser.hx`**
```haxe
public static function process(jsxString: String): String {
    // 1. Parse JSX syntax
    // 2. Identify interpolation patterns
    // 3. Convert to intermediate format
    // 4. Apply Phoenix transformations
    return processedTemplate;
}
```

### Stage 3: AST Processing
After Haxe's type checking, the Reflaxe compiler receives the typed AST.

**File: `src/reflaxe/elixir/helpers/HxxCompiler.hx`**
```haxe
public function compileHxxTemplate(expr: TypedExpr): String {
    // Walk the AST to reconstruct the template
    var template = walkAST(expr, new CompilationContext());
    
    // Wrap in ~H sigil for Phoenix
    return '~H"""\n${template}\n"""';
}
```

### Stage 4: HEEx Generation
The final stage produces Phoenix-compatible HEEx template syntax.

## Parsing Phase

### JSX Syntax Recognition

HXX recognizes several JSX patterns and transforms them:

#### 1. **Attribute Interpolation**
```haxe
// Haxe input
HXX.hxx('<div class={@className} id={userId}>')

// Parsed intermediate
{type: "element", tag: "div", attrs: [
    {name: "class", value: {type: "assign", name: "className"}},
    {name: "id", value: {type: "variable", name: "userId"}}
]}

// Final HEEx output
<div class={@class_name} id={user_id}>
```

#### 2. **Content Interpolation**
```haxe
// Haxe input
HXX.hxx('<h1>${title}</h1>')

// Parsed intermediate
{type: "element", tag: "h1", children: [
    {type: "interpolation", expr: "title"}
]}

// Final HEEx output
<h1><%= title %></h1>
```

#### 3. **Phoenix Components**
```haxe
// Haxe input
HXX.hxx('<.button type="submit">Save</.button>')

// Recognized as Phoenix component (starts with .)
// Output unchanged
<.button type="submit">Save</.button>
```

## AST Transformation

### Walking the TypedExpr Tree

The HxxCompiler traverses the Haxe AST to reconstruct templates:

```haxe
private function walkAST(expr: TypedExpr, context: Context): String {
    switch (expr.expr) {
        case TConst(TString(s)):
            // String literal - the template content
            return processTemplateString(s);
            
        case TCall(e, args):
            // Check for HXX.hxx() call
            if (isHxxCall(e)) {
                return walkAST(args[0], context);
            }
            
        case TBlock(exprs):
            // Multiple expressions in template
            return exprs.map(e -> walkAST(e, context)).join("");
            
        case TBinop(OpAdd, e1, e2):
            // String concatenation in template
            return walkAST(e1, context) + walkAST(e2, context);
    }
}
```

### Variable Name Transformation

Variables undergo snake_case conversion:

```haxe
private function transformVariableName(name: String): String {
    // userName -> user_name
    // isActive -> is_active
    return NamingHelper.toSnakeCase(name);
}
```

### Phoenix Assigns Handling

Assigns (`@variable`) are special in Phoenix and preserve their @ prefix:

```haxe
private function processAssign(varName: String): String {
    // @userName -> @user_name
    if (varName.startsWith("@")) {
        return "@" + transformVariableName(varName.substring(1));
    }
    return transformVariableName(varName);
}
```

## HEEx Generation

### Template Wrapping

Templates are wrapped in the ~H sigil for Phoenix:

```haxe
public function generateHEEx(template: String): String {
    // Multi-line templates use triple quotes
    if (template.contains("\n")) {
        return '~H"""\n${template}\n"""';
    }
    // Single-line can use regular quotes
    return '~H"${template}"';
}
```

### Component Detection

Phoenix components (starting with `.`) receive special handling:

```haxe
private function isPhoenixComponent(tagName: String): Bool {
    return tagName.startsWith(".");
}

private function processComponent(tag: String, attrs: Map<String,String>): String {
    // <.modal id="confirm"> becomes <.modal id="confirm">
    // Components pass through unchanged
    return '<${tag}${formatAttributes(attrs)}>';
}
```

### Conditional Rendering

Conditional attributes and content:

```haxe
// Input
HXX.hxx('<div class={if @active, do: "active", else: "inactive"}>')

// Output
<div class={if @active, do: "active", else: "inactive"}>
```

## Integration Points

### 1. **LiveView Functions**

Functions using HXX templates are detected for special handling:

```haxe
// In FunctionCompiler.hx
private function containsHxxCall(expr: TypedExpr): Bool {
    // Recursively check for HXX.hxx() calls
    // This affects parameter naming (assigns without underscore)
}
```

---

## Macro Path (current)

HXX now compiles via a macro by default and feeds the builder with `@:heex`‑tagged strings (emitted as `ESigil("H", ...)`). The former transitional stub `std/HXX.cross.hx` has been removed.

- Authoring:
  - `HXX.hxx("...")` expands at compile time, validates, and returns a tagged literal.
- AST pipeline:
  - `ElixirASTBuilder` attaches typed HEEx AST; downstream transforms operate on `ESigil("H", ...)`.
  - `HeexControlTagTransforms` remains as a safety net but is idempotent for macro‑produced content.
  - `TemplateHelpers` continues to support interpolation mapping when needed.

Implications:

- Expressions inside templates are validated earlier; prefer attribute expressions and structured fragments for best typing.
- Target‑conditional classpath gating remains in place so macro code does not leak Elixir internals into other targets.

### 2. **Phoenix.Component Import**

Classes using HXX automatically get Phoenix.Component:

```haxe
// In ClassCompiler.hx
if (usesHxxTemplates(classType, funcFields)) {
    result.add('  use Phoenix.Component\n\n');
}
```

### 3. **Method Call Detection**

The compiler detects HXX.hxx() calls:

```haxe
// In MethodCallCompiler.hx
if (objStr == "HXX" && methodName == "hxx") {
    return compiler.compileHxxCall(args);
}
```

## Examples and Patterns

### Complete LiveView Component Example

**Haxe Source:**
```haxe
@:liveview
class UserLive {
    public function render(assigns: Dynamic): String {
        return HXX.hxx('
            <div class="user-list">
                <h1><%= @title %></h1>
                <%= for user <- @users do %>
                    <div class="user-card">
                        <span class={@user.active ? "active" : "inactive"}>
                            <%= user.name %>
                        </span>
                        <.button phx-click="edit_user" phx-value-id={user.id}>
                            Edit
                        </.button>
                    </div>
                <% end %>
            </div>
        ');
    }
}
```

**Compilation Steps:**

1. **Macro Processing**: HXX.hxx() macro extracts the template string
2. **Parser Analysis**: Identifies assigns (@title, @users), loops, components
3. **AST Walking**: Compiler traverses the TypedExpr tree
4. **Name Transformation**: Variables converted to snake_case
5. **HEEx Generation**: Wrapped in ~H sigil

**Generated Elixir:**
```elixir
defmodule TodoAppWeb.UserLive do
  use TodoAppWeb, :live_view
  
  def render(assigns) do  # Note: no underscore prefix
    ~H"""
    <div class="user-list">
      <h1><%= @title %></h1>
      <%= for user <- @users do %>
        <div class="user-card">
          <span class={if user.active, do: "active", else: "inactive"}>
            <%= user.name %>
          </span>
          <.button phx-click="edit_user" phx-value-id={user.id}>
            Edit
          </.button>
        </div>
      <% end %>
    </div>
    """
  end
end
```

### Pattern: Form Handling

**Haxe:**
```haxe
HXX.hxx('
    <.form for={@changeset} phx-submit="save">
        <.input field={@changeset[:name]} label="Name" />
        <.input field={@changeset[:email]} type="email" label="Email" />
        <.button type="submit">Save</.button>
    </.form>
')
```

**Generated:**
```elixir
~H"""
<.form for={@changeset} phx-submit="save">
  <.input field={@changeset[:name]} label="Name" />
  <.input field={@changeset[:email]} type="email" label="Email" />
  <.button type="submit">Save</.button>
</.form>
"""
```

## Debugging HXX Compilation

### Enable Debug Flags

```bash
# Enable HXX debugging
npx haxe build-server.hxml -D debug_hxx

# Enable all template debugging
npx haxe build-server.hxml -D debug_hxx -D debug_template
```

### Common Issues and Solutions

#### Issue 1: Underscore Prefix on assigns
**Problem**: Function parameters get underscore prefix when unused
**Solution**: HxxCompiler detects HXX usage and preserves "assigns" parameter name

#### Issue 2: String Interpolation Errors
**Problem**: `${@field}` causes Haxe compilation errors
**Solution**: Use `{@field}` for attributes, `<%= @field %>` for content

#### Issue 3: Component Not Recognized
**Problem**: Phoenix components not working
**Solution**: Ensure component starts with `.` (dot)

### AST Inspection

To debug AST processing:

```haxe
#if debug_hxx
trace("[HXX] Processing expression: " + expr.expr);
trace("[HXX] Template fragment: " + result);
#end
```

## Performance Considerations

### Compile-Time Processing
- All template parsing happens at compile time
- No runtime template compilation overhead
- Templates are static strings in generated Elixir

### Optimization Opportunities
1. **Template Caching**: Processed templates could be cached
2. **Incremental Compilation**: Only reprocess changed templates
3. **AST Simplification**: Optimize AST before walking

## Future Enhancements

### Planned Features
1. **Template Validation**: Compile-time HTML validation
2. **Component Type Safety**: Typed component props
3. **Slot Support**: Full Phoenix slot functionality
4. **Error Boundaries**: Better error reporting for malformed templates

### Integration Improvements
1. **Source Maps**: Map HEEx errors back to HXX source
2. **IDE Support**: Syntax highlighting and autocomplete
3. **Template Fragments**: Support for template partials
4. **Live Reload**: Hot template reloading during development

## Related Documentation

- [Phoenix HEEx Documentation](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- [HXX vs Template Comparison](/documentation/HXX_VS_TEMPLATE.md)
- [LiveView Compiler Documentation](/docs/03-compiler-development/liveview-compilation.md)
- [Template Compilation Patterns](/docs/07-patterns/template-patterns.md)

## Summary

HXX provides a sophisticated bridge between Haxe's type-safe world and Phoenix's powerful template system. Through careful AST processing and Phoenix-aware transformations, it enables developers to write type-safe templates that compile to idiomatic HEEx code. The system handles everything from variable name transformation to component detection, ensuring seamless integration with the Phoenix ecosystem while maintaining the benefits of compile-time checking.
