# Enum Compilation Patterns in Reflaxe.Elixir

## The Problem: Haxe Enums vs Elixir Data Structures

Haxe enums are algebraic data types that need to be translated into idiomatic Elixir patterns. This creates a fundamental challenge:

1. **Haxe Side**: Type-safe enum constructors with parameters
2. **Elixir Side**: Various data structure patterns (tuples, atoms, keyword lists, maps)
3. **The Gap**: The compiler must understand the *intent* of each enum to generate proper Elixir code

## Common Patterns That Need Special Compilation

### 1. OTP Child Specifications (ChildSpecFormat)
```haxe
// Haxe enum definition
enum ChildSpecFormat {
    ModuleRef(module: String);
    ModuleWithArgs(module: String, args: Array<Dynamic>);
    ModuleWithConfig(module: String, config: Array<{key: String, value: Dynamic}>);
    FullSpec(spec: ChildSpec);
}

// Usage in Haxe
ModuleWithConfig("Phoenix.PubSub", [{key: "name", value: "MyApp.PubSub"}])

// Should compile to Elixir as:
{Phoenix.PubSub, [name: "MyApp.PubSub"]}
```

### 2. Result Types (Common Functional Pattern)
```haxe
// Haxe enum
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

// Usage
Ok("success")
Error("failed")

// Should compile to:
{:ok, "success"}
{:error, "failed"}
```

### 3. Option Types
```haxe
// Haxe enum
enum Option<T> {
    Some(value: T);
    None;
}

// Usage
Some(42)
None

// Should compile to:
{:some, 42}
:none
```

### 4. GenServer Responses
```haxe
// Haxe enum
enum GenServerReply<T, S> {
    Reply(response: T, newState: S);
    NoReply(newState: S);
    Stop(reason: String, newState: S);
}

// Should compile to:
{:reply, response, new_state}
{:noreply, new_state}
{:stop, reason, new_state}
```

## Why This Happens Repeatedly

This pattern occurs because:

1. **Type Safety vs Runtime Representation**: Haxe provides compile-time type safety through enums, but Elixir uses runtime patterns (tuples, atoms)
2. **Framework Integration**: Many Elixir frameworks (OTP, Phoenix, Ecto) expect specific data formats
3. **Idiomatic Code Generation**: We want generated Elixir to look hand-written, not machine-translated

## General Solution: Enum Compilation Rules

### Approach 1: Metadata-Based Compilation
Add metadata to enums to specify their Elixir representation:

```haxe
@:elixirCompile("tuple")
@:constructorFormat("atom_snake_case")
enum Result<T, E> {
    @:elixirAtom("ok")
    Ok(value: T);
    
    @:elixirAtom("error")
    Error(error: E);
}
```

### Approach 2: Convention-Based Compilation
Establish naming conventions that the compiler recognizes:

- Enums ending with `Result` → `{:ok, _}` / `{:error, _}` pattern
- Enums ending with `Option` → `{:some, _}` / `:none` pattern
- Enums in `otp` package → OTP-specific patterns

### Approach 3: AST Transformation Passes (Current Implementation)
Use transformation passes to detect and convert specific enum patterns:

```haxe
// In ElixirASTTransformer.hx
static function enumCompilationPass(ast: ElixirAST): ElixirAST {
    switch (ast.def) {
        case ECall(target, args):
            // Detect enum constructor calls
            if (isEnumConstructor(target)) {
                return compileEnumToElixir(target, args);
            }
        // ... other cases
    }
}
```

## Implementation Strategy

### Phase 1: Detection
The compiler needs to detect when an enum constructor is being used:
- During AST building (`ElixirASTBuilder.hx`)
- Mark enum constructor calls with metadata
- Preserve enum type information for transformation

### Phase 2: Transformation
During AST transformation (`ElixirASTTransformer.hx`):
- Identify enum constructor patterns
- Apply appropriate compilation rules
- Generate idiomatic Elixir structures

### Phase 3: Printing
During code generation (`ElixirASTPrinter.hx`):
- Output the transformed Elixir code
- Ensure proper formatting and syntax

## Benefits of General Solution

1. **Consistency**: All enums following a pattern compile the same way
2. **Maintainability**: New enum patterns can be added without compiler changes
3. **Type Safety**: Maintains compile-time checking while generating runtime patterns
4. **Idiomatic Output**: Generated code matches Elixir conventions

## Examples of Other Affected Code

### Phoenix Presence
```haxe
enum PresenceUpdate {
    Join(user: User, metadata: Dynamic);
    Leave(user: User, metadata: Dynamic);
}
// Needs to compile to Phoenix Presence format
```

### Ecto Changesets
```haxe
enum ChangesetAction {
    Insert;
    Update;
    Delete;
    Replace;
}
// Needs to compile to Ecto atoms
```

### LiveView Events
```haxe
enum LiveViewEvent {
    Mount(params: Dynamic, session: Dynamic);
    HandleEvent(event: String, params: Dynamic);
    HandleInfo(message: Dynamic);
}
// Needs to compile to LiveView handler format
```

## Conclusion

This is a fundamental pattern in the Reflaxe.Elixir compiler. Any time we create type-safe Haxe enums to represent Elixir data structures, we need compilation rules to translate them properly. The solution should be general and extensible, not hardcoded for specific types.