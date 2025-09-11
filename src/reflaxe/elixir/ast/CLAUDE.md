# AST Development Context for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) and [/src/reflaxe/elixir/CLAUDE.md](/src/reflaxe/elixir/CLAUDE.md) for project-wide conventions

This file contains AST-specific development guidance for agents working on the Reflaxe.Elixir AST transformation pipeline.

## 🏗️ AST Pipeline Architecture

The AST pipeline is the core of the Reflaxe.Elixir compiler, transforming Haxe's TypedExpr into idiomatic Elixir code through three phases:

1. **Builder Phase** (`ElixirASTBuilder.hx`) - Converts TypedExpr → ElixirAST
2. **Transformer Phase** (`ElixirASTTransformer.hx`) - Applies idiomatic transformations
3. **Printer Phase** (`ElixirASTPrinter.hx`) - Generates final Elixir strings

## 🔍 Known Challenges & Limitations

### Enum Pattern Variable Name Extraction

**STATUS**: Architectural limitation with partial workarounds
**LAST UPDATED**: January 2025
**COMMITS**: 6053a43a, 76b71bd1, 28f8088f

#### The Challenge

When Haxe processes switch cases with enum patterns like `case Ok(email):`, the pattern variable names (like "email") are not directly preserved in the TypedExpr representation. Instead, Haxe generates:

1. **Pattern matching** using integer indices (for optimization)
2. **Temporary variable extraction** using `TEnumParameter` 
3. **Variable assignments** that may be optimized away

**Example Transformation**:
```haxe
// Haxe source
switch(result) {
    case Ok(email):
        trace(email);
}

// Haxe's internal representation (simplified)
switch(elem(result, 0)) {  // Check tag
    case 0:  // Ok constructor index
        _g = elem(result, 1);  // Extract parameter to temp var
        email = _g;            // May be optimized away!
        trace(email);
}
```

#### Current State

The compiler currently generates patterns with generic names:
- `{:ok, g}` instead of `{:ok, email}`
- `{:error, g}` instead of `{:error, reason}`

This is functionally correct but not idiomatic Elixir.

#### Investigation History

**Commit 6053a43a (Sep 2025)**: First attempt to map temp vars to pattern names
- Added `tempVarMapping` to track `_g` → `email` mappings
- Two-pass analysis: find extractions, then find assignments
- Partial success but assignments often optimized away

**Commit 76b71bd1**: Enhanced pattern detection
- Added usage analysis to infer names from method calls
- Still couldn't reliably extract user-specified names

**Current Implementation (Jan 2025)**: 
- `analyzeEnumParameterExtraction()` tries multiple strategies
- `extractPatternVariableNamesFromValues()` attempts to extract from case values
- Falls back to generic names when extraction fails

#### Root Cause

**This is a Haxe TypedExpr limitation, not a bug in our compiler.**

When Haxe compiles switch patterns:
1. Pattern variables are not stored as named entities in `case.values`
2. The TypedExpr only contains the structural pattern (constructor + arity)
3. Variable names exist only in the case body as assignments
4. Haxe's optimizer may remove "unnecessary" assignments

#### Potential Solutions

1. **Accept the Limitation** ✅ (Current approach)
   - Use consistent generic names (`g`, `value`, etc.)
   - Ensure ClauseContext correctly maps variables in case body
   - Document as known limitation

2. **Haxe Compiler Modification** (Long-term)
   - Modify Haxe to preserve pattern variable names in metadata
   - Would require upstream Haxe changes

3. **Source Position Analysis** (Complex)
   - Parse original .hx source using position information
   - Extract pattern variable names from source text
   - Fragile and complex to implement

4. **Metadata Annotations** (User workaround)
   ```haxe
   @:patternVars(["email"])  // Hypothetical annotation
   case Ok(email):
   ```

#### Impact & Workarounds

**Impact**:
- Generated patterns use generic names instead of descriptive ones
- Code is functionally correct but less readable
- Elixir developers may find patterns non-idiomatic

**Current Workaround**:
- ClauseContext system ensures variable references are correct
- Even with `{:ok, g}` pattern, the case body correctly maps variables
- Abstract type methods work correctly through variable mapping

#### Related Code Locations

- `ElixirASTBuilder.hx:4237` - `analyzeEnumParameterExtraction()`
- `ElixirASTBuilder.hx:4190` - `extractPatternVariableNamesFromValues()`
- `ElixirASTBuilder.hx:4341` - `convertIdiomaticEnumPatternWithExtraction()`
- `ElixirASTBuilder.hx:2440` - Switch case processing

## 🔧 ClauseContext Variable Mapping System

**STATUS**: Fixed January 2025
**COMMITS**: (Your recent fix commit hash here)

### The Problem

When enum patterns extract variables with generic names (like `{:ok, g}`), the case body needs to know that references to the original variable names (like `value`) should use the extracted names (like `g`).

### The Solution

The `ClauseContext` class maintains a mapping from Haxe TVar IDs to the actual pattern variable names used in the generated Elixir. This ensures that:
1. Pattern extracts to `{:ok, g}`
2. Abstract type method calls use `g` not undefined `value`
3. All variable references are consistent throughout the case body

### Key Implementation Details

**Location**: `ElixirASTBuilder.hx`

1. **createVariableMappingsForCase()** - Creates the mapping
   - Must use `extractedParams` (actual pattern names like "g")
   - NOT `canonicalNames` (enum definition names like "value")

2. **TCall handling for abstract types** - Lines 1457-1466
   - Checks `currentClauseContext` for mapped names
   - Uses mapped name for first argument to _Impl_ methods

3. **TLocal variable resolution** - Lines 367-373
   - Consults ClauseContext for renamed variables
   - Ensures consistent naming throughout case body

### Example Transformation

**Haxe Input:**
```haxe
switch(emailResult) {
    case Ok(email):
        var domain = email.getDomain();
}
```

**Generated Elixir (with fix):**
```elixir
case email_result do
  {:ok, g} ->
    email = g  # Correctly assigns from g, not undefined value
    domain = Email_Impl_.get_domain(g)  # Uses g, not value
end
```

## 🔍 Enum Pattern Detection Bug (Fixed January 2025)

**STATUS**: Fixed January 2025
**COMMITS**: (Add commit hash after fix)

### The Problem

Regular enums (without `@:elixirIdiomatic` metadata) were incorrectly being treated as idiomatic enums, causing them to go through the wrong pattern extraction path. This resulted in patterns like `RGB(r, g, b)` generating `{:rgb, g, g1, g2}` instead of preserving the user-specified variable names.

### Root Cause

In `ElixirASTBuilder.hx` line 2423, the detection logic was incorrect:
```haxe
// WRONG: Treats ALL enums as idiomatic if type is known
var isIdiomaticEnum = enumType != null;
```

This should have been:
```haxe
// CORRECT: Only treat enums with @:elixirIdiomatic metadata as idiomatic
var isIdiomaticEnum = enumType != null && enumType.meta.has(":elixirIdiomatic");
```

### The Bug's Impact

1. **Regular enums** like `Color` went through `convertIdiomaticEnumPatternWithExtraction`
2. That function uses generic names (`g`, `g1`, `g2`) from temp variable extraction
3. The correct path (`convertPatternWithExtraction`) preserves pattern variable names
4. This affected ALL regular enums, not just Color

### The Fix

Check for the `@:elixirIdiomatic` metadata when determining if an enum should use idiomatic pattern conversion. This ensures:
- Regular enums preserve pattern variable names from the user's code
- Only enums explicitly marked as idiomatic use the generic extraction path
- Abstract type wrapped enums (like `Result<Email>`) continue to work correctly

### Testing

After the fix:
- `Color.RGB(r, g, b)` should generate patterns with `r`, `g`, `b` names
- Abstract types like `Result<Email>` should still use generic names due to Haxe limitations
- All existing enum tests should pass

## 🎯 Development Guidelines

### When Working with Enum Patterns

1. **Don't assume pattern variable names are available** - They're often not
2. **Use ClauseContext for variable mapping** - Ensures correct variable usage in case bodies
3. **Test with multiple enum types** - Result, Option, custom enums
4. **Check for variable consistency** - Ensure extracted vars match usage
5. **Verify abstract type method calls** - They must use the mapped variable names

### Debug Strategies

Enable debug output to understand pattern extraction:
```bash
npx haxe compile.hxml -D debug_ast_builder -D debug_enum
```

### Testing Pattern Extraction

Test cases to verify:
- Simple patterns: `case Ok(value):`
- Multiple parameters: `case Custom(a, b, c):`
- Nested patterns: `case Ok(Some(value)):`
- Unused parameters: `case Ok(_):`
- Mixed usage: `case Custom(used, _unused, used2):`

## 📚 AST Transformation Patterns

### Common Transformation Scenarios

1. **Immutable Operations** - Transform mutations to rebinding
2. **Loop Patterns** - Convert while/for to Enum operations
3. **Pattern Matching** - Generate idiomatic Elixir patterns
4. **Abstract Types** - Route method calls correctly

### Adding New Transformations

When adding AST transformations:
1. **Add to transformer, not builder** - Builder only builds nodes
2. **Use metadata for decisions** - Don't re-detect patterns
3. **Test with todo-app** - Primary integration test
4. **Update snapshot tests** - Capture new behavior

## 🔧 Debugging AST Issues

### Essential Debug Flags

```bash
# All AST debugging
npx haxe compile.hxml -D debug_ast_pipeline

# Specific areas
-D debug_ast_builder      # Builder phase
-D debug_ast_transformer  # Transformation phase  
-D debug_pattern_matching # Pattern generation
-D debug_enum            # Enum pattern extraction
```

### Common AST Problems

1. **Missing transformations** - Check transformer pass order
2. **Incorrect patterns** - Verify extractedParams array
3. **Variable mismatches** - Check ClauseContext mappings
4. **Unused variables** - Verify VariableUsageAnalyzer

## 🚀 Future Improvements

### Planned Enhancements

1. **Better pattern extraction** - Investigate Haxe compiler hooks
2. **Source map integration** - Use positions to read source
3. **Metadata preservation** - Work with Haxe team on preserving names
4. **Pattern library** - Common patterns pre-configured

### Contributing

When working on AST improvements:
1. Document limitations discovered
2. Add debug traces with `#if debug_ast_builder`
3. Update this file with findings
4. Test with real-world code (todo-app)

---

**Remember**: The AST pipeline is the heart of the compiler. Changes here affect all generated code. Test thoroughly with `npm test` and the todo-app before committing.