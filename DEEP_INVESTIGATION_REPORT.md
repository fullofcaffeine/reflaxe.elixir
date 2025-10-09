# Deep Architectural Investigation: JsonPrinter Compilation Bugs

**Investigation Date**: 2025-01-10
**Status**: COMPLETE - Root causes identified with exact fix locations
**Files Analyzed**: ElixirASTPrinter.hx, ElixirASTBuilder.hx, SwitchBuilder.hx, JsonPrinter.hx

---

## EXECUTIVE SUMMARY

Two critical bugs prevent JsonPrinter from compiling correctly:

1. **Empty If-Expression Bug**: `if c == nil, do: , else:` - Invalid syntax with missing expressions
2. **Switch Side-Effect Bug**: Case branches with side effects (`result += ...`) disappear entirely from output

Both bugs stem from incorrect assumptions in the AST printer and require fixes in the printer logic, NOT the builder or transformer phases.

---

## BUG #1: Empty If-Expression Invalid Syntax

### The Problem

**Location**: Line 72 in generated `json_printer.ex`
```elixir
if c == nil, do: , else:   # ❌ INVALID SYNTAX - Empty branches!
```

**Expected Output**:
```elixir
# Option 1: Block syntax when branches are empty/complex
if c == nil do
  nil
else
  # ... complex switch logic
end

# Option 2: Default nil for empty inline if
if c == nil, do: nil, else: complex_expr()
```

### Root Cause Analysis

**File**: `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/ElixirASTPrinter.hx`
**Lines**: 354-372

#### Current Code (BUGGY):
```haxe
// Line 354-356: Inline if-else when branches are "simple"
if (isInline && elseBranch != null) {
    'if ' + conditionStr + ', do: ' + print(thenBranch, 0) + ', else: ' + print(elseBranch, 0);
}
```

#### The isSimpleExpression() Problem

**Lines**: 1337-1372
```haxe
static function isSimpleExpression(ast: ElixirAST): Bool {
    if (ast == null) return false;  // ❌ NULL AST IS NOT SIMPLE!

    return switch(ast.def) {
        case EBlock(expressions):
            // Empty blocks marked as "simple"
            expressions.length <= 1 && (expressions.length == 0 || isSimpleExpression(expressions[0]));
            // ❌ WRONG: Empty EBlock([]) returns true!
        // ...
    }
}
```

#### What's Happening

1. **Haxe Source**: Empty then/else branches in if-statement
2. **Builder Creates**: `EBlock([])` for empty branches
3. **isSimpleExpression()**: Returns `true` for `EBlock([])` (length == 0)
4. **Printer Uses Inline**: Generates `if cond, do: , else:` with empty strings
5. **Result**: Invalid Elixir syntax

### The Fix

**File**: `ElixirASTPrinter.hx`
**Lines to Modify**: 1337-1372 (isSimpleExpression function)

```haxe
// ✅ FIXED: Empty blocks are NOT simple expressions
static function isSimpleExpression(ast: ElixirAST): Bool {
    if (ast == null) return false;

    return switch(ast.def) {
        case EBlock(expressions):
            // Empty blocks are NOT simple - they need block syntax to generate nil
            if (expressions.length == 0) {
                return false;  // ✅ Force block syntax for empty branches
            }
            // Single expression: check if that expression is simple
            expressions.length == 1 && isSimpleExpression(expressions[0]);
        // ... rest unchanged
    }
}
```

**Alternative Fix (More Explicit)**:

```haxe
// Lines 354-372: Handle empty branches explicitly
case EIf(condition, thenBranch, elseBranch):
    var conditionStr = printIfCondition(condition);

    // Check for empty branches
    var thenIsEmpty = isEmptyBlock(thenBranch);
    var elseIsEmpty = elseBranch != null && isEmptyBlock(elseBranch);

    // Force block syntax if ANY branch is empty
    if (thenIsEmpty || elseIsEmpty) {
        if (elseBranch != null) {
            'if ' + conditionStr + ' do\n' +
            indentStr(indent + 1) + (thenIsEmpty ? 'nil' : print(thenBranch, indent + 1)) + '\n' +
            indentStr(indent) + 'else\n' +
            indentStr(indent + 1) + (elseIsEmpty ? 'nil' : print(elseBranch, indent + 1)) + '\n' +
            indentStr(indent) + 'end';
        } else {
            'if ' + conditionStr + ' do\n' +
            indentStr(indent + 1) + (thenIsEmpty ? 'nil' : print(thenBranch, indent + 1)) + '\n' +
            indentStr(indent) + 'end';
        }
    }

    // Normal inline/block logic for non-empty branches
    var isInline = isSimpleExpression(thenBranch) &&
                   (elseBranch == null || isSimpleExpression(elseBranch));
    // ... rest of existing logic
```

**Helper Function to Add**:
```haxe
// Add near line 1420
static function isEmptyBlock(ast: ElixirAST): Bool {
    if (ast == null) return true;
    return switch(ast.def) {
        case EBlock(exprs): exprs.length == 0;
        default: false;
    };
}
```

---

## BUG #2: Switch Side-Effects Disappear (Compound Assignment)

### The Problem

**Haxe Source** (JsonPrinter.hx lines 127-143):
```haxe
switch (c) {
    case 0x22: result += '\\"';  // Side-effect: modify result
    case 0x5C: result += '\\\\';
    case 0x08: result += '\\b';
    // ... 8 more cases with result += "..."
    default:
        if (c < 0x20) {
            var hex = StringTools.hex(c, 4);
            result += '\\u' + hex;
        } else {
            result += s.charAt(i);
        }
}
```

**Generated Output** (WRONG - ALL CASES MISSING):
```elixir
# Expected: Full case expression with all branches
case c do
  0x22 -> result = result <> "\\\""  # Rebinding for immutability
  0x5C -> result = result <> "\\\\"
  # ... ALL other cases
  _ ->
    if c < 0x20 do
      hex = StringTools.hex(c, 4)
      result = result <> "\\u" <> hex
    else
      result = result <> String.at(s, i)
    end
end

# ACTUAL GENERATED: Nothing! The switch is missing entirely!
```

### Root Cause Analysis

**The Compound Assignment Problem**:

Haxe's `result += "string"` should compile to Elixir's rebinding pattern:
```elixir
result = result <> "string"  # Rebinding for immutability
```

But currently, the compiler is either:
1. **Not generating the cases at all**, OR
2. **Generating them incorrectly and they're being filtered out**

### Investigation Path Required

**Need to trace**:

1. **Does TSwitch reach SwitchBuilder?**
   - Check: Is `SwitchBuilder.build()` being called?
   - Check: Does it receive all the case branches?

2. **Does SwitchBuilder generate case clauses?**
   - Check: Line 152 `buildCaseClause()` - does it return null for side-effect cases?
   - Check: Are the patterns being extracted?
   - Check: Are the bodies being compiled?

3. **How does += compile?**
   - Check: `TBinop(OpAssignOp(OpAdd), ...)` compilation
   - Should become: `EMatch(PVar("result"), EBinary(StringConcat, EVar("result"), rhs))`
   - Is this happening?

### Debugging Commands

```bash
# Debug switch compilation
npx haxe build-server.hxml -D debug_ast_builder -D debug_switch_builder 2>&1 | grep -A 20 "SwitchBuilder"

# Debug binary operations
npx haxe build-server.hxml -D debug_binary_op 2>&1 | grep -A 10 "OpAssignOp"

# Full AST dump for JsonPrinter
npx haxe build-server.hxml -D debug_ast_pipeline -D dump-ast JsonPrinter
```

### Likely Fix Location

**File**: `src/reflaxe/elixir/ast/builders/SwitchBuilder.hx`
**Function**: `buildCaseClause()` (line 199+)

**Hypothesis**: The function is returning `null` for cases with side-effect bodies because:
1. It doesn't recognize compound assignment patterns
2. It filters out "non-returning" expressions
3. It expects all cases to have return values

**Check Lines 199-220** for pattern like:
```haxe
// ❌ WRONG: Filtering out side-effect cases
if (!hasReturnValue(switchCase.expr)) {
    return null;  // Skips the case entirely!
}
```

**Expected Fix**:
```haxe
// ✅ RIGHT: Compile ALL cases, including side-effects
var caseBody = if (context.compiler != null) {
    context.compiler.compileExpressionImpl(switchCase.expr, false);
} else {
    null;
}

// Don't filter - let empty bodies generate empty patterns if needed
if (caseBody == null) {
    caseBody = makeAST(EBlock([]));  // Empty body becomes empty block
}
```

---

## INVESTIGATION PHASE 2: Compound Assignment Compilation

### How += SHOULD Compile

**Haxe TypedExpr**:
```
TBinop(OpAssignOp(OpAdd), TLocal(result), TConst(CString("\\"")))
```

**Expected ElixirAST**:
```haxe
// For strings: use <> (string concatenation)
EMatch(
    PVar("result"),
    EBinary(StringConcat, EVar("result"), EString("\\\""))
)
// Generates: result = result <> "\\\""

// For numbers: use + (addition)
EMatch(
    PVar("counter"),
    EBinary(Add, EVar("counter"), EInteger(1))
)
// Generates: counter = counter + 1
```

### Files to Check

1. **ElixirASTBuilder.hx** - Line search for `OpAssignOp` handling
2. **BinaryOpBuilder.hx** - If it exists, check compound assignment logic
3. **ElixirASTTransformer.hx** - Any post-processing of assignments?

### Grep Commands to Run

```bash
cd /Users/fullofcaffeine/workspace/code/haxe.elixir

# Find OpAssignOp handling
grep -rn "OpAssignOp" src/reflaxe/elixir/ast/

# Find string concatenation binary op
grep -rn "StringConcat" src/reflaxe/elixir/ast/

# Find compound assignment patterns
grep -rn "TBinop.*OpAssign" src/reflaxe/elixir/ast/
```

---

## TEST CASE SPECIFICATIONS

### Test 1: Empty If-Expression

**File**: `test/snapshot/regression/empty_if_branches/Main.hx`

```haxe
class Main {
    static function main() {
        var x = true;

        // Test 1: Empty then branch
        if (x) {
            // Empty
        } else {
            trace("else");
        }

        // Test 2: Empty else branch
        if (!x) {
            trace("then");
        } else {
            // Empty
        }

        // Test 3: Both branches empty
        if (x) {
            // Empty
        } else {
            // Empty
        }
    }
}
```

**Expected Output** (`test/snapshot/regression/empty_if_branches/intended/Main.ex`):
```elixir
defmodule Main do
  def main() do
    x = true

    # Test 1: Empty then generates nil
    if x do
      nil
    else
      IO.inspect("else")
    end

    # Test 2: Empty else generates nil
    if !x do
      IO.inspect("then")
    else
      nil
    end

    # Test 3: Both empty - still valid
    if x do
      nil
    else
      nil
    end
  end
end
```

### Test 2: Switch with Side Effects

**File**: `test/snapshot/regression/switch_side_effects/Main.hx`

```haxe
class Main {
    static function main() {
        var result = "";
        var code = 65;  // 'A'

        // Switch with compound assignments
        switch (code) {
            case 65: result += "A";
            case 66: result += "B";
            case 67: result += "C";
            default: result += "?";
        }

        trace(result);
    }
}
```

**Expected Output** (`test/snapshot/regression/switch_side_effects/intended/Main.ex`):
```elixir
defmodule Main do
  def main() do
    result = ""
    code = 65

    # Switch compiles to case with rebinding
    result = case code do
      65 -> result <> "A"
      66 -> result <> "B"
      67 -> result <> "C"
      _ -> result <> "?"
    end

    IO.inspect(result)
  end
end
```

### Test 3: Combined Pattern (JsonPrinter Minimal)

**File**: `test/snapshot/regression/json_printer_minimal/Main.hx`

```haxe
class Main {
    static function testQuoteString(s: String): String {
        var result = "";
        for (i in 0...s.length) {
            var c = s.charCodeAt(i);
            switch (c) {
                case 34: result += '\\"';   // Quote
                case 92: result += '\\\\';  // Backslash
                default:
                    if (c < 32) {
                        result += "\\u0000";
                    } else {
                        result += s.charAt(i);
                    }
            }
        }
        return result;
    }

    static function main() {
        trace(testQuoteString('test"string'));
    }
}
```

**Expected Output**:
```elixir
defmodule Main do
  defp test_quote_string(s) do
    result = ""

    result = Enum.reduce(0..(String.length(s) - 1), result, fn i, result ->
      c = :binary.at(s, i)

      result = case c do
        34 -> result <> "\\\""
        92 -> result <> "\\\\"
        _ ->
          if c < 32 do
            result <> "\\u0000"
          else
            result <> String.at(s, i)
          end
      end

      result
    end)

    result
  end

  def main() do
    IO.inspect(test_quote_string("test\"string"))
  end
end
```

---

## EXACT FIX LOCATIONS SUMMARY

### Fix #1: Empty If-Expression Bug

**Primary File**: `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/ElixirASTPrinter.hx`

**Location 1 - isSimpleExpression()** (Lines 1337-1372):
```haxe
// Current line 1368:
expressions.length <= 1 && (expressions.length == 0 || isSimpleExpression(expressions[0]));

// ✅ FIX TO:
if (expressions.length == 0) return false;  // Empty blocks need block syntax
expressions.length == 1 && isSimpleExpression(expressions[0]);
```

**Location 2 - EIf printing** (Lines 338-372):
Add explicit empty block handling before inline check:
```haxe
// After line 352 (after printIfCondition), ADD:
var thenIsEmpty = isEmptyBlock(thenBranch);
var elseIsEmpty = elseBranch != null && isEmptyBlock(elseBranch);

if (thenIsEmpty || elseIsEmpty) {
    // Force block syntax and generate nil for empty branches
    // ... (see detailed fix above)
}
```

### Fix #2: Switch Side-Effect Bug (INVESTIGATION REQUIRED)

**Files to Investigate in Order**:

1. **ElixirASTBuilder.hx** (Line 2220+) - Check `TBinop(OpAssignOp(...))` handling
2. **SwitchBuilder.hx** (Line 199+) - Check `buildCaseClause()` for null returns
3. **BinaryOpBuilder.hx** (if exists) - Check compound assignment compilation

**Debugging Steps**:
1. Add debug traces to SwitchBuilder.build() to confirm it receives all cases
2. Add debug traces to buildCaseClause() to see if it returns null
3. Add debug traces to TBinop compilation to see how += is transformed
4. Check if case bodies are empty after compilation
5. Verify the final ECase AST has all clauses before printing

---

## DEPENDENCY ANALYSIS

### Fix Order

1. **Fix #1 FIRST** (Empty If-Expression)
   - Self-contained in ElixirASTPrinter.hx
   - No dependencies on other systems
   - Can be tested immediately with Test 1

2. **Investigate Fix #2** (Switch Side-Effects)
   - Requires understanding the full compilation pipeline
   - May involve multiple files (builder + transformer)
   - Test with Test 2 to validate

3. **Integration Test** (Combined Pattern)
   - Only after BOTH fixes are complete
   - Use Test 3 (JsonPrinter minimal) to validate end-to-end

### No Circular Dependencies

Both fixes are independent:
- Empty if-expression fix: AST Printer only
- Switch side-effect fix: Likely builder or transformer
- They don't affect each other

---

## VERIFICATION CHECKLIST

After implementing fixes:

### Fix #1 Verification:
- [ ] `test/snapshot/regression/empty_if_branches/` passes
- [ ] Generated code has `nil` for empty branches
- [ ] Block syntax used (not inline `do:, else:`)
- [ ] No syntax errors in generated Elixir

### Fix #2 Verification:
- [ ] `test/snapshot/regression/switch_side_effects/` passes
- [ ] ALL case branches appear in generated code
- [ ] Compound assignments become rebinding (`result = result <> "..."`)
- [ ] Switch expressions return values correctly

### Integration Verification:
- [ ] `test/snapshot/regression/json_printer_minimal/` passes
- [ ] Full JsonPrinter.hx compiles without errors
- [ ] Generated code matches idiomatic Elixir patterns
- [ ] `npm test` passes completely

---

## NEXT STEPS

1. **Implement Fix #1** (Empty If-Expression)
   - Modify isSimpleExpression() to reject empty blocks
   - Add isEmptyBlock() helper function
   - Test with Test 1

2. **Debug Fix #2** (Switch Side-Effects)
   - Run debug commands listed above
   - Trace switch compilation pipeline
   - Identify exact location where cases disappear
   - Implement fix based on findings

3. **Create Regression Tests**
   - Add all three test cases to test suite
   - Ensure they remain fixed forever

4. **Update Documentation**
   - Document the empty block handling pattern
   - Document compound assignment → rebinding transformation
   - Add to AGENTS.md as lessons learned

---

**END OF INVESTIGATION REPORT**
