# File Naming Architecture for Reflaxe.Elixir

## Overview

This document describes the file naming system that maps Haxe modules to
reviewable Elixir/Phoenix source paths. For Phoenix app-facing code, the target
Elixir module is the source of truth; Haxe package layout is an authoring
concern, not something that should leak into `lib/server/**` or `lib/shared/**`.

## Core Principles

1. **Universal snake_case conversion** - Every file gets proper Elixir naming
2. **Target-module-first placement** - app-facing Phoenix output follows the target Elixir module, not raw source-root layout
3. **Package-to-directory fallback** - plain non-Phoenix modules can still map Haxe packages to snake_case directories
4. **Framework-aware placement** - Phoenix annotations override default paths
5. **DRY implementation** - Single source of truth for all naming logic

## Architecture Components

### 1. Central Target Naming Helpers

Phoenix naming starts in `PhoenixTargetNames.hx` and is applied by
`ModuleBuilder` / `ElixirCompiler`:

```haxe
PhoenixTargetNames.classTargetAlias(classType): Null<String>
PhoenixTargetNames.aliasToPath("TodoAppWeb.TodoLive")
```

**Inputs:**
- `classType`: Complete Haxe class information including name, package, and metadata

**Outputs:**
- target module alias, such as `TodoAppWeb.TodoLive`
- physical path relative to the configured Elixir output root, such as
  `todo_app_web/live/todo_live.ex`

### 2. Naming Pipeline

```
Haxe Class → Derive Target Module → Convert Alias To Phoenix Path
```

#### Step 1: Extract Components
- Class name: `TodoLive`
- Package: `["server", "infrastructure"]`
- Annotations: `@:application`, `@:router`, etc.
- Defines: `-D app_name=TodoApp`, optional `-D app_web_name=TodoAppWeb`

#### Step 2: Derive Target Module
- `@:liveview class TodoLive` → `TodoAppWeb.TodoLive`
- `@:controller class UserController` → `TodoAppWeb.UserController`
- `@:schema class Todo` → `TodoApp.Todo`
- `@:native("Exact.Module")` keeps the exact target module when interop requires it

#### Step 3: Convert Target Module To Path
Target aliases are converted with normal Elixir/Phoenix snake_case rules:
- `TodoApp.Application` → `todo_app/application.ex`
- `TodoAppWeb.Router` → `todo_app_web/router.ex`
- `TodoAppWeb.TodoLive` → `todo_app_web/todo_live.ex`

Phoenix role metadata can add conventional subdirectories:
- `@:liveview` → `todo_app_web/live/todo_live.ex`
- `@:controller` → `todo_app_web/controllers/user_controller.ex`
- `@:component` → `todo_app_web/components/core_components.ex`

## Comprehensive Naming Rules

### Default Rule (No Annotations)
```
Class: MyComplexClassName
Package: com.example.models
Result: lib/com/example/models/my_complex_class_name.ex
```

This fallback is for plain Elixir modules where the Haxe package is
intentionally the Elixir namespace. Phoenix app-facing code should prefer role
metadata plus `-D app_name` / `-D app_web_name` so output lands under normal
`MyApp.*` and `MyAppWeb.*` paths.

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

This default is appropriate only when `Server.Contexts.Users` is intentionally
part of the Elixir API. For Phoenix app-facing modules, prefer an explicit
target namespace such as `TodoApp.Users` or `TodoApp.Accounts.Users`, which
should emit under `lib/todo_app/**`.

#### CamelCase Package
```
Package: MyCompany.DataModels
Class: CustomerOrder
Result: lib/my_company/data_models/customer_order.ex
```

## Implementation Details

### The DRY Naming System

```haxe
function classTargetAlias(classType: ClassType): Null<String> {
    if (hasNativeAlias(classType)) {
        return nativeAlias(classType);
    }

    if (hasPhoenixRole(classType) && hasAppNameDefine()) {
        return derivePhoenixAlias(classType);
    }

    return null;
}
```

### Integration with Reflaxe

The naming system integrates with Reflaxe's file output system:

```haxe
private function setFrameworkAwareOutputPath(classType: ClassType): Void {
    var targetAlias = PhoenixTargetNames.classTargetAlias(classType);

    if (targetAlias != null) {
        setOutputPath(PhoenixTargetNames.aliasToPath(targetAlias));
        return;
    }

    setOutputPath(packageFallbackPath(classType));
}
```

## Edge Cases and Special Handling

### 1. @:native Annotations
Classes with `@:native("Module.Name")` keep their native module name in the
generated code. Use this as an exact interop escape hatch, not the normal way to
name Phoenix app modules. For app-facing Phoenix output, the native module also
drives the physical output path:
```
@:native("TodoApp.Application")
class TodoApp
Result: lib/todo_app/application.ex with module TodoApp.Application
```

`@:native("TodoAppWeb.LiveEvents.TodoEvents")` should write
`lib/todo_app_web/live_events/todo_events.ex`, not a path derived from a Haxe
source package such as `shared.liveview`.

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
haxe build-server.hxml

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
**Final Fix**: Target-module-first naming with a shared alias-to-path mapper and
a package fallback for plain Elixir modules.

### Pattern of Naming Issues
These bugs revealed a systemic issue:
1. Multiple code paths for file naming (violating DRY)
2. Early returns preventing proper snake_case conversion
3. Missing annotation cases (@:application, @:supervisor, etc.)
4. Inconsistent handling between different compiler helpers

### The DRY Solution
Created the `PhoenixTargetNames` target mapper and routed framework-aware output
through it. The mapper:
- derives app/web modules from Phoenix role annotations plus `-D app_name`
- preserves exact `@:native` names only when interop requires them
- converts target aliases to normal Elixir/Phoenix paths
- leaves package-to-directory conversion as the fallback for plain modules

This eliminates an entire class of bugs by having a single source of truth for
app-facing Phoenix module and path naming.

## Future Enhancements

1. **Configurable naming strategies** - Allow projects to customize naming rules
2. **Namespace prefixing** - Support vendor prefixes for libraries
3. **Multi-app support** - Handle umbrella applications with multiple apps
4. **Backward compatibility mode** - Option to use old naming for migration

## Related Documentation

- [`/docs/03-compiler-development/COMPILER_BEST_PRACTICES.md`](/docs/03-compiler-development/COMPILER_BEST_PRACTICES.md) - Compiler development practices
- [`/docs/02-user-guide/FILE_GENERATION.md`](/docs/02-user-guide/FILE_GENERATION.md) - File generation process
- [`/docs/04-api-reference/ANNOTATIONS.md`](/docs/04-api-reference/ANNOTATIONS.md) - Framework annotation system
- [`/docs/02-user-guide/PHOENIX_INTEGRATION.md`](/docs/02-user-guide/PHOENIX_INTEGRATION.md) - Phoenix framework patterns

## Summary

The comprehensive naming system ensures that every Haxe class becomes a properly named Elixir file, following BEAM conventions while supporting Phoenix framework patterns. The DRY implementation makes it easy to maintain and extend, providing a solid foundation for cross-language compilation.
