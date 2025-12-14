# .cross.hx Files Staging Mechanism

## Overview
The Reflaxe framework uses `.cross.hx` files to provide target-specific implementations of standard library classes while maintaining cross-platform compatibility. This document explains the staging mechanism, its current implementation, known issues, and future improvements.

## What are .cross.hx Files?

`.cross.hx` files are a Reflaxe convention for providing target-specific implementations of standard library functionality:
- **Naming**: `ClassName.cross.hx` (e.g., `Array.cross.hx`, `StringTools.cross.hx`)
- **Purpose**: Override or extend default Haxe implementations for specific compilation targets
- **Location**: Originally in `std/` directory alongside regular `.hx` files

## Current Staging Mechanism

### 1. File Discovery
The compiler looks for `.cross.hx` files in the `std/` directory that need special handling for the Elixir target.

### 2. Staging Process
`.cross.hx` files are copied to a staging directory (`std/_std/`) with their `.cross` extension removed:
- `std/Array.cross.hx` → `std/_std/Array.hx`
- `std/Lambda.cross.hx` → `std/_std/Lambda.hx`
- `std/StringTools.cross.hx` → `std/_std/StringTools.hx`

### 3. Classpath Configuration
The staged directory is added to the classpath via `haxe_libraries/reflaxe.elixir.hxml`:
```hxml
# Include staged .cross.hx files (must come before std/ for proper override)
-cp ${SCOPE_DIR}/std/_std/
# Include the Elixir standard library definitions
-cp ${SCOPE_DIR}/std/
```

The order matters - staged files must come before the regular `std/` directory to properly override default implementations.

## Files Currently Staged

As of January 2025, these files are staged to `std/_std/`:
1. **Array.hx** - Elixir list-based array implementation
2. **ArrayTools.hx** - Static extension methods for arrays
3. **Date.hx** - Date/time handling for Elixir
4. **DateConverter.hx** - Date conversion utilities
5. **HXX.hx** - Template system core
6. **Lambda.hx** - Functional operations on iterables
7. **MapTools.hx** - Map manipulation utilities
8. **Math.hx** - Mathematical functions
9. **Process.hx** - Process management
10. **Reflect.hx** - Runtime reflection
11. **Std.hx** - Standard library core
12. **StringBuf.hx** - String buffer implementation
13. **StringTools.hx** - String manipulation utilities
14. **Sys.hx** - System operations
15. **Type.hx** - Type system utilities

## Known Issues and Architectural Flaws

### Critical Issue: Unconditional Classpath Inclusion

**Problem**: The current staging mechanism makes Elixir-specific code available in ALL compilation contexts:
- During macro evaluation
- When compiling to other targets (JavaScript, etc.)
- In the interpreter context

**Symptoms**:
- "Unknown identifier: __elixir__" errors in macro context
- Elixir-specific implementations override standard Haxe in all contexts
- Cross-target compilation issues

**Example Error**:
```
Main.hx:10: characters 15-25 : Unknown identifier: __elixir__
```

This happens because `__elixir__()` is only injected when compiling to Elixir target, but the staged files are available in all contexts.

### Required: Target-Conditional Classpath Injection

**Correct Architecture** (as implemented by mature Reflaxe compilers like hxcpp):

```haxe
// In CompilerInit.hx or bootstrap macro
public static function Start() {
    // ONLY add Elixir-specific paths when target is Elixir
    if (Context.definedValue("target.name") == "elixir") {
        // Add staged .cross.hx files to classpath
        Compiler.addClassPath("std/_std/");
    }
    // Macro context and other targets use regular Haxe stdlib
}
```

**Benefits**:
1. Macro context uses regular Haxe stdlib (no __elixir__ errors)
2. Other compilation targets unaffected
3. Clean separation of concerns
4. Matches established Reflaxe patterns

## Common Issues and Solutions

### Issue: "Array has no field reduce"
**Cause**: Test files using array extension methods without the required `using` statement
**Solution**: Add `using ArrayTools;` to the top of the file (after package statement)

**Example**:
```haxe
package;

using ArrayTools;  // Required for extension methods

class Main {
    public static function main() {
        var numbers = [1, 2, 3];
        var sum = numbers.reduce((a, b) -> a + b, 0);  // Now works!
    }
}
```

### Issue: Tests fail with missing methods
**Cause**: Static extension methods in ArrayTools.hx require explicit import
**Solution**: Ensure all test files that use array methods include `using ArrayTools;`

## Implementation Details

### How Extension Methods Work
ArrayTools provides static methods that extend Array functionality:
```haxe
class ArrayTools {
    public static function reduce<T, U>(array: Array<T>, func: (U, T) -> U, initial: U): U {
        // Implementation using __elixir__()
    }
}
```

When you add `using ArrayTools;`, these static methods become available as if they were instance methods on arrays.

### Why Not Add Methods Directly to Array?
1. **Separation of concerns** - Core Array class vs. functional extensions
2. **Cross-platform compatibility** - Not all targets support all methods
3. **Haxe conventions** - Static extensions are the standard pattern
4. **Maintainability** - Easier to manage extensions separately

## Future Improvements

### 1. Implement Target-Conditional Loading
Move classpath injection to the bootstrap macro and only add staged files when compiling to Elixir target.

### 2. Automatic Using Statements
Consider automatically adding common `using` statements for tests or providing a test base class.

### 3. Better Error Messages
Provide clearer error messages when extension methods are used without the required `using` statement.

### 4. Build-Time Staging
Instead of pre-staging files, stage them during the build process based on the target.

## Testing Considerations

### Required Using Statements
When writing tests that use array methods, always include necessary using statements:
```haxe
using ArrayTools;   // For array extension methods
using Lambda;       // For Lambda functional operations
using StringTools;  // For string extension methods
```

### Compilation Context
Tests compile in a different context than the main application. Ensure:
1. All required dependencies are available
2. Using statements are explicitly added
3. Classpath is correctly configured

## References

- [Reflaxe Framework Documentation](https://github.com/RobertBorghese/reflaxe)
- [Haxe Static Extension Documentation](https://haxe.org/manual/lf-static-extension.html)
- Similar implementations in other Reflaxe compilers:
  - [hxcpp](https://github.com/HaxeFoundation/hxcpp) - C++ target
  - [reflaxe.cs](https://github.com/RobertBorghese/reflaxe.cs) - C# target

## Conclusion

The .cross.hx staging mechanism is a powerful feature for providing target-specific implementations, but the current implementation has architectural flaws. The main issue is unconditional classpath inclusion, which should be replaced with target-conditional injection. Additionally, developers must be aware that static extension methods require explicit `using` statements in Haxe.

---

## Appendix: Transitional Stub Pattern (HXX)

In this repository, `std/HXX.cross.hx` is implemented as a transitional stub. This is a minimal, compile‑time API surface that preserves authoring ergonomics (`HXX.hxx("...")`, `HXX.block("...")`) while the macro‑based HXX path is finalized.

Key properties:

- Zero runtime behavior: the stub returns the input string unchanged (extern/inline).
- Deterministic pipeline: mid/late AST passes convert final HTML‑like strings to `~H` sigils and normalize control tags (`<if {cond}> ... </if>` → block HEEx).
- Target‑conditional availability: the stub is gated via the classpath mechanism described above, so macro/other targets do not see Elixir‑only code.

Why a stub (temporarily)?

- Some example code already uses `HXX.hxx(...)`. The stub keeps call‑sites stable and delegates semantics to our AST pipeline while we complete the macro path that emits `ESigil("H", ...)` directly.

Removal criteria:

- Macro-default HXX is active and validated by snapshots (inline expression + block‑if)
- All example/templates are migrated to macro path (no reliance on stubbed HXX)
- QA sentinel (bounded) is green across full E2E suite
- No module in std/ or src_haxe references `std/HXX.cross.hx`

Once these gates are met, remove the transitional stub and its classpath entry, and re-run snapshots to lock intended shapes. Historical documentation should keep a short note on the stub for context.

Verification steps:

1) `rg -n "HXX.cross.hx|HXX.hxx\(|HXX.block\(" -S` shows only docs/tests/intentional macro usages
2) `make -C test summary` passes with no unexpected diffs
3) `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --playwright --e2e-spec "e2e/*.spec.ts" --e2e-workers 1 --deadline 900 -v` returns DONE=0


1) Macro‑based HXX marks strings with `@:heex` and the builder emits `ESigil("H", ...)` deterministically.
2) Snapshot tests cover block HEEx generation and assigns mapping without relying on string→~H conversion.
3) Example apps compile cleanly with only the macro path enabled.

For a beginner‑friendly introduction to `.cross.hx` (what/why/when), see docs/01-getting-started/cross-hx.md.
