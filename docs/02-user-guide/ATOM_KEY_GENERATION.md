# Atom Key Generation in Reflaxe.Elixir

This document explains when and how Reflaxe.Elixir generates atom keys vs string keys for anonymous objects.

## Overview

In Elixir, map keys can be either atoms (`:key`) or strings (`"key"`). This choice has important implications:

- **Atom keys** (`:key => value`) are used for known, finite sets like configuration and OTP patterns
- **String keys** (`"key" => value`) are used for user data and dynamic keys

## Current Implementation (Conservative Approach)

Reflaxe.Elixir takes a **conservative string-first approach** to avoid breaking existing code.

### When Atom Keys Are Generated

Atom keys are only generated when we have **strong evidence** of OTP supervisor patterns:

```haxe
// This generates atom keys because it has all 3 supervisor option fields
var supervisorOpts = {
    strategy: "one_for_one",
    max_restarts: 5, 
    max_seconds: 10
};
// Compiles to: %{:strategy => "one_for_one", :max_restarts => 5, :max_seconds => 10}
```

### When String Keys Are Generated (Default)

All other cases use string keys:

```haxe
// Child specs use string keys (safer default)
var childSpec = {
    id: "worker1",
    start: {module: "Worker", function: "start_link", args: []}
};
// Compiles to: %{"id" => "worker1", "start" => %{"module" => "Worker", "function" => "start_link", "args" => []}}

// User data uses string keys
var user = {
    name: "John",
    email: "john@example.com"
};
// Compiles to: %{"name" => "John", "email" => "john@example.com"}

// Log metadata uses string keys
Log.trace("message", {fileName: "test.hx", lineNumber: 42});
// Compiles to: Log.trace("message", %{"fileName" => "test.hx", "lineNumber" => 42})
```

## Detection Algorithm

The `shouldUseAtomKeys()` function implements this conservative detection:

```haxe
private function shouldUseAtomKeys(fields: Array<{name: String, expr: TypedExpr}>): Bool {
    // Only use atom keys for exact supervisor option pattern
    var supervisorFields = ["strategy", "max_restarts", "max_seconds"];
    var hasAllSupervisorFields = true;
    for (field in supervisorFields) {
        if (fieldNames.indexOf(field) == -1) {
            hasAllSupervisorFields = false;
            break;
        }
    }
    
    // Must have exactly 3 fields, all valid atom names
    if (hasAllSupervisorFields && fieldNames.length == 3) {
        // Verify all field names can be atoms
        for (field in fields) {
            if (!isValidAtomName(field.name)) {
                return false;
            }
        }
        return true;
    }
    
    // Default to string keys for all other cases
    return false;
}
```

## Lessons Learned

### ❌ What Didn't Work: Over-Aggressive Detection

Initial attempts tried to detect OTP patterns by checking for individual field names like `"id"`, `"start"`, `"type"`. This caused problems:

```haxe
// This broke because "status" was detected as an OTP field
var result = {status: "ok", user: userData};
// Incorrectly generated: %{status => "ok", user => userData}  // status as variable!
// Should generate: %{"status" => "ok", "user" => userData}   // status as string
```

**Why this failed:**
- Field names like `"status"`, `"id"`, `"type"` appear in many non-OTP contexts
- Maintaining lists of "OTP fields" vs "non-OTP fields" is ad-hoc and unmaintainable
- The approach required constant updates as new patterns emerged

### ✅ What Works: Conservative String-First Approach

The current approach only uses atom keys for the most obvious cases:

1. **Very specific patterns** - Exact match for supervisor options
2. **Complete pattern match** - All required fields must be present
3. **No partial matches** - Don't guess based on individual field names
4. **String as default** - Safe fallback that always works in Elixir

## Technical Implementation

### Key Quoting

The key fix was properly quoting string keys:

```haxe
// Before (BROKEN)
f.name;  // Generated: id => value (id treated as variable)

// After (FIXED) 
'"' + f.name + '"';  // Generated: "id" => value (id as string literal)
```

### Atom Validation

Atom keys are only generated for valid Elixir atom names:

```haxe
private function isValidAtomName(name: String): Bool {
    if (name == null || name.length == 0) return false;
    var firstChar = name.charAt(0);
    if (!((firstChar >= 'a' && firstChar <= 'z') || firstChar == '_')) {
        return false;
    }
    for (i in 1...name.length) {
        var char = name.charAt(i);
        if (!((char >= 'a' && char <= 'z') || 
              (char >= 'A' && char <= 'Z') || 
              (char >= '0' && char <= '9') || 
              char == '_')) {
            return false;
        }
    }
    return true;
}
```

## Future Considerations

### Explicit Annotations (Not Implemented)

A future enhancement could allow explicit control:

```haxe
// Hypothetical annotation syntax
@:atomKeys
var childSpec = {
    id: "worker1",
    start: {module: "Worker", function: "start_link"}
};
```

### Context-Aware Detection (Not Implemented)

Another approach could detect usage context:

```haxe
// If passed directly to Supervisor.start_link, use atoms
Supervisor.start_link(children, {strategy: "one_for_one"});  // Could detect this
```

## Best Practices

### For Users

1. **Trust the defaults** - String keys work in all Elixir contexts
2. **Don't try to force atom keys** - The compiler chooses the safest option
3. **Use Elixir wrappers if needed** - For custom OTP patterns requiring atoms

### For Compiler Development

1. **Prefer predictable over clever** - Conservative defaults are better than fragile heuristics
2. **Default to safe options** - String keys always work, atom keys are optimization
3. **Avoid maintenance-heavy approaches** - Don't maintain lists of special cases
4. **Test with real applications** - The todo-app revealed edge cases that unit tests missed

## Related Documentation

- [Elixir Map Documentation](https://hexdocs.pm/elixir/Map.html)
- [OTP Supervisor Documentation](https://hexdocs.pm/elixir/Supervisor.html)
- [Compiler Development Best Practices](../AGENTS.md#compiler-development-best-practices)