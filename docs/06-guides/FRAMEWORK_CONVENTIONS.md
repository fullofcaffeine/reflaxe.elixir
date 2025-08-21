# Framework Convention Adherence Guide

## Overview

**Critical Principle**: Generated Elixir code MUST follow target framework conventions exactly, not just be syntactically correct Elixir.

This document outlines how Reflaxe.Elixir ensures generated code integrates seamlessly with Phoenix and other Elixir frameworks by following their established conventions for file locations, module naming, and directory structure.

## Table of Contents
- [Phoenix Framework Conventions](#phoenix-framework-conventions)
- [File Location Mapping](#file-location-mapping)
- [Module Naming Conventions](#module-naming-conventions)
- [Directory Structure Requirements](#directory-structure-requirements)
- [Compiler Implementation Requirements](#compiler-implementation-requirements)
- [Debugging Framework Integration Issues](#debugging-framework-integration-issues)

## Phoenix Framework Conventions

### Phoenix 1.7 Standard Directory Structure

Phoenix applications follow a strict directory structure that tools, libraries, and developers expect:

```
my_app/
├── lib/
│   ├── my_app/                    # Application modules
│   │   ├── application.ex         # OTP Application
│   │   ├── repo.ex               # Ecto Repository
│   │   └── schemas/              # Database schemas
│   │       └── user.ex
│   └── my_app_web/               # Web interface modules
│       ├── controllers/          # Phoenix Controllers
│       ├── live/                # LiveView modules
│       ├── components/          # Phoenix Components
│       ├── router.ex            # Phoenix Router (CRITICAL)
│       ├── endpoint.ex          # Phoenix Endpoint
│       └── gettext.ex           # Internationalization
├── priv/
│   └── repo/
│       └── migrations/          # Database migrations
└── assets/                      # Frontend assets
```

### Module Naming Patterns

Phoenix follows specific module naming conventions:

```elixir
# Application modules
MyApp.Application           # OTP Application
MyApp.Repo                 # Ecto Repository  
MyApp.Schemas.User         # Database schemas

# Web modules
MyAppWeb.Router            # Router (MOST CRITICAL)
MyAppWeb.Endpoint          # Endpoint
MyAppWeb.UserController    # Controllers
MyAppWeb.UserLive          # LiveView modules
MyAppWeb.CoreComponents    # Components
```

## File Location Mapping

### Critical Mapping Rules

Reflaxe.Elixir compilers MUST implement framework-aware file location logic:

| Haxe Source | Framework Expected Location | Generated Module |
|-------------|---------------------------|------------------|
| `Router.hx` | `/lib/app_web/router.ex` | `AppWeb.Router` |
| `UserController.hx` | `/lib/app_web/controllers/user_controller.ex` | `AppWeb.UserController` |
| `UserLive.hx` | `/lib/app_web/live/user_live.ex` | `AppWeb.UserLive` |
| `User.hx` (schema) | `/lib/app/schemas/user.ex` | `App.Schemas.User` |
| `CreateUsers.hx` | `/priv/repo/migrations/[timestamp]_create_users.exs` | N/A (migration) |

### RouterCompiler Critical Requirements

**MOST IMPORTANT**: The router file location is critical for Phoenix to function:

```haxe
// ❌ WRONG: Current RouterCompiler behavior
// Generates: /lib/TodoAppRouter.ex
// Module: TodoAppRouter

// ✅ CORRECT: Required behavior  
// Generates: /lib/todo_app_web/router.ex
// Module: TodoAppWeb.Router
```

**Why this matters**: Phoenix's `use MyAppWeb, :router` expects the router module to be available at the correct location for compilation and runtime loading.

## Module Naming Conventions

### Transformation Rules

Reflaxe.Elixir must transform Haxe naming to Elixir/Phoenix conventions:

#### 1. Class Name Transformations
```haxe
// Haxe class names → Elixir module names
TodoAppRouter     → TodoAppWeb.Router
UserController    → TodoAppWeb.UserController  
TodoSchema        → TodoApp.Schemas.Todo
CreateTodos       → N/A (migration filename)
UserLive          → TodoAppWeb.UserLive
```

#### 2. File Name Transformations  
```haxe
// Haxe class names → Elixir file names
TodoAppRouter     → router.ex
UserController    → user_controller.ex
TodoSchema        → todo.ex
CreateTodos       → [timestamp]_create_todos.exs
UserLive          → user_live.ex
```

#### 3. Package Structure Mapping
```haxe
// Haxe packages → Phoenix directories
package controllers;    → /lib/app_web/controllers/
package live;          → /lib/app_web/live/  
package schemas;       → /lib/app/schemas/
package migrations;    → /priv/repo/migrations/
```

## Directory Structure Requirements

### Web Module Structure

Phoenix web modules must be placed in the `app_web` directory:

```
lib/todo_app_web/
├── router.ex              # Main router (CRITICAL)
├── endpoint.ex            # Application endpoint
├── controllers/           # HTTP controllers
│   ├── user_controller.ex
│   └── page_controller.ex
├── live/                  # LiveView modules
│   ├── user_live.ex
│   └── counter_live.ex
└── components/            # Reusable components
    └── core_components.ex
```

### Application Module Structure

Application logic modules go in the main `app` directory:

```
lib/todo_app/
├── application.ex         # OTP Application
├── repo.ex               # Ecto Repository
└── schemas/              # Database schemas
    ├── user.ex
    └── todo.ex
```

### Migration Structure

Database migrations have special naming requirements:

```
priv/repo/migrations/
├── 20250813123456_create_users.exs
├── 20250813123500_create_todos.exs
└── 20250813123600_add_index_to_users.exs
```

## Compiler Implementation Requirements

### Framework-Aware File Location Logic

All Reflaxe.Elixir helper compilers MUST implement framework detection and appropriate file placement:

```haxe
public static function generateOutputPath(className: String, classType: ClassType): String {
    // 1. Detect target framework
    var framework = detectFramework(classType);
    
    // 2. Apply framework-specific conventions
    return switch(framework) {
        case Phoenix:
            generatePhoenixPath(className, classType);
        case OTP:
            generateOTPPath(className, classType);
        case Plain:
            generatePlainElixirPath(className, classType);
    }
}

private static function generatePhoenixPath(className: String, classType: ClassType): String {
    if (RouterCompiler.isRouterClassType(classType)) {
        var appName = extractAppName(className);
        return '/lib/${appName}_web/router.ex';
    }
    
    if (SchemaCompiler.isSchemaClassType(classType)) {
        var appName = extractAppName(className);
        var schemaName = extractSchemaName(className);
        return '/lib/${appName}/schemas/${schemaName}.ex';
    }
    
    // Additional Phoenix conventions...
}
```

### Required Helper Compiler Updates

#### RouterCompiler.hx
- **Current Issue**: Generates files based on Haxe class name without framework awareness
- **Required Fix**: Phoenix-aware path generation for `/lib/app_web/router.ex`
- **Module Name**: Correctly generates `AppWeb.Router` (already working)

#### SchemaCompiler.hx  
- **Verify**: Generates schemas in `/lib/app/schemas/` directory
- **Module Pattern**: `App.Schemas.ModelName`

#### LiveViewCompiler.hx
- **Verify**: Generates LiveViews in `/lib/app_web/live/` directory  
- **Module Pattern**: `AppWeb.LiveViewName`

#### MigrationDSL.hx
- **Verify**: Generates migrations in `/priv/repo/migrations/` with timestamps
- **File Pattern**: `[timestamp]_migration_name.exs`

## Debugging Framework Integration Issues

### Common Symptoms and Root Causes

| Symptom | Likely Root Cause | Debug Steps |
|---------|------------------|-------------|
| `Phoenix.plug_init_mode/0 undefined` | Router file in wrong location | Check `/lib/app_web/router.ex` exists |
| `Module not found` errors | File path doesn't match module name | Verify module name matches file location |
| Compilation timeouts | Circular dependencies from wrong imports | Check generated import statements |
| `Function undefined` | Module not loaded due to wrong location | Verify Phoenix can find the module |

### Framework Error Translation

**Key Insight**: Framework compilation errors usually indicate file location/structure problems, not language compatibility issues.

#### Debug Workflow
```bash
# 1. Check file locations first
find lib/ -name "*.ex" | grep -E "(router|live|controller)"

# 2. Verify Phoenix directory structure
ls -la lib/app_web/
ls -la lib/app/schemas/

# 3. Check module names in files
grep "defmodule" lib/app_web/router.ex
grep "defmodule" lib/app_web/live/*.ex

# 4. Clean and regenerate with correct paths
rm -rf _build lib/*.ex
npx haxe build.hxml
mix compile
```

### RouterCompiler Debugging Example

The RouterCompiler debugging session revealed this critical pattern:

**Problem**: `Phoenix.plug_init_mode/0` error during `mix ecto.create`

**Wrong Assumption**: Phoenix version incompatibility or deprecated function usage

**Actual Cause**: Router generated at `/lib/TodoAppRouter.ex` instead of `/lib/todo_app_web/router.ex`

**Solution**: Fix RouterCompiler to generate files in Phoenix-expected locations

## Related Documentation

- **[`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md)** - Complete RouterCompiler file location architecture
- **[`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md)** - Framework integration debugging patterns
- **[Phoenix Directory Structure Guide](https://hexdocs.pm/phoenix/directory_structure.html)** - Official Phoenix conventions
- **[Elixir Naming Conventions](https://hexdocs.pm/elixir/naming-conventions.html)** - Official Elixir style guide