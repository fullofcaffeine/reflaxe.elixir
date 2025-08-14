# Variable Renaming Solution

## Problem Statement

When Haxe compiles code with variables that might shadow other names (like a local variable `todos` and an object field `todos`), it automatically renames variables to avoid conflicts. For example:

```haxe
// Haxe source
var todos = load_todos();
return socket.assign({
    todos: todos,  // Field name: todos, Variable: todos
    //...
});
```

Haxe renames the variable to avoid confusion:
- `todos` → `todos2`
- `current_user` → `current_user2`

This caused our Elixir compiler to generate invalid code that referenced the wrong variable names.

## Investigation Findings

### How Haxe Handles Renaming

Located in `/haxe/src/filters/renameVars.ml`:

1. **Renaming Logic**: When variables conflict, Haxe appends numbers:
   ```ocaml
   name := v.v_name ^ (string_of_int !count);
   ```

2. **Original Name Preservation**: The original name is stored in metadata:
   ```ocaml
   v.v_meta <- (Meta.RealPath,[EConst (String(v.v_name,SDoubleQuotes)),null_pos],null_pos) :: v.v_meta;
   ```

3. **Metadata Format**: `Meta.RealPath` or `:realPath` contains the original variable name before renaming.

### How Other Compilers Handle This

- **GenCpp, GenHL**: Check for `Meta.RealPath` metadata to get original names
- **Reflaxe**: Provides `NameMetaHelper` for handling metadata on objects with `name` and `meta` properties

## Solution Implementation

### 1. Helper Function

Created `getOriginalVarName` function to retrieve original variable names:

```haxe
private function getOriginalVarName(v: TVar): String {
    // TVar has both name and meta properties, so we can use the helper
    return v.getNameOrMeta(":realPath");
}
```

This uses Reflaxe's `NameMetaHelper` to check for `:realPath` metadata and returns the original name if available, otherwise falls back to the current name.

### 2. Applied Throughout Compiler

Updated all places where variable names are accessed:

- **TLocal**: Variable references
- **TVar**: Variable declarations
- **TFor**: Loop variables
- **TUnop**: Increment/decrement operations
- **Loop analysis functions**: Pattern detection for counting, filtering, etc.

### 3. Key Code Locations Updated

- `compileExpression` - TLocal and TVar cases
- `compileForLoop` - Loop variable handling
- `analyzeLoopBody` - Pattern analysis
- `extractLoopVariableFromBody` - Variable extraction
- `collectVariables` - Variable collection
- `extractModifiedVariables` - Mutation tracking
- `compileExpressionWithMutationTracking` - Mutation compilation

## Result

Before fix:
```elixir
def find_todo(id, todos) do
    Enum.find(todos2, fn todo -> (todo.id == id) end)  # Wrong: todos2
end
```

After fix:
```elixir
def find_todo(id, todos) do
    Enum.find(todos, fn todo -> (todo.id == id) end)  # Correct: todos
end
```

## Technical Details

### Why This Works

1. **Metadata Preservation**: Haxe always preserves the original name in metadata
2. **Using Static Extension**: `NameMetaHelper` provides `getNameOrMeta` as a static extension
3. **Fallback Safety**: If no metadata exists, the current name is used
4. **Consistent Application**: Applied everywhere variables are referenced or declared

### Performance Impact

Minimal - just an additional metadata check when compiling variables.

## Testing

The todo-app now compiles correctly with proper variable names throughout the generated Elixir code.

## Lessons Learned

1. **Always Check Metadata**: When working with renamed entities in Haxe, check for metadata that preserves original information
2. **Use Reflaxe Helpers**: The Reflaxe framework provides useful helpers like `NameMetaHelper` for common patterns
3. **Understand the AST Pipeline**: Variable renaming happens during Haxe's filtering phase, after typing but before our compiler sees the AST
4. **Reference Implementations**: Studying how other generators (GenCpp, GenHL) handle this helped identify the solution pattern