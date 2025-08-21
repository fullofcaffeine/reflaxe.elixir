# Module Resolution Roadmap for Reflaxe.Elixir

## Overview

This roadmap outlines the progressive enhancement strategy for automatic module naming in Reflaxe.Elixir, moving from explicit annotations to intelligent convention-based detection while maintaining framework-agnostic architecture.

## Current State: Framework-Agnostic Foundation ✅

**Status**: IMPLEMENTED (v1.0)

### What We Have
- **@:native annotation support**: Explicit module name control
- **Framework-agnostic compiler**: No hardcoded Phoenix assumptions
- **Type-based module resolution**: RouterBuildMacro uses proper type lookup
- **Clean separation**: Business logic vs framework conventions

### Current Usage Pattern
```haxe
// Explicit control with @:native
@:native("TodoAppWeb.TodoLive")
@:liveview
class TodoLive {
    // Implementation
}

// Generates: TodoAppWeb.TodoLive module in Phoenix convention
// File: lib/todo_app_web/live/todo_live.ex
```

### Architectural Principle Established
**Framework conventions are applied via annotations, not compiler assumptions.**

This ensures the compiler can target any Elixir application pattern (Phoenix, Nerves, pure OTP) without modification.

## Research Findings: Phoenix and Haxe Conventions

### Phoenix Module Naming Patterns
Based on analysis of `/haxe.elixir.reference/phoenix-liveview-chat-example/`:

```elixir
// Phoenix Convention: AppNameWeb.ModuleName
defmodule LiveviewChatWeb.MessageLive do    // ← Web module
defmodule LiveviewChat.Message do           // ← Business logic module

// Directory mapping:
lib/liveview_chat_web/live/message_live.ex  // ← Web components
lib/liveview_chat/message.ex                // ← Business logic
```

### Haxe Package System Analysis
From `/haxe.elixir.reference/haxe/` and Reflaxe implementations:

```haxe
package server.live;              // ← Package declaration
// Maps to: server/live/ClassName.hx

package contexts;                 // ← Business logic package  
// Maps to: contexts/ClassName.hx
```

### Natural Mapping Discovery
**Key Insight**: Haxe packages can map directly to Phoenix conventions:

```haxe
// Haxe Structure        →    Phoenix Module
package server.live     →      AppNameWeb.ClassName
package contexts        →      AppName.ClassName  
package channels        →      AppNameWeb.ClassName
package controllers     →      AppNameWeb.ClassName
```

## Phase 1: Project-Level Configuration 🎯

**Target**: v1.1 (Next minor version)  
**Effort**: Medium  
**Value**: High developer experience improvement

### Goal
Enable project-level annotation to automatically apply naming conventions without per-class annotations.

### Implementation
```haxe
// Project-level configuration
@:elixirProject({
    name: "TodoApp",
    webNamespace: "TodoAppWeb", 
    conventions: {
        "server.live": "web",      // Maps to TodoAppWeb.*
        "server.channels": "web",  // Maps to TodoAppWeb.*
        "contexts": "app",         // Maps to TodoApp.*
        "schemas": "app"           // Maps to TodoApp.*
    }
})
class ProjectConfig {}

// Now classes can omit @:native:
@:liveview
class TodoLive {  // Automatically becomes TodoAppWeb.TodoLive
    // Implementation
}
```

### Benefits
- **Reduced boilerplate**: No per-class @:native annotations needed
- **Project consistency**: Centralized naming configuration
- **Migration friendly**: @:native still works for exceptions
- **Framework agnostic**: Works for any Elixir application structure

### Implementation Strategy
1. **Create ProjectConfigCompiler.hx** helper for parsing @:elixirProject
2. **Extend getNameOrNative()** to check project configuration
3. **Add fallback logic**: @:native → project config → package name
4. **Comprehensive testing** with different project structures

## Phase 2: Convention-Based Detection 🚀

**Target**: v1.2  
**Effort**: High  
**Value**: Excellent developer experience

### Goal
Automatically detect project structure and apply appropriate conventions without any configuration.

### Smart Detection Logic
```haxe
// Automatic detection based on directory analysis:

1. **Scan for mix.exs** to identify Elixir project
2. **Extract app name** from mix.exs configuration  
3. **Detect Phoenix** by checking for phoenix dependency
4. **Map packages** using convention table:

package server.live     → {appName}Web.{ClassName}
package server.channels → {appName}Web.{ClassName}
package contexts        → {appName}.{ClassName}
package schemas         → {appName}.{ClassName}

// Fallback: package.subpackage → Package.Subpackage.ClassName
```

### Enhanced Package Mapping
```haxe
// Convention Detection Examples:

// Phoenix Project (detected from mix.exs deps)
package server.live.TodoLive    → TodoAppWeb.TodoLive
package contexts.Users          → TodoApp.Users
package schemas.User            → TodoApp.User

// Plain Elixir Project (no Phoenix)  
package workers.EmailWorker     → Workers.EmailWorker
package services.PaymentService → Services.PaymentService
```

### Implementation Components
1. **ProjectDetector.hx**: Analyze mix.exs and project structure
2. **ConventionMapper.hx**: Apply detected conventions to packages
3. **ConfigCache**: Cache detection results for performance
4. **Override mechanisms**: @:native and @:elixirProject still work

### Benefits
- **Zero configuration**: Works out of the box for standard projects
- **Phoenix-aware**: Understands Phoenix conventions automatically  
- **Elixir-compatible**: Works with any Elixir application structure
- **Performance**: Caches detection results for fast compilation

## Phase 3: Zero-Configuration Mode 🎆

**Target**: v2.0 (Major version)  
**Effort**: High  
**Value**: Industry-leading developer experience

### Goal
Provide completely automatic module resolution with intelligent project analysis and convention inference.

### Advanced Intelligence Features
```haxe
// Enhanced project analysis:

1. **Deep Project Analysis**
   - Parse mix.exs dependencies for framework detection
   - Analyze existing .ex files for naming patterns
   - Detect custom conventions in existing codebase

2. **Framework Pattern Recognition**
   - Phoenix: Automatic Web/App module separation
   - Nerves: Device/firmware module conventions
   - OTP: Application/supervisor hierarchies
   - Custom: Learn from existing module patterns

3. **Package Intelligence**
   - Suggest optimal package structures
   - Warn about convention violations
   - Auto-correct common naming issues
```

### Smart Convention Examples
```haxe
// Zero-config automatically determines:

// TodoApp (Phoenix) project:
class TodoLive                → TodoAppWeb.TodoLive
class UserContext             → TodoApp.UserContext
class PaymentChannel          → TodoAppWeb.PaymentChannel

// NervesDevice (Nerves) project:
class SensorWorker            → NervesDevice.SensorWorker
class RadioFirmware           → NervesDevice.RadioFirmware

// ChatServer (OTP) project:
class MessageSupervisor       → ChatServer.MessageSupervisor
class ConnectionPool          → ChatServer.ConnectionPool
```

### Implementation Architecture
1. **FrameworkDetector**: Identify framework patterns and conventions
2. **PatternLearner**: Analyze existing codebase for custom conventions
3. **ConventionSuggester**: Provide IDE-level naming suggestions
4. **ValidationEngine**: Warn about naming inconsistencies
5. **MigrationAssistant**: Help migrate from manual to automatic naming

## Implementation Timeline

### Phase 1: Project Configuration (v1.1)
- **Week 1-2**: ProjectConfigCompiler implementation
- **Week 3**: Integration with existing getNameOrNative system
- **Week 4**: Testing and documentation

### Phase 2: Convention Detection (v1.2)
- **Week 1-3**: ProjectDetector and ConventionMapper
- **Week 4-5**: Phoenix and Elixir pattern recognition
- **Week 6**: Performance optimization and caching
- **Week 7**: Comprehensive testing

### Phase 3: Zero-Configuration (v2.0)
- **Month 1**: Advanced project analysis
- **Month 2**: Framework pattern recognition
- **Month 3**: Pattern learning and suggestion systems
- **Month 4**: Migration tools and comprehensive testing

## Risk Mitigation

### Backward Compatibility
- **Always preserve @:native**: Manual override always works
- **Graceful degradation**: Falls back to package names if detection fails
- **Migration path**: Easy upgrade from explicit to automatic

### Performance Considerations
- **Caching**: Project analysis cached for compilation performance
- **Lazy detection**: Only analyze when needed
- **Incremental updates**: Re-analyze only when project files change

### Framework Support
- **Phoenix first**: Primary target for convention detection
- **Extensible patterns**: Easy to add new framework conventions
- **Custom projects**: Support for non-standard naming patterns

## Validation Strategy

### Testing Approach
1. **Unit tests**: Each phase component independently tested
2. **Integration tests**: Full compilation with various project structures
3. **Real-world validation**: Test with actual Phoenix/Elixir projects
4. **Performance benchmarks**: Ensure no compilation slowdown

### User Experience Validation
1. **Developer feedback**: Early preview with community input
2. **Migration testing**: Validate smooth upgrade paths
3. **IDE integration**: Ensure naming suggestions work well
4. **Documentation**: Comprehensive guides for each phase

## Success Metrics

### Phase 1 Success Criteria
- ✅ Reduce @:native annotations by 80% in typical projects
- ✅ Zero configuration needed for standard Phoenix projects
- ✅ Compilation time impact < 5ms

### Phase 2 Success Criteria  
- ✅ 100% automatic naming for standard Phoenix/Elixir projects
- ✅ Accurate framework detection in 95% of projects
- ✅ Developer satisfaction > 90% in user surveys

### Phase 3 Success Criteria
- ✅ Industry-leading developer experience
- ✅ Zero learning curve for new developers  
- ✅ Automatic migration tools for existing projects
- ✅ Support for custom frameworks and conventions

## Implementation Priority

### High Priority (Phase 1)
Essential for improving current developer experience with minimal risk.

### Medium Priority (Phase 2)  
Significant value with manageable complexity and established patterns.

### Future Vision (Phase 3)
Aspirational goal that positions Reflaxe.Elixir as the best-in-class transpiler for developer experience.

## Convention Detection Examples

### Phoenix Project Structure Mapping

Based on analysis of real Phoenix projects, here are the discovered convention patterns:

#### Phoenix LiveView Chat Example
```
Project Structure:
lib/liveview_chat_web/live/message_live.ex → LiveviewChatWeb.MessageLive
lib/liveview_chat/message.ex → LiveviewChat.Message

Haxe Package Mapping:
package server.live;     → LiveviewChatWeb.MessageLive
package contexts;        → LiveviewChat.Message
```

#### Todo-App Example (Current Implementation)
```
Explicit @:native Approach:
@:native("TodoAppWeb.TodoLive")
package server.live;
class TodoLive → TodoAppWeb.TodoLive

@:native("TodoApp.User")  
package schemas;
class User → TodoApp.User
```

#### Future Convention Detection
```
Automatic Detection Pattern:
package server.live;     → {AppName}Web.{ClassName}
package server.channels; → {AppName}Web.{ClassName}
package contexts;        → {AppName}.{ClassName}
package schemas;         → {AppName}.{ClassName}

Example Results:
server.live.TodoLive     → TodoAppWeb.TodoLive
server.channels.UserChannel → TodoAppWeb.UserChannel
contexts.Users           → TodoApp.Users
schemas.Todo             → TodoApp.Todo
```

### Convention Detection Algorithm

#### Step 1: Project Analysis
```
1. Scan for mix.exs to identify Elixir project
2. Extract app name from mix.exs (e.g., :todo_app)
3. Convert to PascalCase (todo_app → TodoApp)
4. Check for Phoenix dependency in mix.exs
5. Determine if Web module pattern is used
```

#### Step 2: Package Convention Mapping
```
Phoenix Project Conventions:
- server.live.*     → AppNameWeb.*
- server.channels.* → AppNameWeb.*
- controllers.*     → AppNameWeb.*
- live.*           → AppNameWeb.*
- contexts.*       → AppName.*
- schemas.*        → AppName.*

Plain Elixir Project Conventions:
- workers.*        → Workers.*
- services.*       → Services.*
- utils.*          → Utils.*
- All others       → Package.Subpackage.ClassName
```

#### Step 3: File Structure Verification
```
Generated File Locations:
AppNameWeb.* → lib/app_name_web/
AppName.*    → lib/app_name/

Directory Creation:
lib/todo_app_web/live/todo_live.ex    (from server.live.TodoLive)
lib/todo_app/schemas/todo.ex          (from schemas.Todo)
lib/todo_app/contexts/users.ex        (from contexts.Users)
```

### Gradual Migration Examples

#### Current State: Explicit @:native
```haxe
// Manual annotation for each class
@:native("TodoAppWeb.TodoLive")
@:liveview
class TodoLive {}

@:native("TodoApp.User")
@:schema("users")
class User {}
```

#### Phase 1: Project Configuration
```haxe
// Single project-level configuration
@:elixirProject({
    name: "TodoApp",
    conventions: {
        "server.live": "web",
        "contexts": "app",
        "schemas": "app"
    }
})
class ProjectConfig {}

// Classes now work automatically
@:liveview
class TodoLive {} // → TodoAppWeb.TodoLive

@:schema("users")
class User {}     // → TodoApp.User
```

#### Phase 2: Convention Detection
```haxe
// Zero configuration needed
@:liveview
class TodoLive {} // Automatically → TodoAppWeb.TodoLive
// (detected from mix.exs Phoenix dependency + package server.live)

@:schema("users")
class User {}     // Automatically → TodoApp.User
// (detected from mix.exs app name + package schemas)
```

### Real-World Integration Examples

#### Migrating Existing Phoenix App
```
Step 1: Add @:native to existing classes
@:native("MyAppWeb.UserLive")
class UserLive extends LiveView {}

Step 2: Test compilation and functionality
mix compile && mix test

Step 3: Remove @:native and add project config
@:elixirProject({name: "MyApp"})

Step 4: Verify same output generated
diff lib/my_app_web/live/user_live.ex

Step 5: Migrate to full automatic detection
(Remove project config, rely on convention detection)
```

#### Custom Framework Integration
```haxe
// Nerves Project Example
@:elixirProject({
    name: "MyDevice",
    conventions: {
        "sensors": "app",
        "firmware": "app", 
        "protocols": "app"
    }
})

// Results in:
sensors.TemperatureSensor  → MyDevice.TemperatureSensor
firmware.RadioFirmware     → MyDevice.RadioFirmware
protocols.MqttProtocol     → MyDevice.MqttProtocol
```

### Error Detection and Validation

#### Convention Conflict Detection
```
Warning: Package 'server.live' maps to 'TodoAppWeb' but class already has @:native("TodoApp.TodoLive")
Suggestion: Remove @:native to use convention, or adjust project configuration

Warning: Phoenix dependency detected but no 'Web' modules found
Suggestion: Consider using web package conventions (server.live, controllers, etc.)
```

#### Directory Structure Validation
```
Error: Generated module TodoAppWeb.TodoLive would create lib/todo_app_web/live/todo_live.ex
but lib/todo_app_web/ directory doesn't exist
Suggestion: Create Phoenix web directory structure or adjust module naming
```

### IDE Integration Examples

#### VS Code Extension Support
```
Feature: Auto-suggest @:native based on package
Package: server.live.TodoLive
Suggestion: @:native("TodoAppWeb.TodoLive")

Feature: Show generated module name in hover
class TodoLive // → Generates: TodoAppWeb.TodoLive
File: lib/todo_app_web/live/todo_live.ex
```

#### IntelliJ IDEA Integration
```
Feature: Navigate from Haxe to generated Elixir
Right-click → "Go to Generated Elixir Module"

Feature: Validate naming conventions
Highlight: Non-standard package patterns
Quick-fix: "Apply Phoenix conventions"
```

---

**Next Steps**: Begin Phase 1 implementation with ProjectConfigCompiler.hx and @:elixirProject annotation support.