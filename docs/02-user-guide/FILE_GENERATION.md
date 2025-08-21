# File Generation Architecture in Reflaxe.Elixir

## Overview

Reflaxe.Elixir uses an **annotation-aware file generation system** that automatically places generated files in framework-appropriate locations. This ensures that generated Elixir code follows Phoenix/OTP conventions exactly, enabling seamless integration with the target ecosystem.

## Key Innovation: Framework Convention Adherence

Unlike traditional 1:1 transpilers, Reflaxe.Elixir understands target framework conventions and places files where they're expected, not just based on source file names.

### Example Transformation

```haxe
// Source: src_haxe/TodoAppRouter.hx
@:router
class TodoAppRouter {
    @:route({method: "LIVE", path: "/", controller: "TodoLive", action: "index"})
    public static function root(): Void {}
}
```

**Traditional approach (broken)**:
- Generates: `/lib/TodoAppRouter.ex` ❌ 
- Phoenix can't find it, gets module loading errors

**Reflaxe.Elixir approach (working)**:
- Generates: `/lib/todo_app_web/router.ex` ✅
- Phoenix finds it exactly where expected

## Architecture Components

### 1. Annotation Detection System

**Location**: `src/reflaxe/elixir/helpers/AnnotationSystem.hx`

Detects framework annotations on classes:
- `@:router` - Phoenix router modules  
- `@:liveview` - Phoenix LiveView components
- `@:controller` - Phoenix controllers
- `@:schema` - Ecto schemas
- `@:migration` - Ecto migrations

### 2. Framework Path Mapping

**Location**: `src/reflaxe/elixir/ElixirCompiler.hx`

The `setFrameworkAwareOutputPath()` method calculates correct Phoenix paths:

```haxe
switch (annotationInfo.primaryAnnotation) {
    case ":router":
        // TodoAppRouter → router.ex in todo_app_web/
        fileName = "router";
        dirPath = appName + "_web";
        
    case ":liveview":
        // UserLive → user_live.ex in app_web/live/
        var liveViewName = toSnakeCase(className.replace("Live", ""));
        fileName = liveViewName + "_live";
        dirPath = appName + "_web/live";
        
    case ":schema":
        // User → user.ex in app/schemas/
        var schemaName = toSnakeCase(className);
        fileName = schemaName;
        dirPath = appName + "/schemas";
}
```

### 3. Reflaxe Integration

Uses Reflaxe's built-in file placement system:

```haxe
// Set the file output overrides using Reflaxe's built-in system
setOutputFileName(fileName);    // router.ex
setOutputFileDir(dirPath);     // todo_app_web/
```

This approach is superior because:
- ✅ **No post-compilation file moves** needed
- ✅ **Integrates properly** with Reflaxe's OutputManager
- ✅ **Respects Reflaxe's file tracking** and cleanup
- ✅ **Works with all Reflaxe features** (source maps, etc.)

## Phoenix Convention Mapping

### Router Files
- **Pattern**: `@:router` classes → `/lib/{app}_web/router.ex`
- **Example**: `TodoAppRouter.hx` → `/lib/todo_app_web/router.ex`

### LiveView Components  
- **Pattern**: `@:liveview` classes → `/lib/{app}_web/live/{name}_live.ex`
- **Example**: `UserLive.hx` → `/lib/todo_app_web/live/user_live.ex`

### Controllers
- **Pattern**: `@:controller` classes → `/lib/{app}_web/controllers/{name}.ex`
- **Example**: `UserController.hx` → `/lib/todo_app_web/controllers/user_controller.ex`

### Schemas
- **Pattern**: `@:schema` classes → `/lib/{app}/schemas/{name}.ex`  
- **Example**: `User.hx` → `/lib/todo_app/schemas/user.ex`

### Migrations
- **Pattern**: `@:migration` classes → `/priv/repo/migrations/{timestamp}_{name}.exs`
- **Example**: `CreateUsers.hx` → `/priv/repo/migrations/20250813120000_create_users.exs`

## Implementation Details

### App Name Extraction

The `extractAppName()` utility converts class names to app names:

```haxe
private function extractAppName(className: String): String {
    // Remove common Phoenix suffixes and convert to snake_case
    var appPart = className.replace("Router", "")
                           .replace("Live", "")
                           .replace("Controller", "");
    
    return toSnakeCase(appPart);  // TodoApp → todo_app
}
```

### Snake Case Conversion

The `toSnakeCase()` utility handles PascalCase → snake_case:

```haxe
private function toSnakeCase(name: String): String {
    var result = "";
    for (i in 0...name.length) {
        var char = name.charAt(i);
        if (char >= "A" && char <= "Z" && i > 0) {
            result += "_";
        }
        result += char.toLowerCase();
    }
    return result;  // TodoApp → todo_app
}
```

## Default Behavior (1:1 Mapping)

Classes **without** framework annotations use default 1:1 mapping:
- `MyClass.hx` → `/lib/MyClass.ex`
- No directory transformation
- Standard Reflaxe file output behavior

## Benefits of This Architecture

### 1. **Zero Configuration Framework Integration**
Generated files work immediately with Phoenix without any manual file moves or configuration.

### 2. **Developer Experience**
- Write natural Haxe class names (`TodoAppRouter`)
- Get correct Phoenix file locations automatically (`todo_app_web/router.ex`)
- No need to think about target framework file conventions

### 3. **Ecosystem Compatibility**
- Phoenix compilation works out of the box
- Mix tasks find files where expected
- IDE tooling recognizes standard Phoenix structure

### 4. **Maintainability**
- Single source of truth for file location logic
- Easy to add new framework conventions
- Respects Reflaxe's architecture patterns

## Debugging File Generation

### Check Generated File Locations

```bash
# View all generated files and their locations
cat lib/_GeneratedFiles.txt

# Should show framework-aware paths like:
# todo_app_web/router.ex
# todo_app_web/live/todo_live.ex  
# todo/schemas/todo.ex
```

### Enable Debug Output

Add debug flags to compilation:

```hxml
-D source-map     # Enable source mapping
-D debug-output   # Show file generation details
```

### Common Issues

**Double file extensions (`.ex.ex`)**:
- Cause: Adding `fileExtension` manually when Reflaxe adds it automatically
- Fix: Use bare filenames without extensions in `setOutputFileName()`

**Files in wrong locations**:
- Cause: Annotation not detected or mapping logic missing
- Debug: Check that class has proper annotation (`@:router`, `@:liveview`, etc.)

**Phoenix compilation errors**:
- Often indicates files not where Phoenix expects them
- Verify `/lib/{app}_web/router.ex` exists for routers
- Check `/lib/{app}_web/live/` for LiveView components

## Future Extensions

This architecture can easily support additional frameworks:

### Potential Extensions
- **Nerves**: Device-specific file locations
- **LiveBook**: Notebook-aware output paths  
- **Broadway**: Data pipeline conventions
- **Oban**: Job processing file organization

### Adding New Framework Support

1. **Add annotation detection** in `AnnotationSystem.hx`
2. **Add path mapping** in `setFrameworkAwareOutputPath()`
3. **Document conventions** in this file
4. **Add tests** to validate file placement

## Related Documentation

- [Phoenix Router DSL Documentation](ROUTER_DSL.md)
- [Framework Conventions Guide](FRAMEWORK_CONVENTIONS.md)
- [Architecture Overview](ARCHITECTURE.md)
- [Testing File Generation](architecture/TESTING.md)

---

**Last Updated**: August 2025  
**Status**: Production Ready ✅