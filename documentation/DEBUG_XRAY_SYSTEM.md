# XRay Debugging System for Reflaxe.Elixir

> **Status**: Active Development  
> **Purpose**: Systematic compilation debugging infrastructure  
> **Location**: `src/reflaxe/elixir/helpers/DebugHelper.hx`

## Overview

XRay is the debugging infrastructure for Reflaxe.Elixir compiler development. It provides systematic, conditional debugging capabilities for tracing compilation issues without polluting production code.

## Architecture

### Conditional Compilation
All XRay debugging uses conditional compilation flags:
```haxe
#if (debug_compiler || debug_specific_feature)
// Debug code only exists during debug builds
#end
```

### Debug Categories

#### Core System Debug
- `debug_compiler` - General compiler debugging (always available)
- `debug_inline_if` - Inline if-statement generation and completion
- `debug_y_combinator` - Y combinator pattern detection and generation
- `debug_if_expressions` - If-expression compilation decisions

#### Specialized Debug  
- `debug_variable_tracking` - Variable name tracking and renaming
- `debug_map_merge` - Map.merge optimization detection
- `debug_hxx` - HXX template compilation

## Usage Guide

### Basic Debugging
```haxe
// In compiler code
#if debug_inline_if
DebugHelper.debugInlineIf("TIf main path", "Generating inline if-statement", 
                          'Condition: ${cond}', 'Result: ${result}');
#end
```

### Enabling Debug Output
```bash
# Single feature
haxe -D debug_inline_if test/Test.hxml test=feature_name

# Multiple features  
haxe -D debug_inline_if -D debug_y_combinator test/Test.hxml test=feature_name

# All debugging
haxe -D debug_compiler test/Test.hxml test=feature_name
```

## Current Debug Methods

### `debugInlineIf(context, stage, condition, result)`
**Purpose**: Track inline if-statement generation across compilation paths  
**Critical For**: Y combinator syntax errors, missing `, else: nil` completions  
**Example Output**:
```
[DEBUG:INLINE_IF] ============================================
Context: TIf main path
Stage: Generating inline if-statement  
Condition: (config != nil)
Result: if (config != nil), do: _g_1 = 0, else: nil
[DEBUG:END] ==================================================
```

### `debugYCombinator(context, stage, details)`
**Purpose**: Debug Y combinator generation and syntax issues  
**Critical For**: Loop pattern optimization, syntax error resolution

### `debugIfExpression(context, decision, reason, result)` 
**Purpose**: Debug if-expression compilation decisions  
**Critical For**: Inline vs block syntax decisions

## Development Workflow

### 1. Identify Issue
- Determine which compilation stage has the problem
- Choose appropriate debug category

### 2. Add Debug Points
```haxe
#if debug_your_feature
DebugHelper.debugYourFeature("Context", "Stage", "Details");
#end
```

### 3. Run with Debug
```bash
haxe -D debug_your_feature test/Test.hxml test=problem_test
```

### 4. Analyze Output
- Look for patterns in debug traces
- Identify where compilation deviates from expected behavior

### 5. Fix and Verify
- Apply fix to compiler source
- Re-run with debug to confirm resolution
- Clean up debug code (or keep if generally useful)

## XRay Integration Points

### ElixirCompiler.hx
- **TIf cases**: Inline if-statement generation (lines 2649-2651, 7071-7073)  
- **TBlock cases**: Statement concatenation and joining
- **Expression compilation**: All major expression compilation paths

### Specialized Compilers
- **HxxCompiler.hx**: Template compilation debugging
- **RouterCompiler.hx**: Route compilation debugging  
- **ClassCompiler.hx**: Class generation debugging

## Best Practices

### DO:
- Use conditional compilation for all debug code
- Provide meaningful context and stage information
- Keep debug methods in DebugHelper.hx
- Document new debug categories here

### DON'T:
- Add raw `trace()` statements to compiler code
- Leave debug code uncommented in production
- Create debug methods outside the DebugHelper infrastructure
- Forget to update this documentation when adding new debug features

## Troubleshooting Common Issues

### Y Combinator Syntax Errors
```bash
haxe -D debug_inline_if -D debug_y_combinator test/Test.hxml test=type_safe_child_specs
```
Look for:
- Incomplete inline if-statements
- Missing `, else: nil` completions  
- Statement concatenation issues

### Variable Renaming Issues
```bash
haxe -D debug_variable_tracking test/Test.hxml test=problematic_test
```
Look for:
- Variable shadowing
- Incorrect renaming logic
- Missing variable mappings

## Future Enhancements

### Planned Features
- **JSON output mode**: Structured debug data for analysis tools
- **Compilation flow tracking**: Complete AST transformation tracing  
- **Performance profiling**: Compilation time analysis per debug category
- **Visual debugging**: Integration with external debugging tools

### Extension Points
- **New debug categories**: Add to conditional compilation flags
- **Enhanced output formats**: Beyond simple trace statements
- **Integration testing**: Automated debug output validation

## Maintenance

### When Adding New Debug Categories
1. Add conditional compilation flag (`debug_new_feature`)
2. Create debug method in DebugHelper.hx
3. Add usage examples to this documentation
4. Update compilation instructions

### When Modifying Existing Debug
1. Update method signatures in DebugHelper.hx
2. Update all usage sites in compiler code
3. Update documentation examples
4. Test with affected debug categories

---

**Remember**: XRay is development infrastructure. Keep it clean, documented, and systematically organized for maximum debugging effectiveness.