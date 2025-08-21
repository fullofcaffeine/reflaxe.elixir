# Phoenix Directory Structure: Conventions vs Haxe Organization

## Overview

This document explains the standard Phoenix directory structure, how Reflaxe.Elixir maps Haxe packages to Phoenix conventions, and why we sometimes diverge from Phoenix patterns while still generating idiomatic Elixir code.

## Standard Phoenix Directory Structure

### Phoenix 1.7+ Convention
```
my_app/
├── lib/
│   ├── my_app/                    # Business logic layer
│   │   ├── application.ex         # OTP application supervisor
│   │   ├── repo.ex                # Ecto repository
│   │   ├── mailer.ex              # Email service
│   │   ├── accounts/              # Context modules
│   │   │   ├── user.ex           # Schema
│   │   │   └── accounts.ex       # Context API
│   │   └── catalog/               # Another context
│   │       ├── product.ex        # Schema
│   │       └── catalog.ex        # Context API
│   │
│   └── my_app_web/                # Web layer (Phoenix-specific)
│       ├── endpoint.ex            # HTTP endpoint configuration
│       ├── router.ex              # URL routing
│       ├── telemetry.ex          # Metrics/monitoring
│       ├── gettext.ex            # Internationalization
│       ├── controllers/          # HTTP controllers
│       ├── live/                 # LiveView modules
│       ├── components/           # Reusable UI components
│       └── templates/            # EEx/HEEx templates
│
├── priv/
│   ├── repo/
│   │   └── migrations/           # Database migrations
│   └── static/                   # Static assets
│
└── config/                       # Environment configuration
```

### Key Phoenix Principles

1. **Separation of Concerns**: Clear boundary between business logic (`lib/my_app/`) and web layer (`lib/my_app_web/`)
2. **Context-Based Organization**: Business logic grouped into contexts (Accounts, Catalog, etc.)
3. **Flat Module Structure**: Core infrastructure directly under app namespace (Repo, Mailer, Application)
4. **Web Suffix Convention**: All web-related modules under `MyAppWeb` namespace

## Reflaxe.Elixir Haxe Organization

### Our Haxe Structure
```
src_haxe/
├── TodoApp.hx                    # @:application - Entry point
├── TodoAppRouter.hx              # @:router - URL routing
├── server/
│   ├── infrastructure/           # Infrastructure layer (DDD-inspired)
│   │   ├── Repo.hx              # @:repo - Database repository
│   │   ├── Endpoint.hx          # @:endpoint - HTTP endpoint
│   │   └── Telemetry.hx         # Metrics/monitoring
│   │
│   ├── schemas/                  # Domain models
│   │   ├── Todo.hx              # @:schema - Ecto schema
│   │   └── User.hx              # @:schema - Ecto schema
│   │
│   ├── contexts/                 # Business logic contexts
│   │   ├── Todos.hx             # Todo operations
│   │   └── Users.hx             # User operations
│   │
│   ├── live/                     # LiveView modules
│   │   ├── TodoLive.hx          # @:liveview
│   │   └── UserLive.hx          # @:liveview
│   │
│   └── controllers/              # HTTP controllers
│       └── UserController.hx     # REST API controller
│
└── client/                       # Client-side Haxe code
    └── TodoApp.hx               # Browser entry point
```

## Mapping Strategy: Haxe → Phoenix

### How @:native Annotations Bridge the Gap

The `@:native` annotation allows us to use any Haxe package structure while generating Phoenix-conventional module names:

```haxe
// Haxe location: server/infrastructure/Repo.hx
package server.infrastructure;

@:native("TodoApp.Repo")  // Generates: lib/todo_app/repo.ex
@:repo
extern class Repo { }
```

### Compilation Mapping Examples

| Haxe Package/Class | @:native Annotation | Generated Elixir Module | Phoenix Location |
|-------------------|---------------------|------------------------|------------------|
| `server.infrastructure.Repo` | `@:native("TodoApp.Repo")` | `TodoApp.Repo` | `lib/todo_app/repo.ex` |
| `server.live.TodoLive` | `@:native("TodoAppWeb.TodoLive")` | `TodoAppWeb.TodoLive` | `lib/todo_app_web/live/todo_live.ex` |
| `TodoAppRouter` | `@:native("TodoAppWeb.Router")` | `TodoAppWeb.Router` | `lib/todo_app_web/router.ex` |
| `server.infrastructure.Endpoint` | `@:native("TodoAppWeb.Endpoint")` | `TodoAppWeb.Endpoint` | `lib/todo_app_web/endpoint.ex` |
| `server.schemas.Todo` | `@:native("TodoApp.Schemas.Todo")` | `TodoApp.Schemas.Todo` | `lib/todo_app/schemas/todo.ex` |

## Why We Use Different Organization in Haxe

### 1. Domain-Driven Design (DDD) Alignment
```
server/
├── infrastructure/    # Technical concerns (DB, HTTP, messaging)
├── schemas/          # Domain models
├── contexts/         # Domain services
└── live/            # Presentation layer
```

**Benefits:**
- Clear architectural boundaries in Haxe code
- Easier to reason about dependencies
- Better for larger applications with complex domains

### 2. Client-Server Code Sharing
```
src_haxe/
├── server/          # Server-only code
├── client/          # Client-only code
└── shared/          # Shared types and logic
```

**Benefits:**
- Single source of truth for shared types
- Type-safe client-server communication
- Code reuse between targets

### 3. Type-First Development
Our structure emphasizes types and interfaces first:
```haxe
// Define types in one place
server/types/Types.hx      // All type definitions

// Use throughout application
import server.types.Types.*;
```

### 4. Framework Agnosticism
The Haxe structure doesn't assume Phoenix:
```
server/infrastructure/    # Could be Phoenix, Plug, or custom
server/schemas/           # Could be Ecto, Mnesia, or custom
```

## Best Practices

### 1. Always Use @:native for Phoenix Modules
```haxe
// ✅ CORRECT: Explicit Phoenix convention
@:native("TodoAppWeb.PageController")
class PageController { }

// ❌ WRONG: Relying on package structure
package todoapp.web.controllers;
class PageController { }  // Generates: TodoApp.Web.Controllers.PageController
```

### 2. Document Non-Standard Locations
```haxe
/**
 * TodoApp Repository
 * 
 * ## Directory Structure Note
 * Located in server/infrastructure/ for DDD organization.
 * Compiles to standard Phoenix location via @:native annotation.
 */
@:native("TodoApp.Repo")
```

### 3. Group Related Functionality
```
server/
├── auth/              # All authentication code
│   ├── Guardian.hx    # JWT handling
│   ├── Plug.hx       # Auth plug
│   └── Pipeline.hx   # Auth pipeline
```

### 4. Use Phoenix Conventions in Generated Code
Even though our Haxe structure differs, the generated Elixir must follow Phoenix patterns:
- Context modules with public APIs
- Private schema functions
- Proper supervisor trees
- Standard configuration patterns

## Migration Guide: Phoenix → Haxe

### Converting Existing Phoenix App

| Phoenix Module | Haxe Location | Required Annotations |
|---------------|--------------|---------------------|
| `MyApp.Repo` | `server/infrastructure/Repo.hx` | `@:native("MyApp.Repo") @:repo` |
| `MyAppWeb.Router` | `MyAppRouter.hx` (root) | `@:native("MyAppWeb.Router") @:router` |
| `MyAppWeb.Endpoint` | `server/infrastructure/Endpoint.hx` | `@:native("MyAppWeb.Endpoint") @:endpoint` |
| `MyApp.Accounts.User` | `server/schemas/User.hx` | `@:native("MyApp.Accounts.User") @:schema` |
| `MyApp.Accounts` | `server/contexts/Accounts.hx` | `@:native("MyApp.Accounts")` |
| `MyAppWeb.UserLive` | `server/live/UserLive.hx` | `@:native("MyAppWeb.UserLive") @:liveview` |

## Framework Detection Roadmap

### Current Status (Manual)
Every module requires explicit `@:native` annotation:
```haxe
@:native("TodoAppWeb.TodoLive")  // Manual for each class
@:liveview
class TodoLive { }
```

### Phase 1: Project-Level Configuration (Planned)
Detect Phoenix project and apply conventions automatically:
```haxe
// In build.hxml or project config
-D phoenix_app=TodoApp

// Classes automatically get correct naming:
@:liveview
class TodoLive { }  // Automatically becomes TodoAppWeb.TodoLive

@:schema
class User { }      // Automatically becomes TodoApp.User
```

### Phase 2: Convention Detection (Future)
Auto-detect framework from project structure:
```haxe
// Compiler detects mix.exs with Phoenix dependency
// Automatically applies Phoenix conventions
// No configuration needed!
```

### Phase 3: Pluggable Conventions (Vision)
Support multiple framework patterns:
```haxe
// Detected patterns:
// - Phoenix: AppName / AppNameWeb split
// - Nerves: Hardware-specific organization  
// - Pure OTP: Flat module structure
// - Custom: User-defined patterns
```

**See also**: [`/documentation/MODULE_RESOLUTION_ROADMAP.md`](/documentation/MODULE_RESOLUTION_ROADMAP.md) for complete module resolution strategy

## Conclusion

The dual-structure approach (Haxe organization + Phoenix output) gives us the best of both worlds:

1. **Development Time**: Organized, type-safe, DDD-aligned Haxe code
2. **Runtime**: Idiomatic Phoenix application structure
3. **Flexibility**: Can target Phoenix, Nerves, or pure OTP without restructuring
4. **Maintainability**: Clear boundaries and explicit dependencies

The `@:native` annotation is the bridge that makes this possible, allowing any Haxe organization while ensuring Phoenix-compliant output.