# Array Comprehension Detection Issue - Root Cause Analysis

## Problem Statement

Array comprehensions like `[for (n in [1,2,3,4,5]) n * 2]` are compiled to bare statements instead of idiomatic Elixir comprehensions.

### Current Output (WRONG)
```elixir
doubled = n = 1
[] ++ [n * 2]
n = 2
[] ++ [n * 2]
n = 3
[] ++ [n * 2]
n = 4
[] ++ [n * 2]
n = 5
[] ++ [n * 2]
[]
```

### Expected Output (IDIOMATIC)
```elixir
doubled = for n <- [1, 2, 3, 4, 5], do: n * 2
```

## Root Cause Analysis

### What Haxe Does (Compilation Phase)

Haxe's optimizer **completely unrolls array comprehensions** during optimization. The comprehension:
```haxe
var doubled = [for (n in [1, 2, 3, 4, 5]) n * 2];
```

Becomes (in TypedExpr):
```haxe
var doubled = {
    n = 1;
    [] ++ [n * 2];
    n = 2;
    [] ++ [n * 2];
    ...
    [];
}
```

This means **there is NO TFor expression by the time our compiler sees the code**.

### What Our Compiler Sees (AST Structure)

The actual ElixirAST structure at the transformer phase is:

```
EMatch(
    PVar("doubled"),
    EBlock([
        EBlock([
            EMatch(PVar("n"), EConst(1)),
            EBinary(Concat, EList([]), EList([EBinary(Mult, EVar("n"), EConst(2))]))
        ]),
        EBlock([
            EMatch(PVar("n"), EConst(2)),
            EBinary(Concat, EList([]), EList([EBinary(Mult, EVar("n"), EConst(2))]))
        ]),
        ...
        EList([])
    ])
)
```

**Key Point**: The pattern is NOT at the statement level, it's **inside the RHS of the assignment as nested EBlocks**.

### Why Current Detection Fails

File: `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/transformers/LoopTransforms.hx`
Lines: 835-865

The detection logic at line 853-858 looks for:
```haxe
case EMatch(PVar(_), {def: EMatch(PVar(_), _)}):  // Chained assignment
```

But this pattern would match:
```haxe
doubled = n = 1  // Statement-level chained assignment
```

What we actually have:
```haxe
doubled = <EBlock containing nested blocks>  // Assignment to block
```

The RHS is `EBlock([...])` NOT `EMatch(PVar, ...)`, so the pattern fails immediately at line 861.

### Debug Evidence

From compilation with `-D debug_loop_transforms`:
```
[XRay LoopTransforms] detectComprehensionPattern: Checking from index 7
[XRay LoopTransforms]   First statement type: EMatch(PVar(doubled), {...})
[XRay LoopTransforms]   EMatch pattern: PVar(doubled)
[XRay LoopTransforms]   EMatch RHS type: EBlock([...nested EBlocks...])
[XRay LoopTransforms]   Not a chained assignment, skipping
```

The check `isChainedAssignment` returns `false` because the RHS is `EBlock`, not another `EMatch`.

## The Fix Required

### Step 1: Recognize the Actual Pattern

The comprehension detection needs to handle TWO patterns:

**Pattern A: Statement-level unrolling** (what current code expects)
```haxe
doubled = n = 1;
[] ++ [n * 2];
n = 2;
[] ++ [n * 2];
...
[]
```

**Pattern B: Assignment with unrolled block** (what actually happens)
```haxe
doubled = {
    n = 1;
    [] ++ [n * 2];
    n = 2;
    [] ++ [n * 2];
    ...
    [];
}
```

### Step 2: Detection Algorithm Update

Location: `/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/transformers/LoopTransforms.hx:835-865`

Current code checks for chained assignment. We need to:

1. **Check if the statement is an assignment with a block RHS**:
```haxe
case EMatch(PVar(resultVar), {def: EBlock(blockStmts)}):
    // This is the actual pattern we see
```

2. **Then check if that block contains the unrolled comprehension pattern**:
```haxe
// Look inside blockStmts for:
// - Nested EBlocks, each containing:
//   - EMatch(PVar(loopVar), value)
//   - EBinary(Concat, EList([]), EList([expr]))
// - Final EList([])
```

3. **Extract components**:
   - Result variable: `doubled` (from outer EMatch)
   - Loop variable: `n` (from inner EMatch patterns)
   - Values: `[1, 2, 3, 4, 5]` (from the constants in inner EMatches)
   - Body expression: `n * 2` (from the list concatenation expressions)

### Step 3: Transformation Logic

Once detected, build the idiomatic comprehension:
```haxe
EMatch(
    PVar("doubled"),
    EFor(
        PVar("n"),                           // Loop variable
        EList([EConst(1), ..., EConst(5)]),  // Values
        EBinary(Mult, EVar("n"), EConst(2))  // Body expression
    )
)
```

This generates:
```elixir
doubled = for n <- [1, 2, 3, 4, 5], do: n * 2
```

## Implementation Guidance

### File to Modify
`/Users/fullofcaffeine/workspace/code/haxe.elixir/src/reflaxe/elixir/ast/transformers/LoopTransforms.hx`

### Specific Changes Needed

**Lines 853-858**: Replace chained assignment check with block RHS check:

```haxe
// OLD (incorrect):
var isChainedAssignment = switch(firstStmt.def) {
    case EMatch(PVar(_), {def: EMatch(PVar(_), _)}):
        true;
    default:
        false;
};

// NEW (correct):
var comprehensionPattern = switch(firstStmt.def) {
    case EMatch(PVar(resultVar), {def: EBlock(blockStmts)}):
        // Check if blockStmts contains unrolled comprehension pattern
        detectBlockComprehension(resultVar, blockStmts);
    default:
        null;
};
```

**New Helper Function** (add after line 1000):

```haxe
/**
 * Detect comprehension pattern inside a block assigned to a variable.
 *
 * Pattern: doubled = { n = 1; [] ++ [n*2]; n = 2; [] ++ [n*2]; ...; [] }
 *
 * Returns: {resultVar, loopVar, values, bodyExpr} or null
 */
static function detectBlockComprehension(resultVar: String, stmts: Array<ElixirAST>): Null<ComprehensionInfo> {
    if (stmts.length < 3) return null;  // Need at least 2 iterations + empty list

    var loopVar: String = null;
    var values: Array<ElixirAST> = [];
    var bodyExpr: ElixirAST = null;

    var i = 0;
    while (i < stmts.length - 1) {  // -1 to leave room for final empty list
        var stmt = stmts[i];

        switch(stmt.def) {
            case EBlock(innerStmts) if (innerStmts.length == 2):
                // Each iteration block has 2 statements:
                // 1. n = value
                // 2. [] ++ [expr]

                switch(innerStmts[0].def) {
                    case EMatch(PVar(varName), value):
                        if (loopVar == null) {
                            loopVar = varName;
                        } else if (loopVar != varName) {
                            return null;  // Variable name changed, not a comprehension
                        }
                        values.push(value);
                    default:
                        return null;
                }

                switch(innerStmts[1].def) {
                    case EBinary(Concat, {def: EList([])}, {def: EList([expr])}):
                        if (bodyExpr == null) {
                            bodyExpr = expr;
                        }
                        // TODO: Verify body expression is consistent across iterations
                    default:
                        return null;
                }

            default:
                return null;
        }

        i++;
    }

    // Final statement must be empty list
    if (!switch(stmts[stmts.length - 1].def) {
        case EList([]): true;
        default: false;
    }) {
        return null;
    }

    if (loopVar == null || values.length == 0 || bodyExpr == null) {
        return null;
    }

    return {
        resultVar: resultVar,
        loopVar: loopVar,
        values: values,
        bodyExpr: bodyExpr
    };
}

typedef ComprehensionInfo = {
    var resultVar: String;
    var loopVar: String;
    var values: Array<ElixirAST>;
    var bodyExpr: ElixirAST;
}
```

### Testing the Fix

1. **Compile the test**:
```bash
cd /Users/fullofcaffeine/workspace/code/haxe.elixir/test/snapshot/infrastructure_audit/LoopTransformations
npx haxe compile.hxml
```

2. **Verify output** (should generate):
```elixir
doubled = for n <- [1, 2, 3, 4, 5], do: n * 2
```

3. **Run full test suite**:
```bash
npm test
```

## Key Takeaways

1. **Haxe completely unrolls comprehensions** - No TFor by the time we see the code
2. **The pattern is nested inside an EBlock RHS** - Not a statement-level pattern
3. **Current detection is wrong** - Looking for chained assignment at wrong level
4. **Fix requires pattern detection inside blocks** - Recursive structure analysis
5. **This is a common Haxe optimization** - Other comprehensions likely have same issue

## Next Steps

1. Implement `detectBlockComprehension()` helper
2. Update pattern detection at line 853
3. Test with various comprehension patterns
4. Consider filtered comprehensions (`[for (n in arr) if (cond) n]`)
5. Handle nested comprehensions properly
