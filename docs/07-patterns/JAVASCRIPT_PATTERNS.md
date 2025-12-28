# Modern Haxe JavaScript Patterns

**CRITICAL**: Always check Haxe reference folder and official docs for modern APIs before implementing JavaScript features.

## JavaScript Async/Await Support ✨ (Supported)

**Complete async/await support for modern JavaScript compilation**:
- ✅ **@:async annotation** - Transform functions to native `async function` declarations
- ✅ **Anonymous function support** - Full async support for lambda expressions and event handlers
- ✅ **Type-safe Promise handling** - Automatic Promise<T> wrapping with import-aware type detection
- ✅ **Custom JS Generator** - AsyncJSGenerator extends ExampleJSGenerator for proper code generation
- ✅ **Zero runtime overhead** - Pure compile-time transformation via build macros

**See**: [`async-await-specification.md`](../09-history/archive/docs/04-api-reference/async-await-specification.md) - Async/await specification and examples (archived)

## Modern Haxe JavaScript Patterns ⚡ **REQUIRED READING**

### 1. JavaScript Code Injection

❌ **Deprecated (Haxe 4.1+)**:
```haxe
untyped __js__("console.log({0})", value);  // Shows deprecation warning
```

✅ **Modern (Haxe 4.1+)**:
```haxe
js.Syntax.code("console.log({0})", value);  // Clean, no warnings
```

### 2. Type-Safe DOM Element Casting

❌ **Unsafe Pattern**:
```haxe
var element = cast(e.target, js.html.Element);  // No type checking
```

✅ **Safe Pattern**:
```haxe
var target = e.target;
if (target != null && js.Syntax.instanceof(target, js.html.Element)) {
    var element = cast(target, js.html.Element);  // Type-safe casting
    // Use element safely
}
```

### 3. Performance Monitoring APIs

❌ **Deprecated (Shows warnings)**:
```haxe
var timing = js.Browser.window.performance.timing;  // PerformanceTiming deprecated
var loadTime = timing.loadEventEnd - timing.navigationStart;
```

✅ **Modern (No warnings)**:
```haxe
var entries = js.Browser.window.performance.getEntriesByType("navigation");
if (entries.length > 0) {
    var navTiming: js.html.PerformanceNavigationTiming = cast entries[0];
    var domLoadTime = navTiming.domContentLoadedEventEnd - navTiming.domContentLoadedEventStart;
    var fullLoadTime = navTiming.loadEventEnd - navTiming.fetchStart;
}
```

### 4. DOM Hierarchy Understanding

```
EventTarget (addEventListener, removeEventListener)
    ↓
Node (nodeName, nodeType, parentNode)
    ↓  
DOMElement (id, className, classList, attributes)
    ↓
Element (click, focus, innerHTML) - The HTML element you usually want
```

## Development Rules

1. **ALWAYS check existing implementations first** - Before starting any task, search for existing implementations, similar patterns, or related code in the codebase to avoid duplicate work
2. **Verify task completion status** - Check if the task is already done through existing files, examples, or alternative approaches before implementing from scratch
3. **Check deprecation warnings** - Never ignore Haxe compiler warnings about deprecated APIs
4. **Reference modern docs** - Use https://api.haxe.org/ for Haxe 4.3+ patterns
5. **Use upstream sources** - When unsure, check the Haxe stdlib sources (e.g. `haxe/std/js/**` in the Haxe repo) for modern implementations
6. **Type safety first** - Always use `js.Syntax.instanceof()` before casting DOM elements
7. **Performance APIs** - Use `PerformanceNavigationTiming` instead of deprecated `PerformanceTiming`

## Modern API Migration Guide

### Browser APIs

**Use modern, non-deprecated APIs:**

| Deprecated | Modern Alternative | Reason |
|------------|-------------------|--------|
| `__js__()` | `js.Syntax.code()` | Official deprecation in Haxe 4.1+ |
| `performance.timing` | `performance.getEntriesByType("navigation")` | W3C deprecated PerformanceTiming |
| Direct casting | `js.Syntax.instanceof()` checks | Runtime type safety |
| `untyped` where avoidable | Type-safe abstracts/externs | Compile-time validation |

### Type Safety Patterns

**Always prefer compile-time safety:**

```haxe
// ✅ Type-safe nullable handling
function processElement(el: Null<Element>): Void {
    switch (el) {
        case null: return;
        case element: doSomething(element);
    }
}

// ✅ Safe type checking before casting
function getInputValue(target: EventTarget): Null<String> {
    return if (js.Syntax.instanceof(target, js.html.InputElement)) {
        cast(target, js.html.InputElement).value;
    } else {
        null;
    }
}

// ✅ Abstract types for domain safety
abstract UserId(Int) {
    public inline function new(id: Int) this = id;
    public inline function toInt(): Int return this;
}
```

### Performance Best Practices

**Optimize for modern JavaScript engines:**

1. **Use `inline` functions** for zero-cost abstractions
2. **Leverage tree-shaking** with proper import/export patterns
3. **Avoid `Dynamic`** - use typed alternatives
4. **Use proper `@:native` annotations** for external library integration
5. **Prefer `Map<K,V>` over `Dynamic` objects** for structured data

---

**Key Insight**: Modern Haxe JavaScript compilation emphasizes **compile-time safety** and **zero-cost abstractions** while generating **performant, standards-compliant JavaScript** that works across all modern browsers.
