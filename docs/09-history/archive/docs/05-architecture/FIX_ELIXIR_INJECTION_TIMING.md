# PRD: Fix __elixir__ Injection Timing in Reflaxe

## Problem Statement

### Current Issue
The `__elixir__()` target code injection function is not available during Haxe's typing phase, preventing its use in `extern inline` functions. This limitation forces standard library implementations to avoid inlining, resulting in less efficient code generation and preventing idiomatic Elixir output.

### Impact
1. **Date class**: Cannot use `extern inline` for `Date.now()` to generate clean `DateTime.utc_now()` calls
2. **Array class**: Cannot inline methods like `map()`, `filter()` that use `__elixir__()`
3. **StringBuf**: Cannot inline efficient IO list operations
4. **Any stdlib**: Forced to choose between native efficiency (`__elixir__`) or inlining

### Root Cause
Reflaxe registers `__elixir__` as a TIdent node AFTER Haxe's typing phase via `Context.onAfterTyping()`. When Haxe encounters `extern inline`, it immediately types the function body, but `__elixir__` doesn't exist yet, causing "Unknown identifier: __elixir__" errors.

## Technical Analysis

### Current Flow (BROKEN)
```
1. Haxe starts compilation
2. Haxe encounters `extern inline function` with `untyped __elixir__()`
3. Haxe tries to type the function body immediately
4. ERROR: __elixir__ doesn't exist as an identifier
5. Compilation fails
```

### Desired Flow (FIXED)
```
1. Haxe starts compilation
2. Reflaxe registers __elixir__ as a known identifier EARLY
3. Haxe encounters `extern inline function` with `untyped __elixir__()`
4. Haxe types the function body - __elixir__ is recognized
5. Function inlines properly at call sites
6. Reflaxe processes the inlined __elixir__ calls during code generation
```

## Solution Design

### Approach 1: Define __elixir__ as a Compiler-Level Identifier (RECOMMENDED)

Register `__elixir__` as a global untyped identifier before any typing occurs, similar to how Haxe defines built-in identifiers like `trace`.

**Implementation Steps:**
1. In `ReflectCompiler.hx`, use `Context.defineType()` or `Context.defineModule()` to create `__elixir__` early
2. Register it as an untyped function that accepts dynamic arguments
3. During compilation, recognize and process these calls in `TargetCodeInjection.hx`

**Pros:**
- Clean solution that works with all Haxe features
- No changes needed to user code
- Works with `extern inline`, regular functions, abstracts, etc.

**Cons:**
- Requires understanding of Haxe's internal type definition system

### Approach 2: Initialization Macro (ALTERNATIVE)

Use an initialization macro that runs before typing to define `__elixir__`.

**Implementation:**
```haxe
class ReflectCompiler {
    public static function init() {
        // Called via --macro before compilation
        Context.onMacroContextReused(() -> {
            // Define __elixir__ here
        });
    }
}
```

**Pros:**
- Simpler to implement
- Clear initialization point

**Cons:**
- Requires additional macro call in build files
- May not work in all compilation contexts

### Approach 3: Extern Definition (FALLBACK)

Define `__elixir__` as an extern function in a special module that's always imported.

**Implementation:**
```haxe
// In std/__Internal.hx
extern function __elixir__(code: String, args: haxe.extern.Rest<Dynamic>): Dynamic;
```

**Pros:**
- Very simple implementation
- Uses standard Haxe mechanisms

**Cons:**
- Requires special import handling
- May conflict with Reflaxe's injection mechanism

## Implementation Plan

### Phase 1: Early Registration (Approach 1)

**File: vendor/reflaxe/src/reflaxe/ReflectCompiler.hx**

1. Add early registration hook:
```haxe
public static function AddCompiler(compiler: BaseCompiler, options: ReflectCompilerOptions) {
    // NEW: Register target injection name early
    if (options.targetCodeInjectionName != null) {
        registerTargetInjection(options.targetCodeInjectionName);
    }
    
    // Existing code...
    Context.onAfterTyping(onAfterTyping);
}

static function registerTargetInjection(name: String) {
    // Define as an untyped global identifier
    // This makes it available during typing phase
    try {
        // Create a fake extern that Haxe recognizes but doesn't generate
        var td = macro class {
            public static function $name(code: String, args: haxe.extern.Rest<Dynamic>): Dynamic;
        };
        Context.defineModule("__generated__." + name, [td]);
    } catch(e: Dynamic) {
        // May already be defined, ignore
    }
}
```

### Phase 2: Update Injection Detection

**File: vendor/reflaxe/src/reflaxe/compiler/TargetCodeInjection.hx**

No changes needed - existing detection should work with the early-registered identifier.

### Phase 3: Test with Date Class

**File: std/Date.hx**

Update Date methods to use `extern inline`:
```haxe
public static extern inline function now(): Date {
    return untyped __elixir__('DateTime.utc_now()');
}

public static extern inline function fromTime(t: Float): Date {
    return untyped __elixir__('DateTime.from_unix!({0}, :millisecond)', t);
}
```

## Expected Results

### Before Fix
```haxe
// Date.hx
public static function now(): Date {
    var d = new Date(0, 0, 0, 0, 0, 0);
    d.datetime = untyped __elixir__('DateTime.utc_now()');
    return d;
}

// Usage
var now = Date.now();

// Generated Elixir (inefficient)
d = Date.new(0, 0, 0, 0, 0, 0)
d.datetime = DateTime.utc_now()
now = d
```

### After Fix
```haxe
// Date.hx
public static extern inline function now(): Date {
    return untyped __elixir__('DateTime.utc_now()');
}

// Usage
var now = Date.now();

// Generated Elixir (clean, idiomatic)
now = DateTime.utc_now()
```

## Testing Strategy

### Unit Tests
1. Create test with `extern inline` function using `__elixir__()`
2. Verify compilation succeeds
3. Check generated code is properly inlined

### Integration Tests
1. Update Date class with `extern inline`
2. Compile todo-app
3. Verify Date.now() generates `DateTime.utc_now()`
4. Test other stdlib classes can use inline

### Edge Cases
1. Multiple `__elixir__()` calls in one inline function
2. Nested inline functions with `__elixir__()`
3. Abstract types with inline methods using `__elixir__()`
4. Conditional compilation with `__elixir__()`

## Risk Assessment

### Low Risk
- Change is isolated to initialization phase
- Doesn't affect existing code generation
- Backward compatible - existing code continues to work

### Medium Risk
- May interact with other Haxe macros
- Could affect compilation performance (minimal)

### Mitigation
- Add feature flag to disable if issues arise
- Comprehensive testing before enabling by default
- Document the change clearly

## Success Criteria

1. ✅ `extern inline` functions can use `untyped __elixir__()`
2. ✅ Date.now() compiles to clean `DateTime.utc_now()`
3. ✅ No regression in existing code
4. ✅ Array, StringBuf can be optimized with inline
5. ✅ Compilation performance unchanged or improved

## Timeline

1. **Hour 1**: Implement early registration in ReflectCompiler
2. **Hour 2**: Test with simple inline functions
3. **Hour 3**: Update Date class and test
4. **Hour 4**: Update other stdlib classes
5. **Hour 5**: Comprehensive testing and documentation

## Long-term Benefits

1. **Better Performance**: Inline functions eliminate function call overhead
2. **Cleaner Output**: Direct native calls instead of wrapper objects
3. **Maintainability**: Simpler stdlib implementations
4. **Future Features**: Enables more advanced optimizations
5. **User Experience**: Generated code looks hand-written

## Alternative Considerations

If early registration proves problematic, we could:
1. Use macro functions instead of `untyped __elixir__()`
2. Generate different code paths for inline vs non-inline
3. Implement compiler-level inlining during AST transformation
4. Accept the limitation and document it

## Conclusion

This fix removes a fundamental limitation in Reflaxe's architecture, enabling standard library code to be both efficient (using native Elixir) and optimized (using inline). The solution is clean, backward-compatible, and aligns with Haxe's compilation model.