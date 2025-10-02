# Runtime Validation Issues - Task 8

**Date**: 2025-10-01
**Status**: ❌ BLOCKED - Cannot start server due to compilation errors
**Context**: Attempting runtime validation after fixing Enum method syntax

---

## Compilation Errors (2 Blocking)

### Error 1: Undefined Variable `priority2` in Todo.update_priority/2

**File**: `lib/todo_app/todo.ex:48`

**Error**:
```
error: undefined variable "priority2"
│
48 │     params = %{:priority => priority2}
│                             ^^^^^^^^^
```

**Haxe Source** (`src_haxe/server/schemas/Todo.hx:61-64`):
```haxe
public static function updatePriority(todo: Todo, priority: String): Changeset<Todo, TodoParams> {
    var params: TodoParams = {
        priority: priority  // Correct: using parameter 'priority'
    };
    return changeset(todo, params);
}
```

**Generated Elixir** (WRONG):
```elixir
def update_priority(todo, priority) do
  params = %{:priority => priority2}  # BUG: priority2 instead of priority
  Todo.changeset(todo, params)
end
```

**Root Cause**: Variable renaming bug in object literal context. The compiler incorrectly renames the parameter `priority` to `priority2` when used in a map value position.

**Impact**: BLOCKING - Function cannot compile

---

### Error 2: Undefined Variable `g` in TodoPubSub.parse_message_impl/1

**File**: `lib/server/pubsub/todo_pub_sub.ex:55`

**Error**:
```
error: undefined variable "g"
│
55 │     case g do
│          ^
```

**Generated Elixir** (WRONG):
```elixir
nil
case g do  # BUG: 'g' is never defined!
  "bulk_update" ->
    cond do
      ...
    end
end
```

**Root Cause**: Temporary variable `g` referenced but never defined. Likely a pattern matching or switch compilation bug where the matched value isn't properly extracted.

**Impact**: BLOCKING - Function cannot compile

---

## Unable to Perform Runtime Validation

**Consequence**: Cannot proceed with Task 8 until these compilation errors are fixed.

### Attempted Steps:
1. ✅ Compiled Haxe to Elixir - Success
2. ❌ Mix compilation - FAILED with 2 errors
3. ❌ Cannot start Phoenix server
4. ❌ Cannot test routes
5. ❌ Cannot test LiveView interactions
6. ❌ Cannot test PubSub
7. ❌ Cannot test Presence

---

## Required Fixes

### Fix 1: Object Literal Variable Resolution
**Location**: Likely in `ElixirASTBuilder.hx` or `VariableCompiler.hx`

**Issue**: When a parameter is used as a value in an object literal:
```haxe
{fieldName: parameterValue}  // Parameter gets incorrectly renamed
```

**Expected Behavior**:
- Parameter names should be preserved when used in object values
- No automatic renaming unless there's actual shadowing

### Fix 2: Switch/Case Temporary Variable Generation
**Location**: Likely in pattern matching or switch compilation

**Issue**: Temporary variable `g` referenced but not defined
- Switch expression value not being extracted to variable
- Or variable extracted but not properly inserted in code

**Expected Behavior**:
- If a temporary variable is needed, generate it before use
- Or use the expression directly in the case statement

---

## Testing After Fixes

Once compilation errors are resolved, the runtime validation checklist is:

1. **Phoenix Server Start**
   ```bash
   mix phx.server
   # Expected: Server starts on port 4000
   ```

2. **Basic Routes**
   ```bash
   curl http://localhost:4000/
   # Expected: TodoApp homepage loads
   ```

3. **LiveView Interactions** (via browser)
   - Navigate to /todos
   - Create todo
   - Toggle completion
   - Delete todo
   - Search/filter

4. **PubSub Messaging**
   - Open two browser windows
   - Verify real-time updates
   - Check server logs for PubSub.subscribe success

5. **Phoenix.Presence**
   - Open /users route
   - Verify presence tracking
   - Check multi-user scenarios

6. **Log Analysis**
   - No runtime errors
   - No FunctionClauseError
   - No undefined function errors

---

## Priority Order

1. ⏭️ **IMMEDIATE**: Fix object literal variable resolution (Error 1)
2. ⏭️ **IMMEDIATE**: Fix switch temporary variable generation (Error 2)
3. ⏭️ **THEN**: Recompile and test
4. ⏭️ **THEN**: Continue with Task 8 runtime validation

---

## Related Tasks

- **Task 7**: ✅ Complete - Fixed Enum method syntax (22 tests)
- **Task 8**: ❌ Blocked - Cannot proceed until compilation errors fixed
- **Task 9**: Pending - Depends on Tasks 7 and 8 completion

---

## Notes

- These errors were revealed AFTER the Enum method fix
- Both are compiler bugs, not user code issues
- The Haxe source code is correct
- The generated Elixir code has variable naming/generation bugs
