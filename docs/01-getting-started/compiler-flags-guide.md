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

### `reflaxe_runtime`: Reflaxe compiler context

`-D reflaxe_runtime` is a Haxe compilation define used by the Reflaxe framework. It is
not an Elixir application runtime, deployment profile, or extra production service.
In practical terms, a build has both your application code and the Reflaxe.Elixir
compiler code that translates it. This define tells Haxe to make the compiler's own
helpers available while that translation runs. It is consumed during the build and
does not create a Reflaxe runtime mode in the generated Elixir application.

Reflaxe compiler implementations commonly guard shared compiler code with:

```haxe
#if (macro || reflaxe_runtime)
// Compiler implementation and helpers.
#end
```

Macro execution supplies the first context. The define supplies the second context
when Haxe types the compiler implementation as normal code, including the path used
by Reflaxe target initialization. This is a Reflaxe convention: the upstream
`reflaxe new` template includes it in the generated compiler project's
`DevEnv.hxml` so editor completion and development builds see the same code.
Targets differ in whether they expose that convention to application authors:
Reflaxe.Ruby documents the define in consumer commands, while the Rust and OCaml
compilers use the guard internally without advertising it in normal consumer HXMLs.
Reflaxe.Elixir currently follows the explicit Ruby-style contract.

For Reflaxe.Elixir applications, keep the following line in `build.hxml`:

```hxml
-D reflaxe_runtime
```

Use it only for Haxe builds that invoke Reflaxe.Elixir to generate Elixir. It is not
needed when running the generated application with Mix, compiling an unrelated Haxe
target such as the Phoenix JavaScript client, or including another HXML that already
defines it. Do not configure it as a global Haxe define.

The current `reflaxe.elixir` library HXML does not add the define automatically, so
source-checkout and installed-package examples declare it explicitly. That explicit
line makes the compilation contract visible and keeps both layouts equivalent; it
does not select different generated Elixir semantics. Whether a future release can
supply the define internally is a separate compatibility decision that must preserve
source/package parity and non-Elixir Haxe builds.

### Basic Configuration
```hxml
# build.hxml - Recommended settings
-cp src_haxe
-main Main
-lib reflaxe
-lib reflaxe.elixir
--no-output
-D reflaxe_runtime
-D elixir_output=lib

# Good optimizations
-dce full                    # Dead code elimination (removes unused code)
-D loop_unroll_max_cost=0    # Disable loop unrolling (preserve functional shapes)

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

#### Why `-dce full` is effectively required in this repo

This repository’s workflow (snapshots + CI guardrails + example apps) assumes `-dce full`:
- **Snapshots stay focused**: without DCE, output contains lots of unused generated helpers, making diffs noisy and harder to review.
- **CI stays predictable**: file-size guards and performance budgets rely on output staying small and deterministic.
- **DCE regressions are caught early**: Phoenix/OTP callbacks and modules are often invoked indirectly at runtime; running with DCE surfaces “was removed by DCE” failures during tests instead of in production.

You *can* temporarily disable DCE when debugging, but it’s not the recommended mode for this repo.

### Debug Flags (Development Only)
```hxml
# Helpful during development
-D debug_ast_pipeline       # See AST transformations
-D debug_pattern_matching   # Debug pattern matching
-D source-map              # Reserved/experimental (source mapping not fully wired yet)
```

## 📊 Flag Impact Comparison

| Flag | Impact on Elixir Output | Recommendation |
|------|------------------------|----------------|
| `-D reflaxe_runtime` | Includes the Reflaxe compiler implementation during target typing | ✅ **Required by current application HXML contract** |
| `-D analyzer-optimize` | Destroys functional patterns, unrolls loops | ❌ **Never use** |
| `-dce full` | Removes unused code cleanly | ✅ **Always use** |
| `-D loop_unroll_max_cost=N` | Controls unrolling threshold | ✅ **Prefer `0` (disable)** |
| `-D source-map` | Reserved/experimental | ⚠️ **Not yet end-to-end** |
| `-D debug_ast_pipeline` | Verbose AST transformation output | 🔧 **Development only** |

## 🎯 Configuration by Use Case

### For Development
```hxml
-dce full
-D loop_unroll_max_cost=0
# Optional: -D debug_ast_pipeline
```

### For Production
```hxml
-dce full
-D loop_unroll_max_cost=0
```

### For Testing
```hxml
-dce full
-D loop_unroll_max_cost=0
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
- [Troubleshooting Guide](../06-guides/TROUBLESHOOTING.md) - Common issues and solutions
- [Architecture Overview](../05-architecture/COMPILATION_FLOW.md) - How the compiler works

## 🎓 Key Takeaway

**For Elixir, optimize for humans, not machines.** The Reflaxe.Elixir compiler generates the most idiomatic, maintainable code when it receives relatively unoptimized Haxe AST that preserves the original program structure.
