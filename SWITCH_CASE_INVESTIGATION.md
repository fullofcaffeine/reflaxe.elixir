# JsonPrinter Compilation Bug Investigation Report

**Date**: January 2025
**Investigator**: AI Compiler Expert  
**Bug**: Switch case branches with compound assignments disappear from generated output

---

## 1. THE PROBLEM

### Haxe Source Pattern (JsonPrinter.hx lines 127-143):
```haxe
switch (c) {
    case 0x22: result += '\\"';   // Compound assignment
    case 0x5C: result += '\\\\';  // Compound assignment
    case 0x08: result += '\\b';   // Compound assignment
    // ... 10+ more cases
    default:
        if (c < 0x20) {
            result += '\\u' + hex;
        } else {
            result += s.charAt(i);
        }
}
```

### Current Generated Output (json_printer.ex lines 72-76):
```elixir
c = if result2 == nil, do: nil, else: result2
if c == nil do

else

end
```

**THE ENTIRE SWITCH WITH ALL CASE BRANCHES IS MISSING!**

---

## 2. ROOT CAUSE: SwitchBuilder Silent Failure

### File: /Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/builders/SwitchBuilder.hx

### Lines 216-227 - The Critical Code:
```haxe
// Build case body
var body: ElixirAST = if (switchCase.expr != null && context.compiler != null) {
    var result = context.compiler.compileExpressionImpl(switchCase.expr, false);
    if (result != null) {
        result;  // Already an ElixirAST
    } else {
        // ⚠️ CRITICAL: Compilation failed - use nil
        makeAST(ENil);  // LINE 222 - SILENTLY REPLACES FAILED BODIES!
    }
} else {
    // Empty case body - use nil
    makeAST(ENil);
}
```

### THE PROBLEM:
When `context.compiler.compileExpressionImpl(switchCase.expr, false)` returns **null**, the code:
1. **Silently accepts the failure**
2. **Replaces with ENil** (empty body)
3. **Returns the clause** as if nothing went wrong
4. **Result**: All case clauses have empty bodies

---

## 3. WHY COMPILATION RETURNS NULL

### The Compound Assignment Flow

**What SHOULD happen for `result += '\\"'`:**

```
1. SwitchBuilder.buildCaseClause() calls compileExpressionImpl()
2. ElixirASTBuilder receives TBinop(OpAssignOp(OpAdd), TLocal(result), TConst(...))
3. Matches at ElixirASTBuilder.hx:1697 - case OpAssignOp(innerOp)
4. Extracts pattern via PatternBuilder.extractPattern(e1)
5. Builds leftAST and rightAST
6. Creates EMatch(pattern, innerBinop)
7. Returns ElixirAST node
8. SwitchBuilder adds to case clauses
```

**What's ACTUALLY happening:**

One of these steps returns NULL:
- PatternBuilder.extractPattern(TLocal(result)) → null?
- buildFromTypedExpr(e1) → null?
- buildFromTypedExpr(e2) → null?
- BinaryOpBuilder.buildBinopFromAST() → null?

---

## 4. POSSIBLE ROOT CAUSES

### A) PatternBuilder.extractPattern() Failure
```haxe
// If this returns null for TLocal(result):
var pattern = PatternBuilder.extractPattern(e1);
// Then EMatch(null, innerBinop) is invalid
// ElixirASTBuilder might return null
```

### B) Variable Context Issues
```haxe
// The 'result' variable might not be in scope
// Or currentContext might be null/invalid
var leftAST = buildFromTypedExpr(e1, currentContext);
// If currentContext is broken, returns null
```

### C) BinaryOpBuilder Path Error
```haxe
// BinaryOpBuilder.hx:162 throws for OpAssignOp
case OpAssignOp(innerOp):
    throw "OpAssignOp should be handled in ElixirASTBuilder";
```
If the code accidentally calls BinaryOpBuilder instead of going through ElixirASTBuilder's TBinop handler, it throws and returns null.

---

## 5. THE FIX SPECIFICATION

### DO NOT:
- ❌ Add post-processing to filter empty cases
- ❌ Special-case switch statements
- ❌ Work around the symptom
- ❌ Keep the silent nil replacement

### DO:
- ✅ Add debug tracing to find WHERE it fails
- ✅ Fix WHY compilation returns null
- ✅ Fail fast with error messages instead of silent nil
- ✅ Test with minimal case

---

## 6. RECOMMENDED DEBUG APPROACH

### Step 1: Add Tracing to SwitchBuilder.hx (lines 216-227)

```haxe
// Build case body
var body: ElixirAST = if (switchCase.expr != null && context.compiler != null) {
    #if debug_switch_compilation
    trace('[SwitchBuilder] Compiling case body');
    trace('[SwitchBuilder]   Expression type: ${Type.enumConstructor(switchCase.expr.expr)}');
    #end

    var result = context.compiler.compileExpressionImpl(switchCase.expr, false);

    if (result != null) {
        #if debug_switch_compilation
        trace('[SwitchBuilder]   ✓ Compiled successfully');
        #end
        result;
    } else {
        // ⚠️ ERROR: This should NEVER happen!
        #if debug_switch_compilation
        trace('[SwitchBuilder]   ❌ ERROR: Compilation returned NULL!');
        trace('[SwitchBuilder]   Pattern: ${pattern}');
        #end
        Context.error('Switch case body compilation failed', switchCase.expr.pos);
    }
}
```

### Step 2: Compile with Debug Flag

```bash
npx haxe build-server.hxml -D debug_switch_compilation 2>&1 | tee debug.log
```

### Step 3: Find the Exact Failure Point

Look for:
```
[SwitchBuilder] Compiling case body
[SwitchBuilder]   Expression type: TBinop
[SwitchBuilder]   ❌ ERROR: Compilation returned NULL!
```

Then trace backwards to find which builder returned null.

---

## 7. EXPECTED CORRECT OUTPUT

### For the JsonPrinter switch:

```elixir
defp quote_string(struct, s) do
  result = "\""
  # ... loop setup ...
  
  result = case c do
    0x22 -> result <> "\\\""      # Compound assignment
    0x5C -> result <> "\\\\\\\\"  # Compound assignment
    0x08 -> result <> "\\\\b"
    0x0C -> result <> "\\\\f"
    0x0A -> result <> "\\\\n"
    0x0D -> result <> "\\\\r"
    0x09 -> result <> "\\\\t"
    _ -> 
      if c < 0x20 do
        result <> "\\\\u" <> hex
      else
        result <> String.at(s, i)
      end
  end
  
  # ... rest of function
end
```

---

## 8. ARCHITECTURAL INSIGHTS

### Why Silent Failures Are Wrong:

1. **Hides Bugs**: We had no idea compilation was failing
2. **Debugging Nightmare**: No error message, just missing code
3. **Band-Aid Temptation**: Easy to add filters instead of fixing root cause
4. **Violates Fail-Fast**: Should throw error, not continue with broken AST

### The Correct Pattern:

```haxe
// ❌ WRONG: Silent failure
var result = compile(expr);
if (result == null) {
    return makeAST(ENil);  // Sweep under rug
}

// ✅ RIGHT: Fail fast with information
var result = compile(expr);
if (result == null) {
    trace('[ERROR] Compilation failed for: ${expr}');
    Context.error('Cannot compile expression', expr.pos);
}
```

---

## 9. NEXT STEPS FOR IMPLEMENTATION

### For the Main Agent:

1. **Read SwitchBuilder.hx** (lines 199-234)
2. **Add debug tracing** as specified in Step 1
3. **Compile JsonPrinter** with debug flag
4. **Capture the NULL return point**
5. **Fix the builder** that's returning null
6. **Remove the silent nil replacement**
7. **Test with minimal case**
8. **Verify JsonPrinter compiles correctly**

### Test Case:

```haxe
class TestCompoundSwitch {
    static function test() {
        var result = "";
        var c = 0x22;

        switch(c) {
            case 0x22: result += '\\"';
            case 0x5C: result += '\\\\';
            default: result += "x";
        }

        trace(result);
    }
}
```

Expected:
```elixir
result = case c do
  0x22 -> result <> "\\\""
  0x5C -> result <> "\\\\\\\\"
  _ -> result <> "x"
end
```

---

## CONCLUSION

**Root Cause**: SwitchBuilder.buildCaseClause() silently accepts NULL from compilation and replaces with ENil

**Location**: /Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/builders/SwitchBuilder.hx:222

**Why NULL**: Unknown - requires debug tracing to identify

**Fix Strategy**: 
1. Add tracing to find WHERE it fails
2. Fix the builder returning null
3. Replace silent failure with error throwing

**DO NOT**: Add band-aid fixes or post-processing filters

---

**Investigation Status**: Complete - Root cause identified, debug approach specified
