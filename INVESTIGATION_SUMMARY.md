# Investigation Summary: Undefined Variable 'g' Bug

**Status**: Investigation Complete ✅
**Priority**: P0 - Critical (Blocks TodoApp)
**Estimated Fix Time**: 4-6 hours

---

## Quick Summary

The "undefined variable 'g'" error is **NOT** in TodoPubSub as initially reported. It's actually in **`string_tools.ex` line 54** - a standard library file generated from `StringTools.hx`.

### The Real Problem

**Do-while loops with compound assignments are generating EMPTY loop bodies**, causing all the actual loop logic to disappear.

### Example of the Bug

**Haxe Source** (`std/StringTools.cross.hx`):
```haxe
do {
    s = hexChars.charAt(n & 15) + s;  // Compound assignment
    n >>>= 4;
} while (n > 0);
```

**Generated Elixir** (BROKEN):
```elixir
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, s}, fn _, {n, s} ->  end)
#                                                                                  ^^^ EMPTY!
```

**What Should Be Generated** (CORRECT):
```elixir
Enum.reduce_while(..., fn _, {n, s} ->
  char = String.at(hex_chars, rem(n, 16))
  s = char <> s
  n = n >>> 4
  if n > 0, do: {:cont, {n, s}}, else: {:halt, {n, s}}
end)
```

---

## Root Cause

This is a **known architectural issue** already documented in the codebase:

From `/src/reflaxe/elixir/ast/AGENTS.md`:
> **⚠️ KNOWN ISSUE: Switch Side-Effects in Loops (October 2025)**
>
> **Problem**: Switch statements with compound assignments inside loops have their case branches completely disappear.
>
> **Root Cause**: Pipeline coordination issue between LoopBuilder and other AST components.

The problem affects:
- Do-while loops with compound assignments
- While loops with string building patterns
- Any loop where the body contains rebinding operations

---

## Why This is Critical

1. **Blocks TodoApp**: Cannot compile at all
2. **Affects Standard Library**: StringTools.hex() is broken
3. **No Workaround**: Must fix the compiler
4. **Widespread Pattern**: Any string building in loops fails

---

## Recommended Fix Approach

### Investigation Steps (30 minutes)

1. Add debug tracing to `LoopBuilder.hx`:
```haxe
#if debug_loop_compilation
trace('[LoopBuilder] Building do-while loop');
trace('[LoopBuilder] Body expr: ${bodyExpr.expr}');
trace('[LoopBuilder] Body AST: ${bodyAST}');
#end
```

2. Compile StringTools.hex with debug flag:
```bash
npx haxe build.hxml -D debug_loop_compilation -D debug_ast_builder
```

3. Identify where loop body content is lost in the pipeline

### Implementation (2-4 hours)

Based on debug findings, fix one of:
- **LoopBuilder**: Ensure do-while body is fully captured
- **ElixirASTBuilder**: Verify TWhile compilation processes body
- **ElixirASTTransformer**: Confirm loop transformations preserve body

### Testing (1 hour)

1. Create regression test: `test/snapshot/regression/DoWhileCompoundAssignment/`
2. Verify StringTools.hex compiles correctly
3. Run full test suite: `npm test`
4. Test TodoApp: `cd examples/todo-app && npx haxe build-server.hxml && mix compile`

---

## Files to Check

### Primary Suspects:
- `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/builders/LoopBuilder.hx`
- `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/ElixirASTBuilder.hx`
- `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/ElixirASTTransformer.hx`

### Affected Files:
- `/Users/fullofcaffeine/workspace/code/haxe.elixir/std/StringTools.cross.hx` (source)
- `/Users/fullofcaffeine/workspace/code/haxe.elixir/examples/todo-app/lib/string_tools.ex` (generated, broken)

### Related Documentation:
- `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/AGENTS.md` - Known Issues section
- `/Users/fullofcaffeine/workspace/code/haxe.elixir/docs/03-compiler-development/EMPTY_IF_EXPRESSION_AND_SWITCH_BUGS_FIX.md` - Similar bug patterns

---

## Reference: Related Patterns

This is the SAME architectural issue as "Switch Side-Effects in Loops" but manifesting in do-while loops.

### Working Pattern (outside loops):
```haxe
var s = "";
s = "a" + s;  // Works fine
```

### Failing Pattern (inside loops):
```haxe
do {
    s = hexChars.charAt(n & 15) + s;  // Body disappears!
} while (n > 0);
```

---

## Next Steps

1. **Read**: `UNDEFINED_VARIABLE_G_INVESTIGATION.md` for complete analysis
2. **Debug**: Add traces to LoopBuilder and recompile
3. **Fix**: Based on findings, patch the appropriate builder/transformer
4. **Test**: Create regression test and validate with full suite
5. **Document**: Update AGENTS.md with fix details

---

**Complete Investigation Report**: See `/Users/fullofcaffeine/workspace/code/haxe.elixir/UNDEFINED_VARIABLE_G_INVESTIGATION.md`
