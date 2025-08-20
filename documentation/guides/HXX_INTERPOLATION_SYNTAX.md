# HXX Interpolation Syntax Guide

## Overview

HXX templates in Reflaxe.Elixir must compile to valid Phoenix HEEx syntax, which has **different interpolation rules** depending on context. Understanding these distinctions is critical for proper template compilation.

## ⚠️ CRITICAL WARNING: Avoid `${@field}` Pattern

**The `${@field}` pattern WILL CAUSE COMPILATION ERRORS** and must never be used.

### Why `${@field}` Fails

❌ **THIS PATTERN BREAKS** (causes Haxe compilation errors):
```haxe
return HXX.hxx('<div id="${@id}" class="${@className}">
    ${@inner_content}
</div>');
```

**Root Cause**: 
1. Haxe's string interpolation is triggered by `${}` in single-quoted strings
2. Haxe tries to evaluate `@field` as a variable expression  
3. `@` is not a valid identifier character in Haxe
4. Compilation fails with "Expected expression" or "Unknown identifier" errors

### Haxe String Interpolation Rules
- **Single quotes** (`'string'`) enable string interpolation with `${}`
- **Double quotes** (`"string"`) do NOT enable string interpolation  
- **Interpolation requires valid Haxe identifiers** - `@field` is invalid
- **Phoenix assigns syntax** (`@field`) conflicts with Haxe parsing

### The Correct Solution

✅ **USE THIS INSTEAD** (works correctly):
```haxe
return HXX.hxx('<div id={@id} class={@className}>
    <%= @inner_content %>
</div>');
```

**Key Changes**:
- **Attributes**: `{@field}` (no dollar sign)
- **Text content**: `<%= @field %>` (Phoenix syntax directly)
- **No Haxe interpolation conflict**: HxxCompiler handles Phoenix transformation

## The Two Interpolation Syntaxes

### 1. Text Content Interpolation: `${expression}`

**Haxe HXX Source:**
```haxe
return HXX.hxx('
    <div>
        Welcome, ${user.name}!
        Current time: ${formatTime(now)}
    </div>
');
```

**Generated HEEx Output:**
```elixir
~H"""
<div>
    Welcome, <%= user.name %>!
    Current time: <%= format_time(now) %>
</div>
"""
```

**Rule**: Text content between HTML tags uses `${}` in Haxe → `<%= %>` in HEEx

### 2. Attribute Value Interpolation: `{expression}`

**Haxe HXX Source:**
```haxe
return HXX.hxx('
    <meta name="csrf-token" content={Component.get_csrf_token()}/>
    <div class={getStyleClass(user.role)}>
        <img src={user.avatar} alt={user.name}/>
    </div>
');
```

**Generated HEEx Output:**
```elixir
~H"""
<meta name="csrf-token" content={Component.get_csrf_token()}/>
<div class={get_style_class(user.role)}>
    <img src={user.avatar} alt={user.name}/>
</div>
"""
```

**Rule**: Attribute values use `{}` in Haxe → `{}` in HEEx (no `<%= %>` wrapper)

## Why This Distinction Matters

### Phoenix HEEx Parser Requirements

Phoenix's HEEx template parser has strict rules:

1. **Text interpolation** requires `<%= expression %>` syntax
2. **Attribute interpolation** requires `{expression}` syntax
3. **Mixing them causes compilation errors**

### Example of Incorrect Usage

❌ **This causes compilation errors:**
```elixir
<!-- WRONG: <%= %> in attribute -->
<meta name="csrf-token" content="<%= get_csrf_token() %>"/>
```

✅ **This is correct:**
```elixir
<!-- CORRECT: {} in attribute -->
<meta name="csrf-token" content={get_csrf_token()}/>
```

## HxxCompiler Implementation

### Context Detection

The HxxCompiler needs to distinguish between these contexts:

```haxe
// In generateTemplateContent() - for text content
case VariableNode(name):
    return '<%= ${name} %>';  // Text interpolation

// In generateElixirExpression() - for attributes  
case VariableNode(name):
    return name;  // Direct expression (no wrapper)
```

### Current Implementation Pattern

Our HxxCompiler uses this pattern:

1. **`generateTemplateContent()`**: Generates full template content with `<%= %>` wrappers
2. **`generateElixirExpression()`**: Generates bare expressions for use in attributes
3. **Context awareness**: Different syntax based on where the expression appears

## Development Guidelines

### For Haxe Developers

When writing HXX templates:

```haxe
// ✅ CORRECT: Text content uses ${}
return HXX.hxx('
    <h1>Hello ${userName}!</h1>
    <p>You have ${messageCount} messages</p>
');

// ✅ CORRECT: Attributes use {}
return HXX.hxx('
    <div class={userClass} id={userId}>
        <img src={avatarUrl} alt={userName}/>
    </div>
');

// ❌ WRONG: Don't mix syntaxes
return HXX.hxx('
    <div class="${userClass}">  <!-- Wrong: ${} in attribute -->
        <img src={avatarUrl} alt="${userName}"/>  <!-- Mixed syntax -->
    </div>
');
```

### For Compiler Developers

When enhancing HxxCompiler:

1. **Always consider context** - text vs attribute
2. **Use appropriate generation method** - `generateTemplateContent()` vs `generateElixirExpression()`
3. **Test both contexts** - ensure expressions work in text and attributes
4. **Validate HEEx output** - Phoenix compilation must succeed

## Advanced Cases

### Function Calls in Attributes

**Haxe:**
```haxe
<button onclick={handleClick(user.id)} disabled={isDisabled(user.status)}>
    Click me
</button>
```

**Generated HEEx:**
```elixir
<button onclick={handle_click(user.id)} disabled={is_disabled(user.status)}>
    Click me
</button>
```

### Nested Function Calls

**Haxe:**
```haxe
<div title={formatTooltip(getUserName(user.id))}>
    Content
</div>
```

**Generated HEEx:**
```elixir
<div title={format_tooltip(get_user_name(user.id))}>
    Content
</div>
```

**Note**: No nested `<%= %>` syntax - clean function composition.

## Common Pitfalls

### 1. CSRF Token Issue (Fixed)

**Before (Broken):**
```haxe
// This generated invalid HEEx
<meta name="csrf-token" content="${Component.get_csrf_token()}"/>
```

**After (Working):**
```haxe
// This generates valid HEEx
<meta name="csrf-token" content={Component.get_csrf_token()}/>
```

### 2. Nested Interpolation (Fixed)

**Before (Broken):**
```elixir
<!-- Invalid: nested interpolation -->
<%= get_initials(<%= get_user_name(user) %>) %>
```

**After (Working):**
```elixir
<!-- Valid: clean function composition -->
<%= get_initials(get_user_name(user)) %>
```

## Testing Strategy

### Template Compilation Tests

Create tests that verify both syntaxes work correctly:

```haxe
class HxxInterpolationTest {
    @test
    function testTextInterpolation() {
        var template = HXX.hxx('<div>${message}</div>');
        Assert.equals('<div><%= message %></div>', template);
    }
    
    @test  
    function testAttributeInterpolation() {
        var template = HXX.hxx('<div class={styleClass}></div>');
        Assert.equals('<div class={style_class}></div>', template);
    }
}
```

### Phoenix Integration Tests

Ensure generated templates compile and run:

```bash
# Test that Phoenix can compile generated templates
mix compile
mix phx.server  # Should start without template errors
```

## Migration Guide

### Updating Existing Templates

If you have existing templates with incorrect syntax:

**Find and replace patterns:**
```bash
# Replace ${} in attributes with {}
# Manual review required - check each case
grep -r 'content="\${' src_haxe/
grep -r 'class="\${' src_haxe/
grep -r 'src="\${' src_haxe/
```

**Common replacements:**
```haxe
// OLD: String interpolation in attributes
<div class="user-${userRole}">

// NEW: Direct expression in attributes  
<div class={"user-" <> userRole}>
```

## Future Enhancements

### Automatic Context Detection

Future versions could automatically detect context:

```haxe
// Compiler could auto-detect attribute vs text context
return HXX.hxx('
    <div class="user-${user.role}">  <!-- Auto: attribute context -->
        Welcome ${user.name}!        <!-- Auto: text context -->
    </div>
');
```

**Implementation approach:**
1. Parse HTML structure during AST analysis
2. Track whether expressions are inside attribute values
3. Apply appropriate interpolation syntax automatically

### Smart Quote Handling

Enhanced parsing for mixed quote scenarios:

```haxe
// Handle complex attribute values
<div class="primary ${user.active ? 'active' : 'inactive'} user">
    Content
</div>
```

**Challenges:**
- Quote parsing within string interpolation
- Nested expression detection
- Maintaining backwards compatibility

## Related Documentation

- [`documentation/guides/HXX_GUIDE.md`](HXX_GUIDE.md) - General HXX usage patterns
- [`documentation/HXX_ARCHITECTURE.md`](../HXX_ARCHITECTURE.md) - Technical implementation details
- [`src/reflaxe/elixir/helpers/HxxCompiler.hx`](../../src/reflaxe/elixir/helpers/HxxCompiler.hx) - Implementation source
- [Phoenix HEEx Documentation](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2) - Official HEEx syntax reference

## Summary

The `${}` vs `{}` distinction is fundamental to Phoenix HEEx compatibility:

- **`${expression}` for text content** → compiles to `<%= expression %>`
- **`{expression}` for attributes** → compiles to `{expression}`
- **Context matters** - same expression, different syntax based on location
- **HxxCompiler handles this** via `generateTemplateContent()` vs `generateElixirExpression()`

This ensures Haxe HXX templates compile to valid, idiomatic Phoenix HEEx code.