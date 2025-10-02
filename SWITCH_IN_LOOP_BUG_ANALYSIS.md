# Bug #2: Switch Cases Disappear Inside Loops - Analysis

**Date**: 2025-10-01
**Status**: ❌ **NOT FIXED** - Do-while fix does not resolve this issue
**Related**: Bug #1 (do-while) was fixed, but this is a **separate bug**

---

## Test Results

### ✅ What Works
1. **testSwitchWithoutLoop**: Switch outside loop generates correct case expression
2. **testSwitchWithSimpleAssignment**: Simple assignments work
3. **testMixedOperations**: Arithmetic operations work
4. **testNestedSwitch**: Nested switches work correctly

### ❌ What Still Fails
**testSwitchInsideLoop**: Switch with compound assignments **inside a for loop**

---

## The Problem

### Haxe Input (Main.hx lines 22-40)
```haxe
for (i in 0...input.length) {
    var charCode = input.charCodeAt(i);

    switch (charCode) {
        case 0x22: result += '\\"';   // Should generate case branch
        case 0x5C: result += '\\\\';  // Should generate case branch
        case 0x08: result += '\\b';   // Should generate case branch
        case 0x0C: result += '\\f';   // Should generate case branch
        case 0x0A: result += '\\n';   // Should generate case branch
        case 0x0D: result += '\\r';   // Should generate case branch
        case 0x09: result += '\\t';   // Should generate case branch
        default:
            if (charCode < 0x20) {
                result += '\\u0000';
            } else {
                result += input.charAt(i);
            }
    }
}
```

### Generated Elixir (WRONG - Empty Branches)
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {input, result}, fn _, {input, result} ->
  if 0 < length(input) do
    i = 1
    result2 = :binary.at(input, i)
    char_code = if result2 == nil, do: nil, else: result2
    if char_code == nil do
      # EMPTY - All case branches DISAPPEARED!
    else
      # EMPTY - All case branches DISAPPEARED!
    end
    {:cont, {input, result}}
  else
    {:halt, {input, result}}
  end
end)
```

### Expected Elixir (What Should Be Generated)
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {input, result}, fn _, {input, result} ->
  if 0 < length(input) do
    i = 1
    char_code = :binary.at(input, i)
    result = case char_code do
      0x22 -> result <> "\\\""     # Rebinding pattern
      0x5C -> result <> "\\\\"
      0x08 -> result <> "\\b"
      0x0C -> result <> "\\f"
      0x0A -> result <> "\\n"
      0x0D -> result <> "\\r"
      0x09 -> result <> "\\t"
      _ ->
        if char_code < 0x20 do
          result <> "\\u0000"
        else
          result <> String.at(input, i)
        end
    end
    {:cont, {input, result}}
  else
    {:halt, {input, result}}
  end
end)
```

---

## Root Cause Analysis

### Different from Bug #1
- **Bug #1 (do-while)**: Lambda bodies in `Enum.reduce_while` were empty due to ReduceWhileAccumulatorTransform removing if-expressions
- **Bug #2 (switch-in-loop)**: Switch statements are being converted to empty if-else instead of case expressions

### Likely Root Cause
Based on the original investigation notes (SWITCH_CASE_INVESTIGATION.md):

**File**: `src/reflaxe/elixir/ast/builders/SwitchBuilder.hx` line 222

```haxe
// When case body compilation returns null, it's silently replaced with ENil
// This hides the real issue in compound assignment handling
if (caseBody == null) {
    caseBody = makeAST(ENil);  // Silent failure!
}
```

The switch cases are being compiled, but their bodies are returning `null` (compilation failure), which is then silently replaced with `ENil`, resulting in empty branches.

### Why It Only Happens Inside Loops
When a switch is inside a loop:
1. LoopBuilder transforms the loop to `Enum.reduce_while`
2. Variables become part of the accumulator tuple `{input, result}`
3. SwitchBuilder tries to compile case bodies with compound assignments
4. Compound assignments fail to compile properly in loop context
5. Bodies return `null`, get replaced with `ENil`
6. The entire switch collapses to empty if-else

---

## Investigation Path

To fix this bug, we need to:

1. **Trace Switch Compilation**:
   - Add debug traces to SwitchBuilder to see where case bodies fail
   - Check what happens when compiling `result += '\\"'` inside loop context
   - Identify why the compilation returns null

2. **Check Loop Context Handling**:
   - How does SwitchBuilder handle variables that are part of loop accumulator?
   - Does it know about the tuple structure `{input, result}`?
   - Can it generate proper rebinding for accumulated variables?

3. **Fix Compound Assignment in Loop Context**:
   - Ensure switch cases can access loop accumulator variables
   - Generate proper rebinding patterns: `result = result <> "..."`
   - Return updated accumulator from switch expression

4. **Remove Silent Failure**:
   - Don't silently replace null with ENil
   - Either generate proper code or throw error with diagnostic info

---

## Impact

**Currently Blocking**:
- JsonPrinter.quoteString() - Exact pattern that fails
- Any code with switch statements inside loops
- Character/string processing with escaping

**Workaround**:
Convert switch to if-else manually, or move switch outside loop.

---

## Next Steps

1. ❌ **Confirmed**: Do-while fix does **NOT** fix this bug
2. ⏭️ **Required**: Separate investigation of SwitchBuilder + loop context
3. ⏭️ **Add debug traces** to SwitchBuilder similar to LoopBuilder
4. ⏭️ **Identify** where case body compilation fails
5. ⏭️ **Implement** proper compound assignment handling in switch-in-loop context

---

## Related Documentation

- **Original Investigation**: SWITCH_CASE_INVESTIGATION.md
- **Bug #1 Fix**: DO_WHILE_FIX_PROGRESS.md
- **Bug Documentation**: docs/03-compiler-development/EMPTY_IF_EXPRESSION_AND_SWITCH_BUGS_FIX.md
