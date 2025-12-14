# Future Type-Safe Assign Syntax Ideas

## Current State (December 2024)

We currently use the `_.fieldName` pattern for type-safe assigns:
```haxe
socket.assign(_.userId, 123);
socket.merge({userId: 123, userName: "Alice"});
```

While this works and provides compile-time validation, the underscore syntax (`_`) is unconventional and might confuse developers.

## Alternative Syntax Proposals for Future Milestones

### 1. Field Descriptor Pattern (Strongly Typed)
```haxe
// Create a field descriptor that knows its type
class Fields<T> {
    public var userId: FieldRef<Int>;
    public var userName: FieldRef<String>;
}

// Usage
var f = new Fields<TodoLiveAssigns>();
socket.assign(f.userId, 123);        // Type-safe, no strings!
socket.assign(f.userName, "Alice");  // Compile error if wrong type
```

**Pros**: 
- Very explicit and type-safe
- Familiar object-oriented syntax
- Could provide additional metadata

**Cons**: 
- Requires generating field descriptors
- More verbose than current approach

### 2. Property Access Pattern
```haxe
// Use a proxy-like pattern
var assigns = socket.assigns();
assigns.userId = 123;        // Property setter
assigns.userName = "Alice";
socket = assigns.commit();    // Apply all changes
```

**Pros**: 
- Natural JavaScript-like syntax
- Batches updates automatically
- Very intuitive

**Cons**: 
- Harder to implement in Haxe
- Might not translate well to Elixir

### 3. Lens Pattern (Functional)
```haxe
// Create lenses for each field
var userIdLens = Lens.create<TodoLiveAssigns, Int>("userId");
var userNameLens = Lens.create<TodoLiveAssigns, String>("userName");

// Usage
socket = userIdLens.set(socket, 123);
socket = userNameLens.set(socket, "Alice");
```

**Pros**: 
- Functional programming pattern
- Composable and powerful
- Well-understood in FP community

**Cons**: 
- Learning curve for non-FP developers
- More verbose for simple updates

### 4. Builder Pattern with Fluent Interface
```haxe
// Create a builder that knows the assigns type
socket = Assigns.for(socket)
    .userId(123)
    .userName("Alice")
    .editingTodo(null)
    .apply();
```

**Pros**: 
- Fluent, readable API
- Method chaining feels natural
- Each method is typed

**Cons**: 
- Requires code generation for each assigns type
- Might be too "magical"

### 5. Tagged Template Literal Pattern (Experimental)
```haxe
// Use a macro to parse template literals
socket = assign!`
    userId: ${123}
    userName: ${"Alice"}
    editingTodo: ${null}
`;
```

**Pros**: 
- Very concise
- Visually clear
- Could validate at compile time

**Cons**: 
- Not standard Haxe syntax
- Might be too different from normal code

## Recommendation for Next Steps

1. **Keep current `_.field` pattern for now** - It works and is battle-tested
2. **Prototype Field Descriptor pattern** - Most promising alternative
3. **Gather user feedback** - See what syntax developers prefer
4. **Consider gradual migration** - Support both patterns during transition

## Implementation Considerations

Whatever syntax we choose must:
- ✅ Provide compile-time field validation
- ✅ Support type checking for values  
- ✅ Convert camelCase to snake_case automatically
- ✅ Generate clean, idiomatic Elixir code
- ✅ Work with IDE autocomplete
- ✅ Be discoverable and intuitive

## Timeline

- **Current (v1.0)**: `_.field` pattern (working)
- **v1.1**: Prototype alternative syntaxes
- **v1.2**: User feedback and testing
- **v2.0**: Implement chosen syntax alongside current pattern
- **v3.0**: Deprecate old syntax if new one proves superior

## Related Documentation

- [LiveSocket Implementation](../04-api-reference/LiveSocket.md)
- [AssignMacro Details](../../std/phoenix/macros/AssignMacro.hx)
- [Type Safety Patterns](./type-safety-patterns.md)