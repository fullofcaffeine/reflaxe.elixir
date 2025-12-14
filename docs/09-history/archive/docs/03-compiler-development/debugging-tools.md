# Advanced Debugging Tools for Haxe Macro Development

## Overview

When working on the Reflaxe.Elixir compiler, these Haxe eval debugging flags provide crucial visibility into macro execution and compilation processes. These tools are essential for diagnosing complex AST transformation issues and performance bottlenecks.

## Critical Debugging Flags

### 1. **`-D eval-stack`** - Macro Stack Traces

**Purpose**: Enables reliable stack traces during macro execution (disabled by default for performance).

**When to use**:
- Mysterious AST transformation issues 
- Tracking where compiler functions are called
- Understanding Haxe's desugaring vs our compiler's transformations
- Debugging TEnumParameter generation and orphaned variables

**Usage Example**:
```bash
# Get stack traces for enum parameter compilation
npx haxe build-server.hxml -D eval-stack -D debug_enum_introspection_compiler

# Full stack visibility for pattern matching
npx haxe build-server.hxml -D eval-stack -D debug_pattern_matching
```

**What it reveals**:
- Complete call chain when TEnumParameter expressions are created
- Which macro functions are called in what order
- Where Haxe's internal transformations happen vs compiler logic
- Exact location where compilation errors occur

### 2. **`-D eval-times`** - Performance Profiling

**Purpose**: Adds per-function timers to measure compilation performance.

**When to use**:
- Slow compilation issues
- Identifying performance bottlenecks in compiler helpers
- Optimizing compilation time for large projects
- Understanding which patterns take longest to compile

**Usage Example**:
```bash
# Profile compilation performance
npx haxe build-server.hxml -D eval-times

# Combined with debug output for detailed analysis
npx haxe build-server.hxml -D eval-times -D debug_control_flow_compiler
```

**What it reveals**:
- Which compiler functions consume the most time
- Performance impact of different optimization patterns
- Recursive compilation patterns that might be inefficient
- Relative cost of different AST transformations

### 3. **`-D eval-debugger`** - Interactive Debugging

**Purpose**: Provides debugger support for interactive macro debugging.

**When to use**:
- Complex AST transformation issues
- Need to inspect TypedExpr structures at runtime
- Step-through debugging of compiler logic
- Interactive exploration of variable states

**Usage Example**:
```bash
# Enable debugger support
npx haxe build-server.hxml -D eval-debugger

# Combined debugging session
npx haxe build-server.hxml -D eval-debugger -D eval-stack
```

**What it provides**:
- Breakpoint support in compiler code
- Interactive inspection of AST nodes
- Step-by-step macro execution
- Real-time variable state examination

## Specific Use Cases for Our Compiler

### Debugging Orphaned Variables

When dealing with issues like `g_array` orphaned variables in switch cases:

```bash
# Full visibility into enum parameter compilation
npx haxe build-server.hxml \
  -D eval-stack \
  -D debug_enum_introspection_compiler \
  -D debug_pattern_matching \
  -D debug_expression_variants
```

This combination shows:
1. **eval-stack**: Where TEnumParameter expressions are created
2. **debug_enum_introspection_compiler**: Parameter extraction decisions
3. **debug_pattern_matching**: Switch case compilation flow
4. **debug_expression_variants**: Pre-analysis of case bodies

### Performance Analysis

For optimizing compilation speed:

```bash
# Profile specific compiler components
npx haxe build-server.hxml \
  -D eval-times \
  -D debug_loops \
  -D debug_control_flow_compiler
```

### Complex AST Issues

For mysterious transformation problems:

```bash
# Maximum debugging visibility
npx haxe build-server.hxml \
  -D eval-stack \
  -D eval-debugger \
  -D debug_expression_dispatcher \
  -D debug_variable_compiler
```

## Integration with Our Debug System

These flags complement our existing XRay debug infrastructure:

### Combined Usage Pattern
```bash
# Our XRay traces + Haxe eval debugging
npx haxe build-server.hxml \
  -D eval-stack \
  -D eval-times \
  -D debug_enum_introspection_compiler \
  -D debug_pattern_matching
```

### Debugging Workflow
1. **Start with eval-stack**: Understand the call flow
2. **Add eval-times**: Identify performance bottlenecks  
3. **Use specific XRay flags**: Get detailed transformation info
4. **Enable eval-debugger**: For interactive exploration if needed

## Best Practices

### For Development
- **Always use eval-stack** when debugging new compiler features
- **Profile with eval-times** before optimizing for performance
- **Combine with XRay flags** for maximum visibility

### For Bug Reports
When reporting compiler issues, include output from:
```bash
npx haxe build-server.hxml -D eval-stack -D [relevant-debug-flag]
```

### Performance Considerations
- These flags add compilation overhead
- Use only during debugging, not in production
- eval-stack has the highest performance impact
- eval-times has minimal impact and can be used regularly

## Reference

Based on [Haxe eval target documentation](https://haxe.org/blog/eval/) and optimized for Reflaxe.Elixir compiler development patterns.

### Related Documentation
- [XRay Debug System](./COMPREHENSIVE_DOCUMENTATION_STANDARD.md) - Our internal debugging
- [Compiler Architecture](../05-architecture/compiler-architecture.md) - Understanding compilation flow
- [AST Patterns](./AST_CLEANUP_PATTERNS.md) - Common transformation patterns