# Haxe Language Fundamentals for Reflaxe.Elixir

## Critical Type System Differences

This document captures fundamental differences between Haxe and JavaScript/other languages that are crucial for compiler development and must be understood to avoid architectural mistakes.

## ⚠️ Boolean Operators: NOT Like JavaScript

### The Fundamental Difference

**CRITICAL INSIGHT**: In Haxe, `&&` and `||` operators **ALWAYS return Bool**, not the operand values like in JavaScript.

### JavaScript vs Haxe Behavior

```javascript
// JavaScript - operators return operand values
var name = user.name || "Default";        // ✅ Returns "Default" if user.name is falsy
var obj = user && user.profile;           // ✅ Returns user.profile if user is truthy
```

```haxe
// Haxe - operators return Bool only
var name = user.name || "Default";        // ❌ ERROR: String should be Bool
var obj = user && user.profile;           // ❌ ERROR: Returns Bool, not Dynamic
```

### Correct Haxe Patterns

```haxe
// ✅ Use ternary operator for conditional values
var name = user.name != null ? user.name : "Default";

// ✅ Use if-expressions for complex logic
var name = if (user != null && user.name != null) user.name else "Default";

// ✅ Boolean operators for boolean logic only
var isValid = (user != null) && (user.name != null);  // Returns Bool
var hasEither = (a != null) || (b != null);           // Returns Bool
```

### Template Expression Implications

This affects template string expressions in Phoenix HEEx templates:

```haxe
// ❌ WRONG - generates type errors
HXX.hxx('<span>${assigns.user && assigns.user.name || "Guest"}</span>')

// ✅ CORRECT - explicit conditional logic
HXX.hxx('<span>${assigns.user != null && assigns.user.name != null ? assigns.user.name : "Guest"}</span>')
```

## Why This Matters for Compiler Development

### 1. Template Processing
- HXX template expressions must use proper Haxe conditional syntax
- Cannot rely on JavaScript-style truthiness evaluation
- Type checking prevents implicit conversions

### 2. Code Generation
- Generated Elixir must handle null safety explicitly
- Cannot assume falsy values work like JavaScript
- Pattern matching preferred over boolean operations

### 3. Cross-Platform Consistency
- Haxe's strict typing prevents runtime surprises
- Explicit conditionals make intent clear
- Better error messages at compile time

## Architectural Lessons

### Never Assume JavaScript Semantics
When designing language features or processing user code:

1. **Verify Haxe behavior** - Test actual language semantics
2. **Don't port JavaScript patterns** - They may not work in Haxe
3. **Use official documentation** - https://haxe.org/manual/ for authoritative behavior
4. **Test edge cases** - Especially around type coercion and operators

### Document Type System Differences
- Create examples showing correct patterns
- Explain **why** certain approaches don't work
- Provide migration guides from other languages
- Test examples to ensure accuracy

## Related Documentation

- **HXX Template Guide**: [HXX Syntax & Comparison](HXX_SYNTAX_AND_COMPARISON.md) - Shows correct template syntax
- **Haxe Manual**: https://haxe.org/manual/expression-operators-binops.html - Official operator documentation
- **Type System**: https://haxe.org/manual/types.html - Haxe typing rules

## Testing Haxe Behavior

When in doubt about Haxe semantics, create test files:

```haxe
class TestOperators {
    static function main() {
        var user = {name: "Alice"};
        
        // Test boolean operators
        var hasName:Bool = user != null && user.name != null;  // ✅ Bool
        trace('Boolean result: $hasName');
        
        // Test ternary for values  
        var name = user != null ? user.name : "Default";       // ✅ String
        trace('Name result: $name');
        
        // This would fail:
        // var name2 = user.name || "Default";  // ❌ String should be Bool
    }
}
```

Compile and run: `haxe --main TestOperators --interp`

## Key Takeaway

**Haxe's type system is strict and explicit. JavaScript-style implicit conversions and operator behaviors do not apply. Always verify language semantics before assuming behavior.**
