# The .cross.hx Convention: Target-Specific Standard Library Implementation

## Overview

The `.cross.hx` convention is a Reflaxe framework feature that allows each compilation target to provide its own optimized, idiomatic implementations of standard library classes while maintaining the same public API across all platforms.

## How It Works

### Automatic Override Mechanism

When compiling for a specific target (like Elixir), Reflaxe automatically looks for `.cross.hx` files in the standard library paths and uses them instead of the default Haxe implementations:

1. **Classpath Resolution**: During compilation, Reflaxe checks for files with the `.cross.hx` extension
2. **Automatic Override**: If `Date.cross.hx` exists, it replaces the default `Date.hx` implementation
3. **Transparent to Users**: Application code uses `import Date` normally - no special imports needed
4. **Target-Specific**: Each Reflaxe target can have its own `.cross.hx` implementations

### Implementation in Reflaxe Infrastructure

From the Reflaxe source code (`reflaxe/Run.hx`):

```haxe
// Reflaxe automatically handles .cross.hx files for standard library paths
final ext = StringTools.endsWith(Path.removeTrailingSlashes(stdPath), "_std") ? ".cross.hx" : null;
copyDirContent(stdPathSrc, classPathDest, dirNormalized, stdPaths, ext);
```

This means:
- Files in `std/` directories with `.cross.hx` extension are automatically picked up
- No compiler modifications needed - Reflaxe infrastructure handles everything
- The pattern is baked into the Reflaxe framework itself

## When to Use .cross.hx

### ✅ Use .cross.hx When:

1. **Platform-Specific Optimization**: The target platform has a more efficient native implementation
   - Example: `Date.cross.hx` uses Elixir's DateTime instead of JavaScript-style Date

2. **Idiomatic Code Generation**: The default implementation would generate non-idiomatic code
   - Example: `Array.cross.hx` optimizes for Elixir's immutable lists

3. **Native Feature Access**: Need to leverage platform-specific capabilities
   - Example: `Process.cross.hx` could access BEAM process features

4. **Performance Critical Code**: Standard operations that benefit from native implementations
   - Example: `StringBuf.cross.hx` uses Elixir IO lists for efficiency

### ❌ Don't Use .cross.hx When:

1. **Simple Type Mappings**: If a simple extern or abstract type suffices
2. **Framework-Specific Code**: Use regular modules in appropriate directories (phoenix/, ecto/)
3. **Application Logic**: Not for business logic, only for standard library replacements

## Examples from Our Codebase

### Date.cross.hx - Complete Platform Reimplementation

```haxe
/**
 * Date: Cross-target Haxe API backed by Elixir DateTime at runtime.
 */
import elixir.DateTime.DateTime;

abstract Date(DateTime) {
    // Standard Haxe Date API
    public function getTime(): Float {
        // Convert Elixir microseconds to Haxe milliseconds
        return untyped __elixir__('DateTime.to_unix({0}, :millisecond)', this);
    }

    // Platform-specific extensions
    public function toIso8601(): String {
        return untyped __elixir__('DateTime.to_iso8601({0})', this);
    }
}
```

Key points:
- Maintains standard Haxe Date methods (getTime, getMonth, etc.)
- Backed by Elixir DateTime for zero-cost abstraction
- Can add platform-specific methods (toIso8601, diff, etc.)

### Array.cross.hx - Optimized for Immutable Lists

```haxe
/**
 * Array implementation optimized for Elixir's immutable lists
 */
@:coreApi
class Array<T> {
    public function push(x: T): Int {
        // Note: Creates new list in Elixir (immutable)
        return untyped __elixir__('{0} ++ [{1}]', this, x).length;
    }

    public function map<S>(f: T -> S): Array<S> {
        // Direct mapping to Elixir's Enum.map for efficiency
        return untyped __elixir__('Enum.map({0}, {1})', this, f);
    }
}
```

### StringBuf.cross.hx - Native IO List Implementation

```haxe
/**
 * StringBuf using Elixir's efficient IO lists
 */
class StringBuf {
    var iolist: Dynamic;

    public function new() {
        iolist = untyped __elixir__('[]');
    }

    public function add(x: String): Void {
        iolist = untyped __elixir__('{0} ++ [{1}]', iolist, x);
    }

    public function toString(): String {
        return untyped __elixir__('IO.iodata_to_binary({0})', iolist);
    }
}
```

## Best Practices for Creating .cross.hx Files

### 1. Maintain API Compatibility

**CRITICAL**: All standard Haxe methods must be implemented with identical signatures:

```haxe
// ✅ GOOD: Maintains standard API
public function getTime(): Float { } // Standard Haxe signature

// ❌ BAD: Breaking API compatibility
public function getTime(): Int { }   // Changed return type!
```

### 2. Document Platform Differences

Always document convention conversions and platform-specific behavior:

```haxe
/**
 * ## Convention Conversions:
 * - Months: Haxe uses 0-11, Elixir uses 1-12 (converted automatically)
 * - Day of Week: Haxe uses 0-6 (Sun-Sat), Elixir uses 1-7 (Mon-Sun)
 * - Time Units: Haxe uses milliseconds, Elixir uses microseconds
 */
```

### 3. Use Abstract Types for Zero-Cost Abstractions

Prefer abstract types over classes when wrapping native types:

```haxe
// ✅ GOOD: Zero runtime overhead
abstract Date(DateTime) {
    // 'this' IS the DateTime value
}

// ❌ LESS OPTIMAL: Wrapper object overhead
class Date {
    var datetime: DateTime;  // Extra wrapper
}
```

### 4. Provide Platform Extensions

Add platform-specific methods that enhance the API without breaking compatibility:

```haxe
abstract Date(DateTime) {
    // Standard Haxe API
    public function getTime(): Float { }

    // Elixir-specific extensions
    #if elixir
    public function add(amount: Int, unit: TimeUnit): Date { }
    public function diff(other: Date, unit: TimeUnit): Int { }
    public function truncate(precision: TimePrecision): Date { }
    #end
}
```

### 5. Handle Edge Cases Properly

Consider platform limitations and edge cases:

```haxe
public function new(year: Int, month: Int, day: Int, hour: Int, min: Int, sec: Int) {
    // Handle Elixir's 1-based months vs Haxe's 0-based
    var elixirMonth = month + 1;

    // Validate ranges
    if (elixirMonth < 1 || elixirMonth > 12) {
        throw 'Invalid month: $month';
    }

    this = DateTime.new(year, elixirMonth, day, hour, min, sec);
}
```

## File Organization

### Standard Library Structure

```
std/
├── Date.cross.hx           # Platform-specific Date implementation
├── Array.cross.hx          # Optimized Array for Elixir lists
├── StringBuf.cross.hx      # IO list-based StringBuf
├── Math.cross.hx          # Native math functions
├── Reflect.cross.hx       # Elixir reflection capabilities
├── Lambda.cross.hx        # Functional operations via Enum
└── haxe/
    └── iterators/
        ├── ArrayKeyValueIterator.cross.hx
        └── MapKeyValueIterator.cross.hx
```

### Naming Convention

- **File name**: `ClassName.cross.hx`
- **Location**: Same directory structure as standard Haxe library
- **Package**: Match the standard Haxe package structure

## Testing .cross.hx Implementations

### 1. Cross-Platform Compatibility Tests

Ensure your implementation works identically to other platforms:

```haxe
// Test that should pass on ALL platforms
var date = new Date(2024, 0, 15, 12, 30, 0);
assertEquals(date.getMonth(), 0);        // 0-based month
assertEquals(date.getDay(), 1);          // Monday = 1
assertEquals(date.getFullYear(), 2024);
```

### 2. Platform-Specific Feature Tests

Test platform extensions separately:

```haxe
#if elixir
// Test Elixir-specific features
var date = Date.now();
var tomorrow = date.add(1, Days);
assertEquals(date.diff(tomorrow, Days), -1);
#end
```

### 3. Generated Code Validation

Verify the generated Elixir code is idiomatic:

```elixir
# Generated from Date.cross.hx should be clean:
DateTime.add(datetime, 1, :day)  # Not some complex wrapper
```

## Common Patterns and Solutions

### Pattern 1: Convention Conversion

**Problem**: Haxe and target platform use different conventions
**Solution**: Convert at the API boundary

```haxe
public function getMonth(): Int {
    // Elixir uses 1-12, Haxe expects 0-11
    return untyped __elixir__('{0}.month - 1', this);
}
```

### Pattern 2: Missing Native Functionality

**Problem**: Target platform doesn't have direct equivalent
**Solution**: Implement using available primitives

```haxe
public function getDay(): Int {
    // Elixir's day_of_week returns 1-7 (Mon-Sun)
    // Haxe expects 0-6 (Sun-Sat)
    var elixirDay = untyped __elixir__('Date.day_of_week({0})', this);
    return elixirDay == 7 ? 0 : elixirDay;
}
```

### Pattern 3: Performance Optimization

**Problem**: Default implementation is inefficient
**Solution**: Use native operations

```haxe
public function map<S>(f: T -> S): Array<S> {
    // Direct Elixir Enum.map instead of loop
    return untyped __elixir__('Enum.map({0}, {1})', this, f);
}
```

## Relationship to Other Patterns

### vs. Extern Classes

- **Extern**: For accessing existing native modules
- **.cross.hx**: For replacing/reimplementing standard library

### vs. Abstract Types

- **Abstract**: Type-safe wrappers around native types
- **.cross.hx**: Complete class reimplementation

### vs. @:native Metadata

- **@:native**: Changes generated name of class/method
- **.cross.hx**: Replaces entire implementation

## Debugging .cross.hx Issues

### Common Problems and Solutions

1. **Import not found**: Ensure .cross.hx file is in std/ directory
2. **Method signature mismatch**: Verify exact match with standard Haxe API
3. **Runtime errors**: Check convention conversions and edge cases
4. **Non-idiomatic output**: Review `__elixir__()` usage

### Debug Compilation

```bash
# See which files are being used
npx haxe build.hxml -D dump-path

# Check if .cross.hx is picked up
npx haxe build.hxml -D debug-cross
```

### Using Reflaxe Build System (Recommended)

The Reflaxe framework provides its own build commands that better handle .cross.hx files:

```bash
# Better error reporting and .cross.hx handling
haxelib run reflaxe test build-server.hxml

# Run multiple tests in parallel
haxelib run reflaxe parallel test1.hxml test2.hxml test3.hxml

# Build for distribution
haxelib run reflaxe build dist/
```

Benefits of using `reflaxe test` over direct `haxe` compilation:
- Automatic .cross.hx file resolution
- Better error messages for Reflaxe-specific issues
- Proper handling of standard library paths
- Integrated with Reflaxe's infrastructure

## Migration Guide

### Converting Existing Code to .cross.hx

1. **Identify Candidates**: Look for frequently used stdlib classes
2. **Create .cross.hx File**: In same package structure
3. **Implement Standard API**: All public methods must match
4. **Add Platform Optimizations**: Use native features
5. **Test Thoroughly**: Both compatibility and performance
6. **Document Changes**: Explain optimizations and differences

## Summary

The `.cross.hx` convention is a powerful tool for creating platform-optimized standard library implementations while maintaining cross-platform compatibility. It allows Reflaxe.Elixir to:

- Generate idiomatic Elixir code
- Leverage native platform features
- Maintain full Haxe API compatibility
- Optimize performance-critical operations

When used correctly, it enables the best of both worlds: write once in Haxe, run efficiently on any target platform with native performance and idiomatic code generation.