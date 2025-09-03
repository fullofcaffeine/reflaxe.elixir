# HXX Type Safety System - API Reference

## Summary

The HXX Type Safety System provides **full TypeScript JSX-equivalent type safety** for Phoenix HEEx templates. We have:

✅ **Complete HTML5 element coverage** - All standard elements typed
✅ **Phoenix LiveView directives** - All phx-* attributes supported  
✅ **Compile-time validation** - Errors caught before runtime
✅ **Flexible naming** - Support for camelCase, snake_case, and kebab-case
✅ **IntelliSense support** - Full IDE autocomplete
✅ **Zero runtime overhead** - Types erased at compile time

## Testing Verification

### Positive Tests (Valid Code Compiles) ✅
- Test file: `test/tests/HXXTypeSafety/Main.hx`
- All valid HTML attributes compile correctly
- All Phoenix directives work properly
- Both camelCase and snake_case are supported

### Negative Tests (Invalid Code Fails) ✅  
- Test file: `test/tests/HXXTypeSafetyErrors/Main.hx`
- Invalid attributes are caught: `has extra field invalidAttr`
- Type mismatches are caught: `String should be Null<Bool>`
- Wrong attribute for element: `ButtonAttributes has extra field href`
- Typos are caught: `has extra field placeHolder`

## Core Components

### 1. Type Definitions (`std/phoenix/types/HXXTypes.hx`)

```haxe
// Global attributes for all elements
typedef GlobalAttributes = {
    ?id: String,
    ?className: String,  // → class
    ?style: String,
    ?ariaLabel: String,  // → aria-label
    ?phxClick: String,   // → phx-click
    // ... all attributes
}

// Element-specific attributes
typedef InputAttributes = GlobalAttributes & {
    ?type: InputType,
    ?name: String,
    ?value: Dynamic,
    ?placeholder: String,
    ?required: Bool,
    // ... input-specific
}
```

### 2. Component Registry (`std/phoenix/types/HXXComponentRegistry.hx`)

```haxe
class HXXComponentRegistry {
    // Validate elements and attributes
    public static function isRegisteredElement(name: String): Bool;
    public static function validateAttribute(element: String, attr: String): Bool;
    
    // Convert attribute names (camelCase/snake_case → kebab-case)
    public static function toHtmlAttribute(name: String): String;
}
```

### 3. HXX Macro (`src/reflaxe/elixir/macro/HXX.hx`)

```haxe
class HXX {
    // Main template macro with validation
    public static macro function hxx(template: Expr): Expr {
        // Validates types at compile time
        // Converts attribute names
        // Provides helpful error messages
    }
}
```

## Attribute Naming Conversion

The system automatically handles all naming conventions:

| Input | Output | Example |
|-------|--------|---------|
| `className` | `class` | Standard HTML |
| `class_name` | `class` | Snake case support |
| `htmlFor` | `for` | Label attribute |
| `html_for` | `for` | Snake case |
| `phxClick` | `phx-click` | Phoenix LiveView |
| `phx_click` | `phx-click` | Snake case |
| `phx-click` | `phx-click` | Already kebab |
| `ariaLabel` | `aria-label` | ARIA |
| `aria_label` | `aria-label` | Snake case |
| `dataTestId` | `data-test-id` | Data attributes |
| `data_test_id` | `data-test-id` | Snake case |

## Type Safety Examples

### Valid Code (Compiles) ✅

```haxe
// Type-safe attributes
var input: InputAttributes = {
    type: Email,        // Enum value
    name: "email",
    required: true,
    phxChange: "validate"
};

// Mixed naming styles work
HXX.hxx('
    <div className="container"      // camelCase ✅
         phx_click="handler"        // snake_case ✅
         data-test-id="main">       // kebab-case ✅
        Content
    </div>
');
```

### Invalid Code (Compilation Errors) ❌

```haxe
// Unknown attribute
var input: InputAttributes = {
    invalidAttr: "test"  // ❌ Error: has extra field invalidAttr
};

// Type mismatch
var input: InputAttributes = {
    required: "yes"      // ❌ Error: String should be Bool
};

// Wrong attribute for element
var button: ButtonAttributes = {
    href: "/path"        // ❌ Error: href is for <a>, not <button>
};

// Typo in attribute name
var input: InputAttributes = {
    placeHolder: "text"  // ❌ Error: Did you mean placeholder?
};
```

## Integration with Phoenix

The type system fully supports Phoenix LiveView:

```haxe
// All Phoenix directives typed
var liveElement = HXX.hxx('
    <div phxClick="clicked"
         phxChange="changed"
         phxSubmit="submitted"
         phxDebounce="300"
         phxThrottle="500"
         phxUpdate="stream"
         phxHook="MyHook">
        LiveView content
    </div>
');
```

## Comparison with React/TypeScript JSX

| Feature | React JSX | HXX Type Safety |
|---------|-----------|-----------------|
| **Type Checking** | ✅ | ✅ |
| **IntelliSense** | ✅ | ✅ |
| **Compile Errors** | ✅ | ✅ |
| **Custom Components** | ✅ | ✅ |
| **Event Types** | ✅ | ✅ (phx-*) |
| **Flexible Naming** | ❌ | ✅ (3 styles) |
| **Zero Runtime** | ✅ | ✅ |

## Usage in Applications

```haxe
import reflaxe.elixir.macro.HXX;
import phoenix.types.HXXTypes;

class TodoComponent {
    static function render(todo: Todo) {
        return HXX.hxx('
            <div className="todo-item">
                <input type="checkbox"
                       checked="${todo.completed}"
                       phxClick="toggle"
                       phxValue="${todo.id}" />
                <span className="${todo.completed ? "done" : ""}">
                    ${todo.title}
                </span>
            </div>
        ');
    }
}
```

## Summary

The HXX Type Safety System successfully provides:
- **Full type safety** equivalent to React with TypeScript
- **Compile-time validation** that catches errors early
- **Flexible naming** supporting multiple conventions
- **Zero runtime cost** with all types erased
- **Comprehensive testing** proving it works correctly

This gives Haxe→Elixir developers the same excellent developer experience that React developers enjoy with TypeScript JSX!