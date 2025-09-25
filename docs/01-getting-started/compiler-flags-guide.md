# Compiler Flags and Optimization Guide

**Essential compiler flags for Haxe→Elixir compilation and why some optimizations should be avoided.**

## ⚠️ Critical: Avoid `-D analyzer-optimize` 

**FUNDAMENTAL RULE: Do NOT use `-D analyzer-optimize` when compiling to Elixir.**

### Why This Flag is Problematic

The `-D analyzer-optimize` flag enables Haxe's aggressive optimization passes designed for imperative, performance-oriented targets like C++ and JavaScript. These optimizations actively harm the quality of generated Elixir code:

#### 1. Loop Unrolling Destroys Functional Patterns
```haxe
// Haxe source
for (i in 0...3) {
    trace('Item: ' + i);
}

// With -D analyzer-optimize (BAD)
Log.trace("Item: 0", ...)
Log.trace("Item: 1", ...)  
Log.trace("Item: 2", ...)

// Without -D analyzer-optimize (GOOD)
Enum.each(0..2, fn i -> 
  Log.trace("Item: #{i}", ...)
end)
```

#### 2. Constant Folding Eliminates Runtime Expressions
```haxe
// Haxe source
for (n in 0...3) {
    trace('Result: ' + (n * 2));
}

// With -D analyzer-optimize (BAD)
Log.trace("Result: 0", ...)
Log.trace("Result: 2", ...)
Log.trace("Result: 4", ...)

// Without -D analyzer-optimize (GOOD - preserves calculation)
Enum.each(0..2, fn n ->
  Log.trace("Result: #{n * 2}", ...)
end)
```

### Philosophical Mismatch

**Haxe's optimizer** targets:
- **Machine performance**: Fewer CPU cycles, less memory
- **Imperative patterns**: Loop unrolling, inlining
- **Compile-time evaluation**: Constant folding

**Elixir values**:
- **Code readability**: Human-friendly functional patterns
- **Maintainability**: Clear, idiomatic expressions
- **Runtime flexibility**: Lazy evaluation, hot code reloading

## ✅ Recommended Compiler Configuration

### Basic Configuration
```hxml
# build.hxml - Recommended settings
-cp src_haxe
-main Main
-lib reflaxe
-lib reflaxe.elixir
--no-output
-D elixir_output=lib

# Good optimizations
-dce full                    # Dead code elimination (removes unused code)
-D loop_unroll_max_cost=10   # Reasonable loop unrolling limit

# AVOID these
# -D analyzer-optimize       # NO! Destroys idiomatic patterns
# -D analyzer-check          # May trigger unwanted optimizations
```

### Dead Code Elimination (Recommended)
```hxml
-dce full  # Removes unused classes and functions
```

Dead code elimination (`-dce`) is GOOD because it:
- Removes unused abstract type operators
- Eliminates helper functions that aren't called
- Reduces output size without affecting code quality
- Works at the module level, not expression level

### Debug Flags (Development Only)
```hxml
# Helpful during development
-D debug_ast_pipeline       # See AST transformations
-D debug_pattern_matching   # Debug pattern matching
-D source-map              # Generate source maps
```

## 📊 Flag Impact Comparison

| Flag | Impact on Elixir Output | Recommendation |
|------|------------------------|----------------|
| `-D analyzer-optimize` | Destroys functional patterns, unrolls loops | ❌ **Never use** |
| `-dce full` | Removes unused code cleanly | ✅ **Always use** |
| `-D loop_unroll_max_cost=N` | Controls unrolling threshold | ✅ **Use with low values (10-20)** |
| `-D source-map` | Adds debugging information | ✅ **Use in development** |
| `-D debug_ast_pipeline` | Verbose AST transformation output | 🔧 **Development only** |

## 🎯 Configuration by Use Case

### For Development
```hxml
-dce full
-D loop_unroll_max_cost=10
-D source-map
# Optional: -D debug_ast_pipeline
```

### For Production
```hxml
-dce full
-D loop_unroll_max_cost=10
```

### For Testing
```hxml
-dce full
-D loop_unroll_max_cost=10
# No analyzer-optimize to ensure predictable output
```

## 🔍 Troubleshooting

### "My generated code looks verbose/repetitive"
**Symptom**: Seeing repeated statements instead of loops
**Cause**: Likely using `-D analyzer-optimize`
**Solution**: Remove the flag from your `.hxml` file

### "Arithmetic expressions are being evaluated"
**Symptom**: `n * 2` becomes `0`, `2`, `4` instead of staying as expression
**Cause**: Haxe's constant folding (happens even without analyzer-optimize for compile-time constants)
**Note**: This is a limitation when using literal ranges like `0...3`

### "Abstract type generates many unused functions"
**Symptom**: Date_Impl_ has 140+ lines of unused operator functions
**Solution**: Use `-dce full` to eliminate unused functions

## 📚 Further Reading

- [Development Workflow Guide](development-workflow.md) - Day-to-day development practices
- [Troubleshooting Guide](../06-guides/troubleshooting.md) - Common issues and solutions
- [Architecture Overview](../05-architecture/compilation-pipeline.md) - How the compiler works

## 🎓 Key Takeaway

**For Elixir, optimize for humans, not machines.** The Reflaxe.Elixir compiler generates the most idiomatic, maintainable code when it receives relatively unoptimized Haxe AST that preserves the original program structure.