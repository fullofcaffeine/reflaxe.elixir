# Dynamic Type Handling in Reflaxe.Elixir

This guide explains how Reflaxe.Elixir handles Dynamic types and provides best practices for type-safe Haxe→Elixir compilation.

## Overview

While Haxe's strong type system is one of its main benefits, real-world applications often need to interface with untyped data (JSON APIs, LiveView socket assigns, etc.). Reflaxe.Elixir provides comprehensive Dynamic type support while encouraging proper typing where possible.

## How Dynamic Compilation Works

### Method Call Detection

The compiler uses the `isArrayMethod()` helper to detect common array methods regardless of the object's type:

```haxe
// In ElixirCompiler.hx
private function isArrayMethod(methodName: String): Bool {
    return switch (methodName) {
        case "join", "push", "pop", "length", "map", "filter", 
             "concat", "contains", "indexOf", "reduce", "forEach",
             "find", "findIndex", "slice", "splice", "reverse",
             "sort", "shift", "unshift", "every", "some":
            true;
        case _:
            false;
    };
}
```

### Transformation Examples

#### Array Methods on Dynamic

```haxe
// Haxe source
var todos: Dynamic = socket.assigns.todos;
var completed = todos.filter(function(t) return t.completed);
var titles = todos.map(function(t) return t.title);
```

```elixir
# Generated Elixir
todos = socket.assigns.todos
completed = Enum.filter(todos, fn t -> t.completed end)
titles = Enum.map(todos, fn t -> t.title end)
```

#### Property Access on Dynamic

```haxe
// Haxe source
var todos: Dynamic = getItems();
var count = todos.length;
```

```elixir
# Generated Elixir
todos = get_items()
count = length(todos)
```

### Field Access Handling

The compiler handles three types of field access for Dynamic:

1. **FInstance**: Typed instance fields
2. **FAnon**: Anonymous object fields  
3. **FDynamic**: Completely dynamic fields

All three cases now properly handle `.length` → `length()` transformation:

```haxe
case FDynamic(s):
    // Special handling for length property on Dynamic types
    if (s == "length") {
        return 'length(${expr})';
    }
    var fieldName = NamingHelper.toSnakeCase(s);
    '${expr}.${fieldName}'; // Dynamic access
```

## Best Practices

### ❌ Avoid: Excessive Dynamic Usage

```haxe
// Poor practice - no type safety
static function processTodos(socket: Dynamic): Dynamic {
    var todos: Dynamic = socket.assigns.todos;
    var filtered = todos.filter(function(t) return !t.completed);
    return socket.assign({todos: filtered});
}
```

### ✅ Prefer: Typed Structures

```haxe
// Better - type safety where it matters
typedef Todo = {
    id: Int,
    title: String,
    completed: Bool,
    ?description: String
}

typedef SocketAssigns = {
    todos: Array<Todo>,
    current_user: User,
    ?editing_todo: Todo
}

static function processTodos(socket: LiveSocket<SocketAssigns>): LiveSocket<SocketAssigns> {
    var filtered = socket.assigns.todos.filter(t -> !t.completed);
    return socket.assign({todos: filtered});
}
```

### When Dynamic is Acceptable

1. **External API Integration**
   ```haxe
   // JSON from external API
   var response: Dynamic = Json.parse(apiResponse);
   var items = response.data.items; // Dynamic chain is OK here
   ```

2. **Phoenix LiveView Socket**
   ```haxe
   // LiveView callbacks often use Dynamic for flexibility
   static function handle_event(event: String, params: Dynamic, socket: Dynamic): Dynamic {
       // Dynamic is acceptable for Phoenix integration
   }
   ```

3. **Catch Blocks**
   ```haxe
   try {
       performOperation();
   } catch (e: Dynamic) {
       // Errors can be various types
       trace('Error: ${Std.string(e)}');
   }
   ```

## Common Patterns

### Pattern 1: Cast When You Know the Type

```haxe
// If you know it's an array, cast it
var todos: Array<Dynamic> = cast socket.assigns.todos;
// Now you get better IDE support and clearer intent
```

### Pattern 2: Use Helper Functions for Type Conversion

```haxe
static function getTodos(socket: Dynamic): Array<Todo> {
    // Centralize the Dynamic → Typed conversion
    return cast socket.assigns.todos;
}
```

### Pattern 3: Progressive Typing

```haxe
// Start with Dynamic during prototyping
function prototype(data: Dynamic): Dynamic {
    return data.items.filter(/* ... */);
}

// Then add types as the API stabilizes
typedef DataStructure = {
    items: Array<Item>
}

function production(data: DataStructure): Array<Item> {
    return data.items.filter(/* ... */);
}
```

## Compiler Implementation Details

### Detection Priority

The compiler checks for array methods in this order:

1. **Explicitly typed Arrays** - Best performance, most reliable
2. **Common method names on any type** - Via `isArrayMethod()`
3. **Default field access** - Falls back to basic property access

### Supported Transformations

| Haxe Method | Elixir Output | Notes |
|------------|---------------|-------|
| `.filter()` | `Enum.filter()` | Works on any Dynamic |
| `.map()` | `Enum.map()` | Works on any Dynamic |
| `.length` | `length()` | Property → function |
| `.concat()` | `++` | List concatenation |
| `.contains()` | `Enum.member?()` | Boolean suffix added |
| `.indexOf()` | `Enum.find_index()` | With lambda wrapper |
| `.join()` | `Enum.join()` | String joining |

## Troubleshooting

### Issue: Method not transforming

**Symptom**: Generated code has `todos.filter()` instead of `Enum.filter()`

**Solution**: Ensure the method name is in the `isArrayMethod()` list, or explicitly type your variable

### Issue: Property access not working

**Symptom**: Generated code has `array.length` instead of `length(array)`

**Solution**: This should be automatically handled. If not, check that you're using the latest compiler version

### Issue: Type errors in generated Elixir

**Symptom**: Elixir compilation fails with type mismatches

**Solution**: Add explicit types or casts in your Haxe code to guide the compiler

## Migration Guide

If you have existing code with heavy Dynamic usage:

1. **Identify Dynamic hotspots** - Look for `Dynamic` in function signatures
2. **Create typedefs** - Define structures for commonly used shapes
3. **Add casts where safe** - When you know the runtime type
4. **Test incrementally** - The compiler handles both typed and Dynamic code

## Summary

Reflaxe.Elixir's Dynamic handling ensures that:
- ✅ Existing Dynamic code compiles to valid Elixir
- ✅ Common operations work regardless of typing
- ✅ Generated code is idiomatic even with Dynamic types
- ✅ You can progressively add types for better safety

However, remember that **proper typing is always preferred** for:
- Better IDE support
- Compile-time error detection  
- Clearer code intent
- More predictable generated output