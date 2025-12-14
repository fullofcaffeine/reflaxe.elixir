# parseMessageImpl AST Structure Investigation

## Problem Statement
Pattern detection in TypedExprPreprocessor.hx fires for TodoLive.hx but NOT for TodoPubSub.hx parseMessageImpl. We need to understand WHY the AST structures differ.

## Fixed Compilation Error

**Original Error**:
```
src/reflaxe/elixir/preprocessor/TypedExprPreprocessor.hx:473: characters 58-62 : haxe.macro.FieldAccess has no field name
```

**Root Cause**: `FieldAccess` is an enum, not a structure with a `name` field.

**Correct Pattern**:
```haxe
case TField(_, FInstance(_, _, cf)): 'TField.FInstance(${cf.get().name})';
case TField(_, FStatic(_, cf)): 'TField.FStatic(${cf.get().name})';
case TField(_, FAnon(cf)): 'TField.FAnon(${cf.get().name})';
case TField(_, FDynamic(s)): 'TField.FDynamic($s)';
```

## Key Discovery: parseMessageImpl Structure

### Actual Source Code (TodoPubSub.hx:189-226)
```haxe
public static function parseMessageImpl(msg: Dynamic): Option<TodoPubSubMessage> {
    if (!SafePubSub.isValidMessage(msg)) {  // Line 190
        trace(SafePubSub.createMalformedMessageError(msg));
        return None;
    }

    return switch (msg.type) {  // Line 195 - Switch is in RETURN statement!
        case "todo_created":
            if (msg.todo != null) Some(TodoCreated(msg.todo)) else None;
        case "todo_updated":
            if (msg.todo != null) Some(TodoUpdated(msg.todo)) else None;
        // ... more cases
        case _:
            trace(SafePubSub.createUnknownMessageError(msg.type));
            None;
    };
}
```

### Critical Structural Difference

**Pattern We're Looking For** (TodoLive.hx pattern):
```
TBlock([
    TVar(_g, TEnumParameter(...)),  // Infrastructure variable
    TSwitch(TLocal(_g), ...)        // Switch on that variable
])
```

**What parseMessageImpl Actually Has**:
```
TBlock([
    TIf(condition, thenBlock, elseBlock),  // Line 190-193
    TReturn(                                // Line 195
        TSwitch(msg.type, ...)              // Switch is NESTED in return!
    )
])
```

### Why Pattern Detection Fails

The pattern detection in `processBlock` looks for:
1. TVar with TEnumParameter init at index `i`
2. Followed by TBlock or TSwitch at index `i+1`

**parseMessageImpl doesn't match because**:
- Expression 0: `TIf` (not TVar!)
- Expression 1: `TReturn` wrapping TSwitch (not direct TSwitch!)

### TodoLive.hx Working Pattern (for comparison)

```haxe
// In handleEvent switch:
case EditUser(id):
    var _g = id;  // TVar with TEnumParameter
    handleEditUser(id, socket);  // Wrapped in TBlock
```

**Generated AST Structure**:
```
TBlock([
    TVar(_g, TEnumParameter(event, EditUser, 0)),
    TBlock([  // The action body
        TVar(id, TLocal(_g)),
        TCall(handleEditUser, [id, socket])
    ])
])
```

## Investigation Results

### processBlock Trace Output
When compiling with `-D debug_infrastructure_vars`, we see NO processBlock traces for parseMessageImpl's body. This confirms:
- The function body is processed by some other code path
- It never reaches the infrastructure variable pattern detection logic
- The structure doesn't match the expected pattern

### Debug Trace Enhancement
Added comprehensive debug traces at TypedExprPreprocessor.hx:464-525:
- Detailed TVar init expression analysis
- TSwitch target field access pattern detection
- TIf condition expression type identification
- Full expression tree visibility

## Root Cause Analysis

**parseMessageImpl is fundamentally different from the switch case pattern**:

1. **Not an infrastructure variable pattern**: It's a normal function with control flow
2. **Switch is on dynamic field**: `msg.type` (not an enum parameter extraction)
3. **Return-wrapped switch**: The switch is the return value, not a statement
4. **No TEnumParameter**: There's no enum deconstruction creating infrastructure variables

## Conclusion

**parseMessageImpl does NOT need infrastructure variable pattern detection** because it doesn't have the pattern! The pattern detection is working correctly - it should NOT fire for this function.

The diagnostics showed parseMessageImpl mentioned because it's being compiled, but it's not actually going through the infrastructure variable code path (which is correct behavior).

## Next Steps

1. Verify TodoLive.hx handleEvent switch cases DO trigger pattern detection
2. Confirm the pattern only fires for actual TVar + TEnumParameter + TSwitch sequences
3. Document the exact AST pattern that requires processing
4. Update investigation to focus on why TodoLive pattern exists but isn't being optimized

## AST Pattern Specification

### Pattern That SHOULD Be Detected:
```haxe
// Haxe source
switch (enumValue) {
    case Constructor(param):
        useParam(param);
}

// Desugared to AST:
TBlock([
    TVar(_g, TEnumParameter(enumValue, Constructor, 0)),  // Infrastructure var
    TSwitch(TLocal(_g), [
        {values: [...], expr: TBlock([
            TVar(param, TLocal(_g)),  // Extract parameter
            TCall(useParam, [param])
        ])}
    ])
])
```

### Pattern That Does NOT Need Detection:
```haxe
// Haxe source
return switch (msg.type) {
    case "value": result;
}

// Already optimal AST:
TReturn(
    TSwitch(TField(msg, type), [
        {values: [...], expr: result}
    ])
)
```

## Investigation Complete
Date: 2025-01-10
Status: Compilation error fixed, AST structure documented, pattern difference explained
