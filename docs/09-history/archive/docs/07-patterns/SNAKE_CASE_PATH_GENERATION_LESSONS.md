# Snake_case Path Generation Lessons Learned

> **Historical Note**: This document describes an earlier naming bug that has been comprehensively fixed by the DRY file naming architecture implemented in 2025-08-18. For the current naming system, see [`FILE_NAMING_ARCHITECTURE.md`](FILE_NAMING_ARCHITECTURE.md). This document is preserved for historical context and learning purposes.

## Problem Statement
The RouterCompiler was generating Phoenix router files in `TodoApp_web/router.ex` instead of the correct `todo_app_web/router.ex`, causing Phoenix module loading issues.

## Root Cause Analysis

### The Bug Hunt Journey
1. **Initial Hypothesis**: The RouterCompiler wasn't using snake_case conversion
   - **Finding**: RouterCompiler correctly generated `TodoAppWeb.Router` module name
   - **Lesson**: Module names and file paths are handled separately in the compiler

2. **Second Hypothesis**: The `extractAppName` function wasn't converting to snake_case
   - **Finding**: The function had `toSnakeCase` call, but it wasn't being executed
   - **Lesson**: Conditional compilation can bypass critical code paths

3. **Third Hypothesis**: The `toSnakeCase` function was broken
   - **Finding**: Function worked perfectly when tested in isolation
   - **Lesson**: Always test utility functions independently to eliminate variables

4. **Final Discovery**: Compiler defines were bypassing snake_case conversion
   - **Finding**: `-D app_name=TodoApp` in build-server.hxml returned PascalCase directly
   - **Critical Code**:
     ```haxe
     #if (app_name)
     return haxe.macro.Context.definedValue("app_name"); // Returned "TodoApp" without conversion!
     #end
     ```
   - **Lesson**: Compiler defines can introduce unexpected behavior bypasses

## The Fix
```haxe
// Before: Trusted the define value to be in correct format
#if (app_name)
return haxe.macro.Context.definedValue("app_name");
#end

// After: Always normalize to snake_case
#if (app_name)
var definedName = haxe.macro.Context.definedValue("app_name");
return toSnakeCase(definedName);
#end
```

## Key Lessons for Compiler Development

### 1. Never Trust External Input Format
**Principle**: Always normalize external inputs (defines, environment variables, user input) to the expected format.
- Compiler defines might be in any case format
- User-provided values need validation and normalization
- Framework conventions must be enforced consistently

### 2. Conditional Compilation Creates Hidden Code Paths
**Principle**: Be extremely careful with `#if` conditionals in critical paths.
- They can bypass important processing logic
- They make debugging harder (traces might not execute)
- They create multiple code paths that need testing

### 3. Separation of Concerns in Path Generation
**Principle**: Module names, file names, and directory paths are separate concerns.
- Module name: `TodoAppWeb.Router` (PascalCase modules)
- File name: `router.ex` (snake_case file)
- Directory path: `todo_app_web/` (snake_case directory)
- Each needs its own formatting rules

### 4. Debugging Strategy for Path Issues
**Effective Approach**:
1. Trace the exact values at each transformation point
2. Test utility functions in isolation
3. Check for conditional compilation bypasses
4. Verify external configuration values
5. Look for multiple sources of truth (defines vs. code logic)

### 5. Framework Convention Enforcement
**Principle**: Compilers targeting frameworks must enforce framework conventions.
- Phoenix expects specific directory structures
- File locations affect module loading
- Case sensitivity matters in paths
- Convention over configuration requires the compiler to know conventions

## Testing Improvements Needed

### 1. Test with Various Define Values
```hxml
# Test different case formats
-D app_name=TodoApp      # PascalCase
-D app_name=todo_app      # snake_case  
-D app_name=TODO_APP      # UPPER_CASE
```

### 2. Test Path Generation Independently
```haxe
class PathGenerationTest {
    static function testExtractAppName() {
        assertEquals("todo_app", extractAppName("TodoAppRouter"));
        assertEquals("my_app", extractAppName("MyAppLive"));
        // Test with defines set
        assertEquals("todo_app", extractAppNameWithDefine("TodoApp"));
    }
}
```

### 3. Validate Generated Paths Match Phoenix Expectations
```bash
# Verify generated structure matches Phoenix conventions
assert -d "lib/todo_app_web"
assert -f "lib/todo_app_web/router.ex"
assert ! -d "lib/TodoApp_web"  # Should not exist
```

## Prevention Strategies

### 1. Input Normalization Layer
Create a dedicated function for all external inputs:
```haxe
function normalizeAppName(name: String): String {
    return toSnakeCase(name.replace("App", "")
                           .replace("Web", ""));
}
```

### 2. Consistent Define Format Documentation
Document expected format for all compiler defines:
```hxml
# app_name: Application name in snake_case (e.g., todo_app, my_app)
# NOT: TodoApp, MyApp, TODO_APP
-D app_name=todo_app
```

### 3. Runtime Validation
Add validation to catch incorrect formats early:
```haxe
var appName = extractAppName(className);
if (appName.indexOf("_") == -1 && appName != appName.toLowerCase()) {
    Context.warning('App name "${appName}" should be in snake_case', pos);
}
```

## Impact of This Fix

### Before
- Generated: `lib/TodoApp_web/router.ex`
- Phoenix couldn't find the router module
- Module loading errors at runtime

### After  
- Generated: `lib/todo_app_web/router.ex`
- Phoenix loads the router correctly
- Follows Phoenix conventions exactly

## Related Issues This Might Affect
- LiveView path generation (`todo_app_web/live/`)
- Controller path generation (`todo_app_web/controllers/`)
- Any other framework-aware path generation

## Conclusion
This bug highlighted the importance of:
1. **Normalizing all external inputs** regardless of source
2. **Testing with realistic configuration** (actual build files)
3. **Understanding framework conventions** deeply
4. **Tracing actual values** not assuming behavior
5. **Being suspicious of conditional compilation** in critical paths

The fix was simple (3 lines), but finding it required systematic debugging and understanding the full compilation pipeline from Haxe source to Elixir file generation.