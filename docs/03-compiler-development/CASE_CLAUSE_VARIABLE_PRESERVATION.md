# Case Clause Variable Preservation Issue

## Problem Description

The `assignmentExtractionPass` was dropping variable declarations in case clause bodies, causing undefined variable errors in generated Elixir code.

### Example of the Bug

**Haxe Input:**
```haxe
case result {
    Error(changeset):
        var errors = changeset.traverseErrors();
        throw 'Changeset validation failed: $errors';
}
```

**Generated Elixir (Before Fix):**
```elixir
case result do
  {:error, reason} ->
    # Variable declaration was dropped!
    throw("Changeset validation failed: " <> errors)  # ERROR: undefined variable 'errors'
end
```

**Generated Elixir (After Fix):**
```elixir
case result do
  {:error, reason} ->
    errors = "test_error"  # Variable declaration preserved
    throw("Changeset validation failed: " <> errors)  # Works!
end
```

## Root Cause Analysis

### The Assignment Extraction Pass

The `assignmentExtractionPass` is designed to extract variable assignments from expression contexts where Elixir doesn't allow them. For example:

```haxe
// Haxe allows assignments in expressions
var result = (var x = compute(); x * 2);

// Elixir doesn't, so we extract:
x = compute()
result = x * 2
```

### The Problem: Context Confusion

The pass was treating ALL 2-statement blocks `EBlock([EMatch, expr])` the same way:
1. Extract the assignment (EMatch)
2. Return only the expression
3. Hoist the assignment to an outer scope

This works in expression contexts but is wrong for statement contexts like case clause bodies.

### Expression vs Statement Contexts

**Expression Contexts** (extraction needed):
- Function arguments: `foo(var x = 5; x)`
- Map values: `{key: (var x = 5; x)}`
- Binary operations: `(var x = 5; x) + y`

**Statement Contexts** (preserve declarations):
- Case clause bodies ✅ (fixed)
- Function bodies ⚠️ (needs fix)
- Try/rescue blocks ⚠️ (needs fix)
- With do-blocks ⚠️ (needs fix)

## The Fix

### Immediate Solution (Implemented)

Special-case ECase nodes to prevent extraction in their clause bodies:

```haxe
static function transformAssignments(node: ElixirAST): ElixirAST {
    switch(node.def) {
        case ECase(expr, clauses):
            // Special handling to preserve clause body statements
            var transformedExpr = transformAssignments(expr);
            var transformedClauses = [];
            for (clause in clauses) {
                var transformedBody = transformClauseBody(clause.body);  // Preserves all statements
                transformedClauses.push({
                    pattern: clause.pattern,
                    guard: clause.guard != null ? transformAssignments(clause.guard) : null,
                    body: transformedBody
                });
            }
            return makeASTWithMeta(ECase(transformedExpr, transformedClauses), node.metadata, node.pos);
            
        default:
            // Standard recursive transformation
    }
}

static function transformClauseBody(body: ElixirAST): ElixirAST {
    switch(body.def) {
        case EBlock(statements):
            // Preserve ALL statements in the block
            var transformedStatements = [];
            for (stmt in statements) {
                transformedStatements.push(transformClauseBody(stmt));
            }
            return makeASTWithMeta(EBlock(transformedStatements), body.metadata, body.pos);
            
        default:
            // Recurse but don't extract
            return ElixirASTTransformer.transformAST(body, transformAssignments);
    }
}
```

### Recommended Long-term Solution (From Codex Review)

Implement a mode-based traversal system:

```haxe
enum TraversalMode {
    Expression;  // Allow extraction (function args, map values)
    Statement;   // Preserve declarations (clause bodies, function bodies)
    Guard;       // Disallow all extraction (case guards must be pure)
}

static function transformAssignments(node: ElixirAST, mode: TraversalMode): ElixirAST {
    switch(mode) {
        case Expression:
            // Current extraction logic
        case Statement:
            // Preserve all declarations
        case Guard:
            // Error if extraction attempted
    }
}
```

## Remaining Issues

### Other Statement Contexts Need Fixing

1. **Function bodies** (`fn` and `def`)
2. **Try/rescue/after blocks**
3. **With do-blocks**
4. **Receive/after blocks**
5. **For comprehension bodies**

### Nested Context Leakage

The current fix only handles direct EBlock in case clauses. Nested blocks inside if/cond within the clause could still trigger extraction.

## Testing Requirements

### Regression Test Added
- `test/tests/CaseClauseVariableDeclarations/` - Tests variable declarations in case clauses

### Additional Tests Needed
1. **Nested blocks**: `case x { ... -> if (cond) { var e = f(); g(e) } }`
2. **Guard safety**: Ensure guards never have extraction
3. **Other constructs**: fn, try, with bodies
4. **Expression contexts**: Verify extraction still works where needed

## Debugging This Issue

### How to Identify Similar Problems

1. **Symptom**: Undefined variable errors in generated Elixir
2. **Pattern**: Variable declared at start of a block, used later
3. **Location**: Inside case/fn/try/with bodies

### Debug Flags
```bash
# Enable assignment extraction debugging
npx haxe build.hxml -D debug_assignment_extraction

# Look for these patterns in output:
# - "Found assignment in block - extracting" (wrong in statement contexts)
# - "Block is in statement context - preserving all" (correct)
```

### Key Files
- `src/reflaxe/elixir/ast/transformers/AssignmentExtractionTransforms.hx` - The pass
- `src/reflaxe/elixir/ast/ElixirASTTransformer.hx` - Pass orchestration

## Lessons Learned

1. **Context matters**: Expression vs statement contexts require different handling
2. **Recursive transformations need context tracking**: Can't just blindly apply the same transformation everywhere
3. **Test statement contexts explicitly**: Easy to miss because expressions are more common
4. **Codex consultation valuable**: Identified architectural improvements and edge cases

## Related Issues

- Variable renaming in case clauses (alpha-renaming)
- Temp-binding collapse optimization
- InlineTempBindingInExprPass context awareness

## References

- Commit: d126391b - "fix(ast): preserve variable declarations in case clause bodies"
- Related: InlineTempBindingInExprPass also needed context awareness
- Codex review suggested mode-based traversal for robustness