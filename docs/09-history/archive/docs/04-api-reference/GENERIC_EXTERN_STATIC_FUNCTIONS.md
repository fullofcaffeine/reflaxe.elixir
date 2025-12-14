# Generic Extern Static Functions in Haxe

This document explains the Haxe language limitation regarding static functions in generic extern classes and provides three proven solutions.

## The Problem ❌

Haxe has a fundamental language limitation: **static methods in generic extern classes cannot access the class's type parameter.**

```haxe
@:native("Phoenix.LiveView")
extern class LiveView<T> {
    // ❌ ERROR: Type not found: T
    static function mount(params: MountParams, session: Session, socket: Socket<T>): MountResult<T>;
}
```

**Error**: `Type not found : T on Phoenix.hx:84`

## Why This Limitation Exists

1. **Static methods operate at class level**, not instance level
2. **Type parameters are instance-specific** concepts  
3. **Static methods exist before instances**, so they can't know what `T` would be
4. **By design** - this is consistent across many languages (Java, C#, etc.)

## Investigation Evidence

### Haxe Standard Library Patterns
All generic extern classes with static methods in Haxe's standard library use **method-level generics**:

```haxe
// Promise<T> - each static method declares own T
static function resolve<T>(value: T): Promise<T>;
static function reject<T>(?reason: Dynamic): Promise<T>;
static function all<T>(iterable: Array<Promise<T>>): Promise<Array<T>>;

// Type class - each static method declares own T
static function createInstance<T>(cl: Class<T>, args: Array<Dynamic>): T;
static function getClass<T>(o: T): Class<T>;

// Reflect class - each static method declares own T  
static function compare<T>(a: T, b: T): Int;
static function copy<T>(o: Null<T>): Null<T>;
```

**Pattern**: Static methods **never** reference the class's generic parameter. They declare their own.

### Language Documentation
- "Static fields are used 'on the class' whereas non-static fields are used 'on a class instance'"
- "In a static function, you cannot access member variables"
- "Type parameters are not available to static fields"

## Three Solutions

## Solution 1: Method-Level Generics ✅ **RECOMMENDED**

Each static method declares its own type parameter. This is the **standard Haxe pattern**.

```haxe
@:native("Phoenix.LiveView")
extern class LiveView<T> {
    // Static methods with their own generic parameters
    static function mount<TAssigns>(params: MountParams, session: Session, socket: Socket<TAssigns>): MountResult<TAssigns>;
    static function handle_event<TAssigns>(event: String, params: EventParams, socket: Socket<TAssigns>): HandleEventResult<TAssigns>;
    static function handle_info<TAssigns>(info: PubSubMessage, socket: Socket<TAssigns>): HandleInfoResult<TAssigns>;
    
    // Instance methods can still use class T (if ever needed)
    function render(assigns: T): String;
}

// Usage example
class TodoLive {
    typedef TodoAssigns = { todos: Array<Todo>, filter: String };
    
    public static function mount(params, session, socket: Socket<TodoAssigns>): MountResult<TodoAssigns> {
        // Type inference works: TAssigns = TodoAssigns
        return LiveView.mount(params, session, socket);
    }
}
```

**Pros**:
- ✅ Follows Haxe standard library patterns (Promise, Type, Reflect)
- ✅ Maximum type safety at each call site
- ✅ Type inference works correctly
- ✅ Each call can have different assign types
- ✅ Explicit and clear

**Cons**:
- 🔸 Type parameter name differs from class parameter (`TAssigns` vs `T`)
- 🔸 Requires explicit type parameter (but type inference usually handles this)

**When to Use**: This is the **default choice** for generic extern classes with static methods.

---

## Solution 2: Non-Generic LiveView with Generic Socket

Remove generics from LiveView entirely, keeping only Socket generic.

```haxe
@:native("Phoenix.LiveView")
extern class LiveView {
    // Static methods with generic parameters (no class-level generic)
    static function mount<T>(params: MountParams, session: Session, socket: Socket<T>): MountResult<T>;
    static function handle_event<T>(event: String, params: EventParams, socket: Socket<T>): HandleEventResult<T>;
    static function handle_info<T>(info: PubSubMessage, socket: Socket<T>): HandleInfoResult<T>;
    
    // Instance methods without generics
    static function render(assigns: Dynamic): String; // Less type-safe
}

// Usage example  
class TodoLive {
    typedef TodoAssigns = { todos: Array<Todo>, filter: String };
    
    public static function mount(params, session, socket: Socket<TodoAssigns>): MountResult<TodoAssigns> {
        // T inferred as TodoAssigns
        return LiveView.mount(params, session, socket);
    }
}
```

**Pros**:
- ✅ Simpler class definition
- ✅ Matches Phoenix's actual non-generic nature
- ✅ Clean static method signatures
- ✅ Type safety where it matters (Socket assigns)

**Cons**:
- ❌ Less type-safe for any future instance methods
- ❌ Cannot distinguish between different LiveView types at class level

**When to Use**: When the extern class maps to a non-generic native library and generics are only needed for parameters.

---

## Solution 3: Separate Static Helper Class

Split static and instance methods into separate classes.

```haxe
// Instance-level class with generics
@:native("Phoenix.LiveView")
extern class LiveView<T> {
    // Instance methods that use T
    function render(assigns: T): String;
    // Any other instance-level methods
}

// Static helper class (maps to same native module)
@:native("Phoenix.LiveView")
extern class LiveViewStatic {
    static function mount<T>(params: MountParams, session: Session, socket: Socket<T>): MountResult<T>;
    static function handle_event<T>(event: String, params: EventParams, socket: Socket<T>): HandleEventResult<T>;
    static function handle_info<T>(info: PubSubMessage, socket: Socket<T>): HandleInfoResult<T>;
}

// Usage example
class TodoLive {
    typedef TodoAssigns = { todos: Array<Todo>, filter: String };
    
    public static function mount(params, session, socket: Socket<TodoAssigns>): MountResult<TodoAssigns> {
        return LiveViewStatic.mount(params, session, socket); // Different class
    }
}
```

**Pros**:
- ✅ Clear separation of concerns
- ✅ Both map to same native module via `@:native`
- ✅ Maximum flexibility for both static and instance contexts
- ✅ No generic conflicts

**Cons**:
- ❌ Less intuitive API (users must know about both classes)
- ❌ More complex documentation
- ❌ Import complexity

**When to Use**: When you have many instance methods that need the class generic AND many static methods that conflict with it.

---

## Recommended Decision Matrix

| Scenario | Recommended Solution | Reasoning |
|----------|---------------------|-----------|
| **Most extern classes** | Method-Level Generics | Standard Haxe pattern, follows stdlib |
| **Non-generic native library** | Non-Generic Class | Matches native library design |
| **Complex mixed usage** | Separate Classes | Maximum flexibility and clarity |
| **Phoenix LiveView** | Method-Level Generics | Follows Promise<T> pattern, maintains type safety |

## Implementation Guidelines

### 1. Type Parameter Naming Convention
- Class level: `<T>`, `<K, V>`
- Method level: `<TAssigns>`, `<TData>`, `<TResult>` (descriptive)

### 2. Documentation Requirements
- Always document which approach you chose and why
- Include usage examples showing type inference
- Note any trade-offs made

### 3. Testing Approach
- Test type inference works correctly
- Verify different call sites can use different types
- Ensure compilation errors are clear

## Conclusion

**Method-Level Generics (Solution 1)** is the recommended approach because:

1. **Follows established patterns** - Haxe's Promise, Type, and Reflect all use this pattern
2. **Maximum type safety** - Every call site gets proper type checking  
3. **Type inference friendly** - Haxe can usually infer the type parameter
4. **Future-proof** - Compatible with potential future instance methods

This approach transforms a Haxe language limitation into an idiomatic, type-safe API that provides the same developer experience as directly accessing class type parameters.