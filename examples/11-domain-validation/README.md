# Domain Validation Example

This example demonstrates **type-safe domain abstractions** that showcase how Haxe enhances Elixir development with compile-time guarantees while generating idiomatic Elixir code.

## What This Example Shows

- **Type Safety**: Email, UserId, PositiveInt, and NonEmptyString types prevent invalid data at compile-time
- **Parse, Don't Validate**: Strong types guarantee validity after construction
- **Functional Composition**: Result/Option types enable safe chaining of operations
- **Idiomatic Elixir**: Generated code uses `{:ok, value}` / `:error` patterns
- **Real-World Usage**: User registration system with comprehensive validation

## Domain Abstractions

### Email
```haxe
// Type-safe email with validation and domain extraction
var email = Email.parse("user@example.com");
email.map(e -> e.getDomain());  // "example.com"
```

### UserId  
```haxe
// Alphanumeric IDs with case-insensitive comparison
var userId = UserId.parse("User123");
userId.map(id -> id.equalsIgnoreCase(otherUserId));
```

### PositiveInt
```haxe
// Integers guaranteed > 0 with safe arithmetic
var count = PositiveInt.parse(5);
count.flatMap(n -> n.safeSub(PositiveInt.parse(3)));  // Ok(2)
```

### NonEmptyString
```haxe
// Strings guaranteed to have content
var name = NonEmptyString.parseAndTrim("  Alice  ");  
name.map(n -> n.toUpperCase());  // "ALICE"
```

## Key Benefits of Haxe → Elixir

### 1. **Compile-Time Safety + Runtime Idioms**
- Haxe provides compile-time type checking
- Generated Elixir uses idiomatic `{:ok, value}` / `:error` patterns
- No manual type guards needed in Elixir code

### 2. **Functional Composition**
```haxe
// Chain operations with automatic error handling
var result = UserId.parse(input)
    .flatMap(id -> Email.parse(emailInput).map(email -> {id: id, email: email}))
    .flatMap(data -> createUser(data.id, data.email));
```

### 3. **Zero Boilerplate**
- No need for custom validation functions
- No manual error tuple construction
- Automatic parameter validation

### 4. **LLM-Friendly Development**
- Deterministic types reduce AI hallucinations
- Clear domain vocabulary for LLM code generation
- Type system guides AI toward correct patterns

## Files

- `UserRegistration.hx` - Complete user registration system
- `build.hxml` - Compilation configuration
- `mix.exs` - Phoenix project configuration (generated)

## Running the Example

```bash
# Compile Haxe to Elixir
haxe build.hxml

# Run the generated Elixir code  
mix run
```

## Generated Elixir Code

The Haxe domain abstractions compile to clean, idiomatic Elixir:

```elixir
# Email validation compiles to:
case Email.parse("user@example.com") do
  {:ok, email} -> Email.get_domain(email)  
  :error -> "invalid"
end

# Type-safe arithmetic compiles to:
case PositiveInt.safe_sub(count, amount) do
  {:ok, result} -> {:ok, result}
  :error -> :insufficient_funds  
end
```

This demonstrates how Haxe acts as a **powerful code generator** that produces maintainable, type-safe Elixir while eliminating boilerplate and runtime errors.
