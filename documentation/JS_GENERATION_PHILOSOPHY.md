# JavaScript Generation Philosophy for Reflaxe.Elixir

## Core Principle: Separation of Concerns

**Reflaxe.Elixir focuses exclusively on Haxe→Elixir compilation**. JavaScript generation is delegated to Haxe's standard JS compiler, with minimal custom modifications only when absolutely necessary.

## Why This Approach?

### 1. **Reduced Maintenance Burden**
- Haxe's JS compiler is mature, well-tested, and continuously maintained
- We don't duplicate effort maintaining a parallel JS generation system
- Bug fixes and improvements in Haxe JS automatically benefit our users

### 2. **Clear Project Scope**
- Our mission: Generate idiomatic Elixir code from Haxe
- JavaScript is already a "solved problem" in the Haxe ecosystem
- Focus engineering effort on Elixir-specific challenges

### 3. **Better Compatibility**
- Standard Haxe JS output works with existing JS tooling
- No surprises for developers familiar with Haxe's JS target
- Seamless integration with Phoenix LiveView's JS requirements

## When We DO Customize JS Generation

Custom JS generation is reserved for features that:
1. **Don't exist in standard Haxe** (e.g., async/await syntax)
2. **Require specific integration** with Elixir/Phoenix features
3. **Provide critical value** that justifies maintenance overhead

### Current Custom JS Features

#### Async/Await Support
- **Why**: Standard Haxe (as of 4.3) doesn't have native async/await
- **What**: Transform Haxe async abstractions to modern JS async/await
- **How**: Use JSGenApi for targeted syntax transformation
- **Scope**: Only async-specific code paths

```haxe
// Haxe source with async abstraction
@:async function fetchData() {
    var result = @:await fetch("/api/data");
    return result;
}

// Custom JS generation
async function fetchData() {
    var result = await fetch("/api/data");
    return result;
}
```

## Implementation Guidelines

### 1. **Default to Standard Generation**
```haxe
// In ElixirCompiler.hx or similar
if (!requiresCustomJSGeneration(expr)) {
    return useStandardHaxeJSCompiler(expr);
}
```

### 2. **Isolate Custom Generation**
- Keep custom JS generation in separate modules
- Clear documentation on why customization is needed
- Minimal surface area for custom code

### 3. **Future-Proof Design**
- Design for easy migration to [Genes](https://github.com/benmerckx/genes) compiler
- Keep custom JS logic modular and replaceable
- Document integration points clearly

## Testing Philosophy

### What We Test
- **Elixir generation**: Comprehensive testing required
- **Custom JS features**: Test only our customizations
- **Standard JS**: Rely on Haxe's test suite

### What We Don't Test
- Standard Haxe→JS compilation (already tested by Haxe team)
- JS features that work identically to standard Haxe
- Cross-compilation scenarios unless specifically needed

## Future Direction: Genes Integration

When appropriate, we may migrate to the Genes compiler for JS generation:
- Modern ES6+ output by default
- Smaller bundle sizes
- Better tree-shaking support
- Still maintains separation of concerns principle

## Practical Examples

### ✅ Good: Focus on Elixir
```haxe
// PatternMatcher.hx - Elixir-specific pattern matching
class PatternMatcher {
    public function compileSwitchExpression(...) {
        // Generate idiomatic Elixir case/with statements
        // No JS generation logic here
    }
}
```

### ❌ Bad: Mixing Concerns
```haxe
// Don't do this
class PatternMatcher {
    public function compileSwitchExpression(...) {
        if (target == "elixir") {
            // Elixir logic
        } else if (target == "js") {
            // Custom JS logic - AVOID!
        }
    }
}
```

### ✅ Good: Isolated Custom JS
```haxe
// AsyncJSGenerator.hx - Clearly separated custom JS logic
@:jsRequire("reflaxe.js.Async")
class AsyncJSGenerator {
    // Only handles async/await transformation
    // Clear, focused responsibility
}
```

## Summary

- **Primary focus**: Haxe→Elixir compilation excellence
- **JS generation**: Use standard Haxe compiler (99% of cases)
- **Custom JS**: Only for critical features not in standard Haxe
- **Future**: Consider Genes for modern JS, maintain separation principle

This philosophy ensures Reflaxe.Elixir remains maintainable, focused, and delivers maximum value to developers building Elixir applications with Haxe's type safety.