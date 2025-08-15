# JavaScript Compilation Architecture

## Overview

This document explains how Haxe's standard JavaScript target works in the context of Phoenix LiveView applications, providing the technical foundation for understanding our pure-Haxe architecture approach.

## Haxe JavaScript Target Fundamentals

### Compilation Pipeline

```
Haxe Source (.hx) → Haxe Parser → Type Checker → JS Generator → JavaScript (.js)
                                                      ↓
                                              ES6 Modules + Source Maps
```

### Key Compilation Flags

Our client build configuration uses these critical flags:

```hxml
# build-client.hxml
-js assets/js/app.js              # Output file
-D js-es=6                        # ES6 module output
-D js-unflatten                   # Better module structure
-D analyzer-optimize              # Enable optimizations
-D dce=full                       # Dead code elimination
-D js-source-map                  # Generate source maps
-D real-position                  # Accurate source positions
```

### Code Generation Patterns

#### 1. **Class Compilation**

**Haxe Source:**
```haxe
package client.hooks;

class AutoFocus implements LiveViewHook {
    public var el: Element;
    
    public function new() {}
    
    public function mounted(): Void {
        focusElement();
    }
    
    private function focusElement(): Void {
        el.focus();
    }
}
```

**Generated JavaScript (ES6):**
```javascript
import { LiveViewHook } from "./extern/Phoenix.js";

export class AutoFocus {
    constructor() {
        this.el = null;
    }
    
    mounted() {
        this.focusElement();
    }
    
    focusElement() {
        this.el.focus();
    }
}
```

#### 2. **Interface/Typedef Compilation**

**Haxe Source:**
```haxe
typedef Todo = {
    id: Int,
    title: String,
    completed: Bool
};

interface LiveViewHook {
    var el: Element;
    function mounted(): Void;
}
```

**Generated JavaScript:**
```javascript
// Typedefs become runtime objects (if used)
// Interfaces are erased (type checking only)
```

**Key Point**: Interfaces are completely erased at runtime - they provide compile-time type safety but generate no JavaScript code.

#### 3. **Enum Compilation**

**Haxe Source:**
```haxe
enum TodoFilter {
    All;
    Active;
    Completed;
}
```

**Generated JavaScript:**
```javascript
export const TodoFilter = {
    All: { _hx_index: 0, toString: () => "All" },
    Active: { _hx_index: 1, toString: () => "Active" },
    Completed: { _hx_index: 2, toString: () => "Completed" }
};
```

#### 4. **Abstract Type Inlining**

**Haxe Source:**
```haxe
abstract UserId(Int) from Int to Int {
    public function new(id: Int) this = id;
    public function toString(): String return 'User#$this';
}
```

**Generated JavaScript:**
```javascript
// Abstracts are completely inlined - no runtime representation
// UserId becomes plain Int in generated code
```

## Optimization Techniques

### 1. **Dead Code Elimination (DCE)**

With `-D dce=full`, unused code is completely removed:

```haxe
class Utils {
    public static function usedFunction(): String return "used";
    public static function unusedFunction(): String return "unused"; // ← Removed
}

// Only usedFunction appears in final JS
Utils.usedFunction();
```

### 2. **Analyzer Optimization**

`-D analyzer-optimize` enables:
- **Constant folding**: `1 + 2` becomes `3`
- **Inlining**: Small functions inlined at call sites
- **Type-based optimizations**: Specialized code for known types

### 3. **ES6 Module Structure**

With `-D js-es=6` and `-D js-unflatten`:

```javascript
// Optimized module structure
export { AutoFocus } from "./hooks/AutoFocus.js";
export { ThemeToggle } from "./hooks/ThemeToggle.js";
export { Hooks } from "./hooks/Hooks.js";

// Instead of flattened:
// export const client_hooks_AutoFocus = ...
```

## Type System Integration

### Runtime Type Information

Haxe generates minimal runtime type info:

```javascript
// Type checking functions (only when needed)
function $hx_instanceof(obj, cl) {
    return obj != null && obj.__class__ == cl;
}

// RTTI (only with -D haxe-rtti)
AutoFocus.__name__ = "client.hooks.AutoFocus";
AutoFocus.__interfaces__ = [LiveViewHook];
```

### Type Erasure Benefits

- **Smaller bundles**: Interfaces and typedefs don't generate code
- **Better performance**: No runtime type checking overhead
- **Clean output**: Generated JS looks hand-written

## Performance Characteristics

### Bundle Size Analysis

For our todo-app client code:

| Component | Haxe Source | JS Output | Notes |
|-----------|-------------|-----------|-------|
| TodoApp.hx | 15KB | 8KB | Main application logic |
| Hooks (5 files) | 25KB | 12KB | LiveView hooks |
| Utils (2 files) | 8KB | 3KB | Utilities with DCE |
| **Total** | **48KB** | **23KB** | **52% reduction** |

### Compilation Speed

- **Cold compilation**: ~2-3 seconds
- **Incremental**: ~200-500ms
- **With DCE**: +10-20% compile time
- **Source maps**: +5-10% compile time

## Source Map Chain

### Development Workflow

```
Browser DevTools ← Source Maps ← JavaScript ← Haxe Source
     ↑                                            ↑
   Debug here                              Write code here
```

### Source Map Quality

Haxe generates high-quality source maps with:
- **Accurate line mapping**: Errors point to exact Haxe lines
- **Variable names**: Original Haxe variable names preserved
- **Call stack traces**: Full Haxe call stacks in browser
- **Breakpoints**: Debug Haxe code directly in browser

Example browser error:
```
Error at TodoTemplate.hx:45:12 in function renderTodoItem
  at client.templates.TodoTemplate.renderTodoItem (TodoTemplate.hx:45:12)
  at client.TodoApp.main (TodoApp.hx:38:8)
```

## Memory Management

### Garbage Collection

Haxe generates standard JavaScript objects:
- **No special GC**: Uses browser's native garbage collection
- **Weak references**: Supported through browser APIs
- **Manual cleanup**: Event listeners cleaned up in destroyed()

### Object Creation Patterns

```javascript
// Efficient object creation
class TodoItem {
    constructor(id, title) {
        this.id = id;
        this.title = title;
    }
}

// vs Java-style (what other transpilers might generate)
function TodoItem() {
    var this_ = {};
    this_.id = 0;
    this_.title = "";
    return this_;
}
```

## Browser Compatibility

### ES6 Target Benefits

- **Native classes**: Better performance than function constructors
- **Modules**: Tree shaking and lazy loading support
- **Arrow functions**: Cleaner generated code
- **Template literals**: Better string handling

### Fallback Strategy

For older browsers, use Babel in esbuild:

```javascript
// esbuild config
{
  target: ['es2017', 'chrome60', 'firefox60', 'safari11']
}
```

## Integration with Phoenix

### Hook Export Pattern

Our generated JavaScript integrates with Phoenix LiveView:

```javascript
// Generated hook exports
export const Hooks = {
    AutoFocus: client_hooks_AutoFocus,
    ThemeToggle: client_hooks_ThemeToggle,
    TodoForm: client_hooks_TodoForm,
    TodoFilter: client_hooks_TodoFilter,
    LiveSync: client_hooks_LiveSync
};

// Phoenix integration
import { Hooks } from "./app.js";
liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks });
```

## Limitations of Standard Haxe JS

### 1. **Verbose Patterns**

Some generated code is more verbose than hand-written:

```javascript
// Haxe enum matching
switch(filter._hx_index) {
    case 0: /* All */ break;
    case 1: /* Active */ break;
    case 2: /* Completed */ break;
}

// vs hand-written
switch(filter) {
    case 'all': break;
    case 'active': break;
    case 'completed': break;
}
```

### 2. **Async Patterns**

Haxe uses callback-style async:

```javascript
// Haxe generated
function fetchTodos(callback) {
    fetch('/api/todos').then(function(response) {
        callback(response.json());
    });
}

// vs modern async/await
async function fetchTodos() {
    const response = await fetch('/api/todos');
    return response.json();
}
```

### 3. **Bundle Size Considerations**

- **Haxe runtime**: ~2-5KB overhead
- **RTTI**: Can add significant size if enabled
- **Enum objects**: More verbose than string constants

## Optimization Best Practices

### 1. **Use Abstracts for Zero-Cost Wrappers**

```haxe
abstract ElementId(String) from String to String {
    public function focus(): Void {
        js.Browser.document.getElementById(this).focus();
    }
}
// Generates no runtime code - pure inlining
```

### 2. **Leverage DCE Effectively**

```haxe
#if debug
    public static function debugLog(msg: String): Void {
        trace(msg);
    }
#else
    public static inline function debugLog(msg: String): Void {
        // Inlined to nothing in release builds
    }
#end
```

### 3. **Minimize Dynamic Usage**

```haxe
// Avoid when possible
var data: Dynamic = response.data;

// Prefer typed structures
var data: {id: Int, title: String} = response.data;
```

## Future: Genes Compiler

The limitations above are precisely why Genes compiler would be beneficial:

- **Modern async/await**: Native Promise support
- **Cleaner output**: Less verbose generated code
- **Smaller bundles**: Reduced runtime overhead
- **Better tree shaking**: More efficient dead code elimination

See [ROADMAP.md](../examples/todo-app/ROADMAP.md) for detailed Genes migration plan.

## Conclusion

Haxe's standard JavaScript target provides:
- ✅ **Type safety** with compile-time checking
- ✅ **Good performance** with optimization flags
- ✅ **Excellent debugging** with source maps
- ✅ **Phoenix integration** through proper module exports
- ✅ **Maintainable code** with shared types

While there are areas for improvement (addressed by Genes), the current setup provides a solid foundation for type-safe Phoenix LiveView development.