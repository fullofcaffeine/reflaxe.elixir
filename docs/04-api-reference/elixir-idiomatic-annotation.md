# @:elixirIdiomatic Annotation

## Overview

The `@:elixirIdiomatic` annotation is a **specialized metadata marker** that instructs the Reflaxe.Elixir compiler to generate idiomatic Elixir patterns instead of generic tagged tuples for enum constructors.

**⚠️ IMPORTANT**: This annotation should be used **sparingly** - only for enums that represent established Elixir/OTP patterns.

## When to Use (Rare Cases)

### ✅ USE for OTP/BEAM Patterns

Use `@:elixirIdiomatic` **only** when your enum represents an established Elixir/OTP pattern that requires specific compilation:

#### 1. OTP Child Specifications
```haxe
@:elixirIdiomatic
enum ChildSpecFormat {
    ModuleRef(module: String);
    ModuleWithArgs(module: String, args: Array<Dynamic>);
    ModuleWithConfig(module: String, config: Array<{key: String, value: Dynamic}>);
}

// Compiles to proper OTP formats:
ModuleRef("MyWorker")                    // → MyWorker
ModuleWithArgs("Worker", [1, 2])         // → {Worker, [1, 2]}
ModuleWithConfig("Phoenix.PubSub", [...]) // → {Phoenix.PubSub, [name: "..."]}
```

#### 2. Standard Result/Option Patterns
```haxe
@:elixirIdiomatic
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

// Compiles to Elixir conventions:
Ok("success")    // → {:ok, "success"}
Error("failed")  // → {:error, "failed"}
```

#### 3. GenServer Response Patterns
```haxe
@:elixirIdiomatic
enum GenServerReply<T, S> {
    Reply(response: T, newState: S);
    NoReply(newState: S);
    Stop(reason: String, newState: S);
}

// Compiles to GenServer expected formats:
Reply(data, state)      // → {:reply, data, state}
NoReply(state)          // → {:noreply, state}
Stop("shutdown", state) // → {:stop, "shutdown", state}
```

## When NOT to Use (Most Cases)

### ❌ DON'T USE for Regular Application Enums

**95% of your enums should NOT use this annotation**. Regular application enums should compile to standard tagged tuples:

#### Domain Models (NO annotation)
```haxe
// NO @:elixirIdiomatic - just a regular enum
enum UserRole {
    Admin;
    Moderator(permissions: Array<String>);
    User(tier: String);
}

// Compiles to standard tagged tuples:
Admin                        // → :admin
Moderator(["edit", "delete"]) // → {:moderator, ["edit", "delete"]}
User("premium")              // → {:user, "premium"}
```

#### Application State (NO annotation)
```haxe
// NO @:elixirIdiomatic - application-specific
enum ConnectionState {
    Disconnected;
    Connecting(attemptNumber: Int);
    Connected(socket: Dynamic);
    Reconnecting(lastError: String, attemptNumber: Int);
}

// Compiles to predictable tuples:
Disconnected           // → :disconnected
Connecting(3)          // → {:connecting, 3}
Connected(socket)      // → {:connected, socket}
```

#### UI States (NO annotation)
```haxe
// NO @:elixirIdiomatic - not an Elixir pattern
enum LoadingState<T> {
    Idle;
    Loading(progress: Float);
    Success(data: T);
    Failure(error: String);
}

// Standard compilation:
Idle              // → :idle
Loading(0.5)      // → {:loading, 0.5}
Success(data)     // → {:success, data}
Failure("timeout") // → {:failure, "timeout"}
```

## How It Works

### Without @:elixirIdiomatic (Default Behavior)
```haxe
enum MyEnum {
    Simple;
    WithArg(x: Int);
    Complex(x: Int, y: String);
}

// Predictable compilation:
Simple           // → :simple
WithArg(42)      // → {:with_arg, 42}
Complex(1, "hi") // → {:complex, 1, "hi"}
```

### With @:elixirIdiomatic (Convention-Based Compilation)
```haxe
@:elixirIdiomatic
enum SpecialEnum {
    // Compiler applies convention-based transformations
}
```

The compiler uses **structural conventions**, not hardcoded patterns:

#### Convention Rules:

1. **Zero Arguments** → Bare atom
   ```haxe
   Permanent    // → :permanent (not {:permanent})
   None         // → :none
   ```

2. **Single Argument** → Unwrap the value
   ```haxe
   ModuleRef("Phoenix.PubSub")  // → Phoenix.PubSub (not {:module_ref, Phoenix.PubSub})
   Some(42)                      // → 42 (just the value)
   ```

3. **Two Arguments with Keyword List** → OTP tuple pattern
   ```haxe
   ModuleWithConfig("Phoenix.PubSub", [{key: "name", value: "MyApp"}])
   // → {Phoenix.PubSub, [name: "MyApp"]}
   ```

4. **Two Arguments (General)** → Tagged tuple
   ```haxe
   Ok(value)        // → {:ok, value}
   Error(reason)    // → {:error, reason}
   ```

5. **Three+ Arguments** → Standard tagged tuple
   ```haxe
   Reply(response, state, timeout)  // → {:reply, response, state, timeout}
   ```

### Module Name Detection

Strings that look like Elixir module names are automatically converted to atoms:
```haxe
ModuleRef("Phoenix.PubSub")   // → Phoenix.PubSub (atom)
ModuleRef("MyApp.Endpoint")   // → MyApp.Endpoint (atom)
ModuleRef("some_string")      // → "some_string" (stays string)
```

## Decision Flowchart

```
Is my enum representing an OTP/BEAM pattern?
├─ NO (95% of cases) → Don't use @:elixirIdiomatic
└─ YES → Does Elixir/OTP expect a specific format?
         ├─ NO → Don't use @:elixirIdiomatic
         └─ YES → Use @:elixirIdiomatic
```

## Common Mistakes

### ❌ Wrong: Using for Regular Business Logic
```haxe
@:elixirIdiomatic  // WRONG!
enum TodoPriority {
    High;
    Medium;
    Low;
}
```

### ✅ Correct: Only for Elixir Patterns
```haxe
// No annotation - it's just app logic
enum TodoPriority {
    High;
    Medium;
    Low;
}
```

### ❌ Wrong: Using Because "It Looks Cleaner"
```haxe
@:elixirIdiomatic  // WRONG - not an Elixir pattern!
enum HttpMethod {
    Get;
    Post(body: String);
    Put(body: String);
}
```

### ✅ Correct: Let Default Compilation Handle It
```haxe
// Standard compilation is fine
enum HttpMethod {
    Get;
    Post(body: String);
    Put(body: String);
}
```

## Rule of Thumb

**If you're unsure whether to use @:elixirIdiomatic, you probably shouldn't use it.**

The annotation exists specifically for interfacing with Elixir/OTP APIs that expect certain formats. If you're defining your own application's data types, use standard enum compilation.

## Implementation Details

When the compiler sees `@:elixirIdiomatic`:
1. The AST builder detects the metadata on the enum type
2. It marks enum constructor calls with `requiresIdiomaticTransform` in metadata
3. The AST transformer applies pattern-specific transformations
4. The result is idiomatic Elixir code that matches OTP expectations

## See Also

- [Enum Compilation Patterns](../03-compiler-development/ENUM_COMPILATION_PATTERNS.md)
- [OTP Integration](../02-user-guide/otp-integration.md)
- [Phoenix Patterns](../07-patterns/phoenix-patterns.md)