# File Naming Architecture for Reflaxe.Elixir

## Overview

This document describes the comprehensive file naming system that transforms Haxe PascalCase class names and package structures into Elixir snake_case file paths. The system ensures **100% consistency** across all generated files while respecting Phoenix framework conventions.

## Core Principles

1. **Universal snake_case conversion** - Every file gets proper Elixir naming
2. **Package-to-directory mapping** - Haxe packages become snake_case directories
3. **Framework-aware placement** - Phoenix annotations override default paths
4. **DRY implementation** - Single source of truth for all naming logic

## Architecture Components

### 1. Central Naming Function: `getComprehensiveNamingRule()`

Located in `ElixirCompiler.hx`, this function handles ALL naming scenarios:

```haxe
private function getComprehensiveNamingRule(classType: ClassType): {fileName: String, dirPath: String}
```

**Inputs:**
- `classType`: Complete Haxe class information including name, package, and metadata

**Outputs:**
- `fileName`: Snake_case file name (without extension)
- `dirPath`: Directory path relative to lib/

### 2. Naming Pipeline

```
Haxe Class → Extract Components → Apply Rules → Generate Path
```

#### Step 1: Extract Components
- Class name: `TodoApp`
- Package: `["server", "infrastructure"]`
- Annotations: `@:application`, `@:router`, etc.

#### Step 2: Apply Base Rules
- Convert class name to snake_case: `TodoApp` → `todo_app`
- Convert package parts to snake_case: `["server", "infrastructure"]` → `["server", "infrastructure"]`
- Create default path: `server/infrastructure/todo_app.ex`

#### Step 3: Apply Framework Overrides
If framework annotations are present, override the default path:
- `@:application` → `todo_app/application.ex`
- `@:router` → `todo_app_web/router.ex`
- `@:endpoint` → `todo_app_web/endpoint.ex`

## Comprehensive Naming Rules

### Default Rule (No Annotations)
```
Class: MyComplexClassName
Package: com.example.models
Result: lib/com/example/models/my_complex_class_name.ex
```

### Framework Annotation Rules

#### @:application
```
Class: TodoApp
Annotation: @:application
Result: lib/todo_app/application.ex
```
**Note**: The file is named `application.ex` but placed in the app's directory for better organization.

#### @:router
```
Class: TodoAppRouter
Annotation: @:router
Result: lib/todo_app_web/router.ex
```
**Special**: Always named `router.ex` regardless of class name.

#### @:liveview
```
Class: UserLive
Annotation: @:liveview
Result: lib/todo_app_web/live/user_live.ex
```
**Pattern**: Preserves the `_live` suffix for clarity.

#### @:controller
```
Class: UserController
Annotation: @:controller
Result: lib/todo_app_web/controllers/user_controller.ex
```

#### @:schema
```
Class: Todo
Annotation: @:schema
Result: lib/todo_app/schemas/todo.ex
```

#### @:endpoint
```
Class: Endpoint
Annotation: @:endpoint
Result: lib/todo_app_web/endpoint.ex
```

### Package Transformation Examples

#### Simple Package
```
Package: models
Class: User
Result: lib/models/user.ex
```

#### Nested Package
```
Package: server.contexts
Class: Users
Result: lib/server/contexts/users.ex
```

#### CamelCase Package
```
Package: MyCompany.DataModels
Class: CustomerOrder
Result: lib/my_company/data_models/customer_order.ex
```

## Implementation Details

### The DRY Naming System

```haxe
private function getComprehensiveNamingRule(classType: ClassType): {fileName: String, dirPath: String} {
    var className = classType.name;
    var packageParts = classType.pack;
    var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
    
    // 1. Start with base snake_case conversion
    var baseFileName = NamingHelper.toSnakeCase(className);
    
    // 2. Convert package parts to snake_case directories
    var snakePackageParts = packageParts.map(part -> NamingHelper.toSnakeCase(part));
    var packagePath = snakePackageParts.length > 0 ? snakePackageParts.join("/") : "";
    
    // 3. Create default rule
    var rule = {
        fileName: baseFileName,
        dirPath: packagePath
    };
    
    // 4. Apply framework-specific overrides
    if (annotationInfo.primaryAnnotation != null) {
        // ... annotation-specific logic
    }
    
    return rule;
}
```

### Integration with Reflaxe

The naming system integrates with Reflaxe's file output system:

```haxe
private function setFrameworkAwareOutputPath(classType: ClassType): Void {
    var namingRule = getComprehensiveNamingRule(classType);
    
    // Tell Reflaxe where to put the file
    setOutputFileName(namingRule.fileName);
    setOutputFileDir(namingRule.dirPath);
}
```

## Edge Cases and Special Handling

### 1. @:native Annotations
Classes with `@:native("Module.Name")` keep their native module name in the generated code but still follow file naming conventions:
```
@:native("TodoApp.Application")
class TodoApp
Result: lib/todo_app/application.ex with module TodoApp.Application
```

### 2. Acronyms and Special Cases
```
HTTPClient → http_client.ex
XMLParser → xml_parser.ex
IOManager → io_manager.ex
```

### 3. Numbers in Names
```
User2FASettings → user2fa_settings.ex
Table3Column → table3_column.ex
```

### 4. Already Snake_Case
If a class is already in snake_case (unusual but possible):
```
already_snake → already_snake.ex (no change)
```

## Benefits of This Architecture

1. **Consistency** - All files follow Elixir conventions
2. **Predictability** - Developers can easily find generated files
3. **Framework Integration** - Phoenix apps work out-of-the-box
4. **Maintainability** - Single source of truth for naming logic
5. **Extensibility** - Easy to add new annotation types

## Testing the Naming System

### Unit Test Examples
```haxe
// Test basic conversion
assert(getName("MyClass") == "my_class");

// Test package conversion
assert(getPath(["com", "example"], "User") == "com/example/user.ex");

// Test annotation override
assert(getPath([], "TodoAppRouter", "@:router") == "todo_app_web/router.ex");
```

### Integration Test
```bash
# Compile todo-app
npx haxe build-server.hxml

# Verify file structure
find lib -name "*.ex" | head -20

# Should see:
# lib/todo_app/application.ex
# lib/todo_app_web/router.ex
# lib/todo_app_web/endpoint.ex
# lib/todo_app_web/live/todo_live.ex
# lib/todo_app/schemas/todo.ex
```

## Migration Guide

### For Existing Projects
1. Delete all generated .ex files
2. Update to latest compiler with comprehensive naming
3. Regenerate all files
4. Update any manual references to old file paths

### Common Issues and Solutions

**Issue**: File not found after naming update
**Solution**: Check for framework annotations that change output location

**Issue**: Module name doesn't match file path
**Solution**: This is normal for @:native annotations - module name can differ from file name

**Issue**: Package directories not created
**Solution**: Ensure package declaration in Haxe source matches intended structure

## Bug Fixes and Historical Issues

### The Double Colon Bug
**Issue**: Supervisor options were being compiled as `::one_for_one` instead of `:one_for_one`
**Root Cause**: The compileSupervisorOptions function was adding an extra colon to enum values that already had one
**Fix**: Added detection to remove leading colon from enum values before formatting (ElixirCompiler.hx lines 5060-5067)
**Related**: This was part of a pattern of enum compilation issues where the compiler wasn't handling Elixir atoms correctly

### The TodoApp.ex Naming Bug
**Issue**: Application classes like TodoApp were generating `TodoApp.ex` instead of `todo_app.ex`
**Discovery**: User observation that file names weren't following Elixir conventions
**Root Cause**: The @:application annotation case wasn't being handled in file naming logic
**Initial Attempt**: Added @:application case but had early return bug preventing snake_case conversion
**Final Fix**: Comprehensive DRY naming system that handles all cases without early returns

### Pattern of Naming Issues
These bugs revealed a systemic issue:
1. Multiple code paths for file naming (violating DRY)
2. Early returns preventing proper snake_case conversion
3. Missing annotation cases (@:application, @:supervisor, etc.)
4. Inconsistent handling between different compiler helpers

### The DRY Solution
Created getComprehensiveNamingRule() function that:
- Centralizes ALL naming logic in one place
- Handles package-to-directory conversion
- Supports all framework annotations
- Always applies snake_case transformation (no early returns)
- Follows idiomatic Elixir/Phoenix conventions

This eliminated an entire class of bugs by having a single source of truth for file naming.

## Future Enhancements

1. **Configurable naming strategies** - Allow projects to customize naming rules
2. **Namespace prefixing** - Support vendor prefixes for libraries
3. **Multi-app support** - Handle umbrella applications with multiple apps
4. **Backward compatibility mode** - Option to use old naming for migration

## Related Documentation

- [`/documentation/COMPILER_BEST_PRACTICES.md`](COMPILER_BEST_PRACTICES.md) - Compiler development practices
- [`/documentation/FILE_GENERATION.md`](FILE_GENERATION.md) - File generation process
- [`/documentation/ANNOTATION_SYSTEM.md`](ANNOTATION_SYSTEM.md) - Framework annotation system
- [`/documentation/PHOENIX_INTEGRATION.md`](PHOENIX_INTEGRATION.md) - Phoenix framework patterns

## Summary

The comprehensive naming system ensures that every Haxe class becomes a properly named Elixir file, following BEAM conventions while supporting Phoenix framework patterns. The DRY implementation makes it easy to maintain and extend, providing a solid foundation for cross-language compilation.