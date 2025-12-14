# Preserving Functions Through Dead Code Elimination (DCE)

## The Problem: Changeset Functions Being Eliminated

When compiling Haxe to Elixir, functions marked with `@:changeset` in schema classes were being removed by Haxe's Dead Code Elimination (DCE) before reaching the code generator. This happened because:

1. **DCE runs before code generation**: Haxe optimizes away "unused" code before Reflaxe sees it
2. **Changesets appear unused**: From Haxe's perspective, changeset functions are only called from generated Elixir code (not visible during Haxe compilation)
3. **Metadata alone doesn't preserve**: Just adding `@:changeset` doesn't prevent DCE

## Two Approaches: Build Macro vs @:keep

### Approach 1: Build Macro with Registry (Complex)

**How it works:**
```haxe
@:build(reflaxe.elixir.macros.SchemaRegistrar.build())
class Todo {
    @:changeset
    public static function changeset(todo: Todo, params: Dynamic): Changeset<Todo> {
        // Validation logic
    }
}
```

The build macro would:
1. Run during macro phase (before typing)
2. Scan class fields for `@:changeset` metadata
3. Store metadata in a registry (Map or Context storage)
4. Add `@:keep` to prevent DCE
5. Registry accessible during code generation

**Advantages:**
- Centralized metadata collection
- Can extract additional information (parameter types, validation patterns)
- Deterministic list of changesets for code generation
- Could potentially analyze function bodies

**Disadvantages:**
- **Complexity**: Requires macro infrastructure
- **Storage challenges**: `Context.registerModuleReuseCall` is deprecated (Haxe 4.3+)
- **Cross-module access**: Registry must persist across compilation units
- **Maintenance burden**: More moving parts to maintain
- **Build time overhead**: Extra macro processing

### Approach 2: Direct @:keep Metadata (Simple) ✅ CHOSEN

**How it works:**
```haxe
class Todo {
    @:changeset
    @:keep  // Simply add this to preserve through DCE
    public static function changeset(todo: Todo, params: Dynamic): Changeset<Todo> {
        // Validation logic
    }
}
```

**Advantages:**
- **Simplicity**: Just add one metadata tag
- **No macro overhead**: Works with existing compilation flow
- **Reliable**: Haxe's built-in DCE respect for @:keep
- **Maintainable**: No complex infrastructure needed
- **Clear intent**: Explicit about preservation

**Disadvantages:**
- Manual addition required (but can be automated in compiler)
- No centralized registry (but not needed for current use case)

## Why @:keep is Better for Our Use Case

### 1. Architectural Simplicity
```haxe
// The compiler can automatically add @:keep when it sees @:changeset
// This happens during the AST transformation phase
if (field.meta.has(":changeset")) {
    field.meta.add(":keep", [], field.pos);
}
```

### 2. No External Dependencies
- Works with all Haxe versions
- No deprecated API usage
- No complex storage mechanisms
- No cross-module communication needed

### 3. Transparent to Users
Users write:
```haxe
@:changeset
public static function changeset(todo: Todo, params: Dynamic): Changeset<Todo> {
    // Their validation logic
}
```

Compiler ensures it's preserved - users don't need to know about @:keep.

### 4. Follows Established Patterns
Many Haxe libraries use @:keep for similar purposes:
- Test frameworks preserve test methods
- Reflection-based systems preserve accessed fields
- Serialization libraries preserve data fields

## Implementation in the Compiler

### Current Implementation (AnnotationTransforms.hx)

```haxe
// Check if a changeset function exists in the body
var hasChangeset = false;
switch(existingBody.def) {
    case EBlock(stmts):
        for (stmt in stmts) {
            switch(stmt.def) {
                case EDef("changeset", _, _, _):
                    hasChangeset = true;
                default:
            }
        }
    default:
}

// If no changeset found, generate a basic one
if (!hasChangeset && meta?.schemaFields != null) {
    // Generate fallback changeset
}
```

### Future Enhancement: Automatic @:keep Addition

We could enhance the compiler to automatically add @:keep during the macro phase:

```haxe
// In macro context when processing classes
#if macro
static function processSchemaClass(fields: Array<Field>): Array<Field> {
    for (field in fields) {
        if (field.meta != null) {
            for (meta in field.meta) {
                if (meta.name == ":changeset" && !hasKeepMeta(field)) {
                    field.meta.push({
                        name: ":keep",
                        pos: field.pos
                    });
                }
            }
        }
    }
    return fields;
}
#end
```

## Comparison with Codex's Recommendation

Codex recommended a hybrid approach: registry + @:keep. After implementation attempts, we found:

1. **Registry complexity not needed**: We don't need centralized metadata access
2. **@:keep alone sufficient**: Solves the DCE problem completely
3. **Simpler is better**: Less code to maintain, fewer failure points

## Best Practices for Function Preservation

### When to Use @:keep
- Functions only called from generated code
- Reflection-accessed methods
- Framework integration points
- Test methods

### When NOT to Use @:keep
- Regular application code
- Functions with direct Haxe callers
- Internal implementation details
- Performance-critical hot paths (prevents DCE optimization)

### Alternative: @:used
For entire classes that should be preserved:
```haxe
@:used  // Preserves entire class
class Configuration {
    // All fields preserved
}
```

## Testing Function Preservation

### Verify Preservation
```bash
# Compile and check generated code
npx haxe build-server.hxml
grep -n "def changeset" lib/server/schemas/todo.ex
```

### Debug DCE Issues
```haxe
// Add debug flag to see what's eliminated
-D dump.dependencies
-D dump.usage
```

## Related Documentation

- [Haxe DCE Documentation](https://haxe.org/manual/cr-dce.html)
- [Metadata Documentation](https://haxe.org/manual/lf-metadata.html)
- [Schema Emission Implementation](./architecture.md#schema-emission)