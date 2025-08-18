# Elixir File Naming Convention Implementation

## Overview

Reflaxe.Elixir now generates files following proper Elixir naming conventions, converting from Haxe's PascalCase class names to Elixir's snake_case file names and directory structure.

## The Problem

Originally, Reflaxe.Elixir generated files using Haxe naming conventions:
- `TestDocClass.hx` → `TestDocClass.ex` (PascalCase)
- `haxe.CallStack` → `haxe_CallStack.ex` (flat structure with underscores)

This violated Elixir conventions which require:
- **snake_case filenames**: `test_doc_class.ex`
- **Directory structure for packages**: `haxe/call_stack.ex`

## The Solution (Two-Part Fix)

### Part 1: Snake_case Conversion ✅
**Location**: `ElixirCompiler.hx` lines 266 & 281  
**Implementation**: Replace `className` with `NamingHelper.toSnakeCase(className)`

```haxe
// Before:
return haxe.io.Path.join([outputDir, className + fileExtension]);

// After:
return haxe.io.Path.join([outputDir, NamingHelper.toSnakeCase(className) + fileExtension]);
```

### Part 2: Package-to-Directory Conversion ✅  
**Location**: `ElixirCompiler.hx` new function `convertPackageToDirectoryPath()`  
**Implementation**: Convert package.Class format to package/class structure

```haxe
private function convertPackageToDirectoryPath(classType: ClassType): String {
    var packageParts = classType.pack;
    var className = classType.name;
    
    // Convert class name to snake_case
    var snakeClassName = NamingHelper.toSnakeCase(className);
    
    if (packageParts.length == 0) {
        // No package - just return snake_case class name
        return snakeClassName;
    }
    
    // Convert package parts to snake_case and join with directories
    var snakePackageParts = packageParts.map(part -> NamingHelper.toSnakeCase(part));
    return haxe.io.Path.join(snakePackageParts.concat([snakeClassName]));
}
```

## Before and After Examples

### Simple Classes (No Package)
- **Before**: `TestDocClass.hx` → `TestDocClass.ex`
- **After**: `TestDocClass.hx` → `test_doc_class.ex`

### Packaged Classes  
- **Before**: `haxe.CallStack` → `haxe_CallStack.ex`
- **After**: `haxe.CallStack` → `haxe/call_stack.ex`

### Nested Packages
- **Before**: `haxe.ds.EnumValueMap` → `haxe_ds_EnumValueMap.ex`  
- **After**: `haxe.ds.EnumValueMap` → `haxe/ds/enum_value_map.ex`

### Exception Classes
- **Before**: `haxe.exceptions.NotImplementedException` → `haxe_exceptions_NotImplementedException.ex`
- **After**: `haxe.exceptions.NotImplementedException` → `haxe/exceptions/not_implemented_exception.ex`

## Integration Points

### 1. ElixirCompiler.hx Changes
- **Line 266**: Updated default file path generation
- **Line 281**: Updated fallback file path generation  
- **New function**: `convertPackageToDirectoryPath()` for package handling

### 2. NamingHelper.hx Utilization
The existing `NamingHelper.toSnakeCase()` function handles:
- PascalCase → snake_case conversion
- Elixir reserved keyword escaping
- Consistent naming across the codebase

## Testing Impact

### Snapshot Tests Affected ⚠️
All snapshot tests now generate files with the new naming convention, requiring `update-intended` for:
- Tests with packaged classes (most standard library tests)
- Tests with multiple classes in different packages
- Any test expecting the old PascalCase filenames

### Mix Tests  
Mix tests expecting specific filenames need updates:
- `test/mix_integration_test.exs:318` updated to expect `test_doc_class.ex`

## Technical Implementation Details

### Why Two Separate Fixes Were Needed

1. **Snake_case conversion**: Handled at the filename level
2. **Package structure**: Required AST-level access to `ClassType.pack`

The fixes had to be separate because:
- Snake_case affects the final filename only
- Package structure affects the entire file path with directories
- Reflaxe's `globalName()` flattens packages with underscores by default

### Reflaxe Integration
The implementation works within Reflaxe's file generation system by:
- Using `ClassType.pack` to access package information
- Leveraging `haxe.io.Path.join()` for cross-platform paths
- Maintaining compatibility with Reflaxe's `OutputManager`

## Validation

### Generated File Structure Examples
```
lib/
├── test_doc_class.ex              # Simple class
├── haxe/
│   ├── call_stack.ex              # haxe.CallStack
│   ├── log.ex                     # haxe.Log
│   ├── ds/
│   │   └── enum_value_map.ex      # haxe.ds.EnumValueMap
│   ├── io/
│   │   ├── bytes.ex               # haxe.io.Bytes
│   │   └── input.ex               # haxe.io.Input
│   └── exceptions/
│       └── not_implemented_exception.ex  # haxe.exceptions.NotImplementedException
```

### Phoenix Framework Compatibility ✅
The fix maintains compatibility with Phoenix-specific file placement:
- `@:router` classes still go to `lib/app_web/router.ex`
- `@:liveview` classes still go to `lib/app_web/live/`
- `@:schema` classes still go to `lib/app/schemas/`

## Performance Impact

**Minimal**: The conversion adds minimal overhead since it's:
- Applied only during compilation (macro-time)
- Uses simple string operations
- Leverages existing `NamingHelper` functions
- No runtime performance impact

## Future Considerations

### Potential Optimizations
- Cache converted paths for repeated class compilations
- Batch directory creation for better filesystem performance

### Edge Cases Handled
- Classes with no package (root level)
- Nested packages with multiple levels
- Reserved Elixir keywords in package names
- Special characters in class names

## Compliance

This implementation ensures Reflaxe.Elixir generates files that:
- ✅ Follow Elixir community conventions
- ✅ Work correctly with Mix build system
- ✅ Integrate properly with Phoenix projects
- ✅ Are compatible with Elixir tooling (IDE, formatters, etc.)
- ✅ Match the structure expected by Elixir developers

The file naming now matches what an Elixir developer would expect when looking at generated code - it appears "hand-written" rather than machine-generated.