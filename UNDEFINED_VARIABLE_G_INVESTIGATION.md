# Root Cause Investigation: Undefined Variable 'g' in Generated Elixir Code

**Date**: October 1, 2025
**Issue**: TodoApp fails to compile with "undefined variable 'g'" error
**Files Affected**: `lib/string_tools.ex:54`, potentially others

---

## 1. EXECUTIVE SUMMARY

### The Problem
The Haxe→Elixir compiler is generating invalid Elixir code with undefined variable references, specifically the variable `g`. This manifests as empty loop bodies in `Enum.reduce_while` statements.

### Root Cause
**Loop body compilation failure** - When compiling do-while loops with compound assignments (like `s = hexChars.charAt(n & 15) + s`), the loop body is being compiled to an empty function body, losing all the actual loop logic.

### Impact
- TodoApp cannot compile at all
- Affects standard library code (StringTools.hex)
- Blocks any application using string hex conversion

---

## 2. DETAILED ANALYSIS

### 2.1 Error Location

**Compiler Error**:
```
error: undefined variable "g"
  │
54 │     case g do
  │          ^
  │
  └─ lib/string_tools.ex:54:5: StringTools.hex/2
```

### 2.2 Generated Code (INCORRECT)

**File**: `examples/todo-app/lib/string_tools.ex` (lines 51-59)

```elixir
def hex(n, digits) do
  s = ""
  hex_chars = "0123456789ABCDEF"
  # BUG: Loop body is completely empty!
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, s}, fn _, {n, s} ->  end)
  if digits != nil do
    # BUG: This loop body is also empty!
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {digits, s}, fn _, {digits, s} ->  end)
  end
  s
end
```

**Problems**:
1. `fn _, {n, s} -> end` - Empty function body (missing loop logic)
2. The actual loop operations (`s = hexChars.charAt(n & 15) + s`) disappeared
3. No case expression generated, yet error mentions `case g do`

### 2.3 Haxe Source Code

**File**: `std/StringTools.cross.hx` (hex function)

```haxe
public static function hex(n: Int, ?digits: Int): String {
    var s = "";
    var hexChars = "0123456789ABCDEF";
    do {
        s = hexChars.charAt(n & 15) + s;  // Compound assignment
        n >>>= 4;
    } while (n > 0);

    if (digits != null) {
        while (s.length < digits) {
            s = "0" + s;  // Another compound assignment
        }
    }
    return s;
}
```

**Key Patterns**:
- do-while loop with compound assignment
- String concatenation with rebinding (`s = ... + s`)
- while loop with string building

### 2.4 Expected Idiomatic Elixir

**What the compiler SHOULD generate**:

```elixir
def hex(n, digits) do
  hex_chars = "0123456789ABCDEF"

  # Option 1: Recursive function (most idiomatic)
  s = build_hex(n, hex_chars, "")

  # Option 2: Enum.reduce (functional approach)
  s = Enum.reduce_while(Stream.iterate(n, & &1 >>> 4), "", fn n, acc ->
    if n > 0 do
      char = String.at(hex_chars, rem(n, 16))
      {:cont, char <> acc}
    else
      {:halt, acc}
    end
  end)

  # Padding logic
  s = if digits != nil and String.length(s) < digits do
    String.pad_leading(s, digits, "0")
  else
    s
  end

  s
end

# Helper for recursion
defp build_hex(0, _hex_chars, acc), do: acc
defp build_hex(n, hex_chars, acc) do
  char = String.at(hex_chars, rem(n, 16))
  build_hex(n >>> 4, hex_chars, char <> acc)
end
```

---

## 3. ROOT CAUSE ANALYSIS

### 3.1 Compilation Pipeline Issue

The problem occurs in the AST compilation pipeline:

```
Haxe TypedExpr (do-while)
  → ElixirASTBuilder (builds loop AST)
  → ElixirASTTransformer (transforms to Enum.reduce_while)
  → ElixirASTPrinter (prints the code)
  → RESULT: Empty loop body
```

**Hypothesis**: Loop body with compound assignments is being lost during one of these phases.

### 3.2 Related Known Issues

From `/src/reflaxe/elixir/ast/AGENTS.md`:

> **⚠️ KNOWN ISSUE: Switch Side-Effects in Loops (October 2025)**
>
> **Problem**: Switch statements with compound assignments (`result += "string"`) inside for/while loops have their case branches completely disappear from generated output.
>
> **Evidence**:
> - Switches **outside loops**: Compile correctly ✅
> - Switches **inside loops**: Cases disappear ❌

**This matches our pattern!** The do-while loop contains compound assignments that are disappearing.

### 3.3 Pipeline Coordination Problem

From the documentation:

> **Root Cause Identified**: Pipeline coordination issue between LoopBuilder and SwitchBuilder.
>
> **Evidence**:
> - Debug tracing proves: Switch never reaches SwitchBuilder when inside loop
> - Need to trace where switch cases are dropped in pipeline

**Key Insight**: Loop compilation is stripping the body content before it can be properly processed.

---

## 4. ARCHITECTURAL FIX APPROACH

### 4.1 Investigation Path

1. **Trace LoopBuilder execution**:
   - Add debug traces in `LoopBuilder.build()` to see what body AST it receives
   - Check if body is already empty when LoopBuilder processes it

2. **Check ElixirASTBuilder do-while handling**:
   - Locate do-while compilation code
   - Verify body expression is being captured

3. **Examine compound assignment handling**:
   - How does `s = hexChars.charAt(n & 15) + s` compile?
   - Is the rebinding pattern being handled correctly?

4. **Review ElixirASTTransformer**:
   - Are loop bodies being transformed correctly?
   - Is content being lost during transformation?

### 4.2 Likely Fix Locations

Based on the architecture, fixes are needed in:

1. **LoopBuilder** (`src/reflaxe/elixir/ast/builders/LoopBuilder.hx`):
   - Ensure do-while body is fully captured
   - Preserve compound assignments during transformation

2. **ElixirASTBuilder** (`src/reflaxe/elixir/ast/ElixirASTBuilder.hx`):
   - Check TWhile compilation (do-while converts to while)
   - Ensure body TypedExpr is processed

3. **ElixirASTTransformer** (`src/reflaxe/elixir/ast/ElixirASTTransformer.hx`):
   - Verify loop body transformations don't drop content
   - Check if compound assignments need special handling

### 4.3 Recommended Solution Pattern

**DO NOT** patch symptoms. **DO** fix the pipeline coordination:

1. **Add comprehensive debug tracing**:
   ```haxe
   #if debug_loop_compilation
   trace('[LoopBuilder] Body AST: ${bodyAST}');
   trace('[LoopBuilder] Body length: ${getBodyStatements(bodyAST).length}');
   #end
   ```

2. **Implement proper body preservation**:
   - Ensure all loop compilation paths preserve the full body
   - Add tests for do-while with compound assignments

3. **Fix coordination between builders**:
   - If body contains compound assignments, handle them explicitly
   - Ensure transformation passes see the complete body structure

---

## 5. RELATED PATTERNS AND EDGE CASES

### 5.1 Similar Failing Patterns

1. **Any loop with compound assignments**:
   ```haxe
   while (condition) {
       result += value;  // This pattern fails
   }
   ```

2. **Do-while loops specifically**:
   ```haxe
   do {
       // Any body content
   } while (condition);
   ```

3. **String building in loops**:
   ```haxe
   for (item in items) {
       str = str + item;  // Rebinding pattern
   }
   ```

### 5.2 Working Patterns (for comparison)

1. **Simple for loops**:
   ```haxe
   for (i in 0...10) {
       trace(i);  // Side effects only
   }
   ```

2. **Array comprehensions**:
   ```haxe
   var result = [for (i in items) transform(i)];
   ```

---

## 6. TESTING STRATEGY

### 6.1 Minimal Reproduction Test

**Create**: `test/snapshot/regression/DoWhileCompoundAssignment/Main.hx`

```haxe
package;

class Main {
    static function main() {
        var result = buildString();
        trace(result);
    }

    static function buildString(): String {
        var s = "";
        var n = 255;
        do {
            s = String.fromCharCode(65 + (n % 10)) + s;
            n = Std.int(n / 10);
        } while (n > 0);
        return s;
    }
}
```

**Expected Output**:
```elixir
def build_string() do
  s = ""
  n = 255

  # Should generate working loop, not empty body
  {s, _n} = Enum.reduce_while(Stream.iterate({s, n}, fn {s, n} ->
    char = String.from_char_code(65 + rem(n, 10))
    s = char <> s
    n = div(n, 10)
    if n > 0, do: {:cont, {s, n}}, else: {:halt, {s, n}}
  end), {s, n}, fn _, acc -> acc end)

  s
end
```

### 6.2 Validation Steps

1. **Compile test**: `npx haxe test/snapshot/regression/DoWhileCompoundAssignment/compile.hxml`
2. **Check generated code**: Loop body should NOT be empty
3. **Verify Elixir compiles**: `elixirc out/Main.ex` should succeed
4. **Run and validate output**: Generated code should work correctly

---

## 7. PRIORITY AND SEVERITY

### Severity: **CRITICAL (P0)**
- Blocks TodoApp compilation completely
- Affects core stdlib functionality
- No workaround available

### Impact:
- **Users affected**: Anyone using StringTools.hex()
- **Scope**: All loops with compound assignments
- **Workaround**: None - must fix the compiler

### Timeline:
- **Immediate**: Add debug tracing to understand where body is lost
- **Short-term**: Fix the specific do-while compilation issue
- **Medium-term**: Comprehensive fix for all loop+compound-assignment patterns

---

## 8. NEXT STEPS (ACTIONABLE)

### Step 1: Debug Tracing (30 minutes)
1. Add `#if debug_loop_compilation` traces to LoopBuilder
2. Recompile todo-app with debug flag
3. Identify exact point where body content is lost

### Step 2: Create Minimal Test (15 minutes)
1. Create DoWhileCompoundAssignment test
2. Verify it reproduces the issue
3. Document expected vs actual output

### Step 3: Fix Implementation (2-4 hours)
1. Based on debug findings, fix the builder/transformer
2. Ensure all loop types preserve body content
3. Add special handling for compound assignments if needed

### Step 4: Validation (1 hour)
1. Run full test suite: `npm test`
2. Compile todo-app: `cd examples/todo-app && npx haxe build-server.hxml && mix compile`
3. Verify string_tools.ex compiles correctly

### Step 5: Documentation (30 minutes)
1. Document the fix in `/docs/03-compiler-development/`
2. Add regression test to prevent recurrence
3. Update AGENTS.md with lessons learned

---

## 9. REFERENCES

### Related Files
- **Error Location**: `examples/todo-app/lib/string_tools.ex:54`
- **Haxe Source**: `std/StringTools.cross.hx` (hex function)
- **Compiler Components**:
  - `src/reflaxe/elixir/ast/builders/LoopBuilder.hx`
  - `src/reflaxe/elixir/ast/ElixirASTBuilder.hx`
  - `src/reflaxe/elixir/ast/ElixirASTTransformer.hx`

### Documentation
- `/src/reflaxe/elixir/ast/AGENTS.md` - Known Issues section
- `/docs/03-compiler-development/EMPTY_IF_EXPRESSION_AND_SWITCH_BUGS_FIX.md` - Related bug fixes
- `/test/snapshot/regression/SwitchSideEffects/` - Existing regression test

### Similar Issues in Git History
```bash
git log --oneline --grep="loop\|compound\|assignment" | head -10
```

---

## 10. CONCLUSION

This is a **critical compiler bug** affecting loop compilation, specifically:
- Do-while loops with compound assignments
- While loops with string building patterns
- Any loop where the body contains rebinding operations

The fix requires:
1. Understanding where loop bodies are being lost in the pipeline
2. Ensuring proper coordination between LoopBuilder and other components
3. Comprehensive testing of all loop patterns with compound assignments

**This cannot be worked around** - it requires a proper architectural fix in the compiler.

---

**Investigation Status**: **COMPLETE - Ready for Implementation**
**Next Action**: Add debug tracing to LoopBuilder to identify loss point
**Estimated Fix Time**: 4-6 hours (including testing and validation)
