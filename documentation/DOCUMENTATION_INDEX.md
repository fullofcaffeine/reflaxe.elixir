# 📚 Documentation Index - Reflaxe.Elixir

## Purpose
This index provides a comprehensive guide to all documentation in the Reflaxe.Elixir project, organized by purpose and audience. Use this to quickly find the right documentation for your needs.

## 🎯 Quick Navigation by Need

### "I need to..."

| Need | Documentation | Location |
|------|--------------|----------|
| Get started with the project | Getting Started Guide | [`guides/GETTING_STARTED.md`](guides/GETTING_STARTED.md) |
| Understand the architecture | Architecture Overview | [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md) |
| Understand standard library design | Haxe Stdlib Architecture | [`HAXE_STDLIB_ELIXIR_ARCHITECTURE.md`](HAXE_STDLIB_ELIXIR_ARCHITECTURE.md) |
| Solve field access issues | Abstract Types Solution | [`ABSTRACT_TYPES_SOLUTION.md`](ABSTRACT_TYPES_SOLUTION.md) |
| Write tests | Testing Overview | [`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md) |
| Find code examples | Examples Guide | [`guides/EXAMPLES.md`](guides/EXAMPLES.md) |
| Use annotations | Annotations Reference | [`reference/ANNOTATIONS.md`](reference/ANNOTATIONS.md) |
| Understand paradigm differences | Paradigm Bridge | [`paradigms/PARADIGM_BRIDGE.md`](paradigms/PARADIGM_BRIDGE.md) |
| Work with Phoenix | Phoenix Integration | [`phoenix/HAXE_FOR_PHOENIX.md`](phoenix/HAXE_FOR_PHOENIX.md) |
| Build Phoenix LiveView apps | LiveView Architecture | [`PHOENIX_LIVEVIEW_ARCHITECTURE.md`](PHOENIX_LIVEVIEW_ARCHITECTURE.md) |
| Learn LiveView patterns | LiveView Patterns | [`PHOENIX_LIVEVIEW_PATTERNS.md`](PHOENIX_LIVEVIEW_PATTERNS.md) |
| Implement LiveView features | LiveView Guide | [`guides/PHOENIX_LIVEVIEW_GUIDE.md`](guides/PHOENIX_LIVEVIEW_GUIDE.md) |
| Test LiveView applications | LiveView Testing | [`PHOENIX_LIVEVIEW_TESTING.md`](PHOENIX_LIVEVIEW_TESTING.md) |
| Use modern JavaScript patterns | JavaScript Patterns | [`JAVASCRIPT_PATTERNS.md`](JAVASCRIPT_PATTERNS.md) |
| Understand testing architecture | Testing Architecture | [`TESTING_ARCHITECTURE.md`](TESTING_ARCHITECTURE.md) |
| Find current development plan | Active PRD | [`plans/ACTIVE_PRD.md`](plans/ACTIVE_PRD.md) |
| Reference existing code | Reference implementations | `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` |
| Plan Reflaxe enhancements | Future Modifications | [`../vendor/reflaxe/FUTURE_MODIFICATIONS.md`](../vendor/reflaxe/FUTURE_MODIFICATIONS.md) |

## 📂 Documentation Structure

### 1. User Guides (`/documentation/guides/`)
**Purpose**: Help users get started and be productive with Reflaxe.Elixir

- **[`GETTING_STARTED.md`](guides/GETTING_STARTED.md)** - Installation, setup, first project
- **[`QUICKSTART.md`](guides/QUICKSTART.md)** - Fast track to productivity
- **[`EXAMPLES.md`](guides/EXAMPLES.md)** - Working code examples with explanations
- **[`COOKBOOK.md`](guides/COOKBOOK.md)** - Copy-paste recipes for common tasks
- **[`DEVELOPER_PATTERNS.md`](guides/DEVELOPER_PATTERNS.md)** - Best practices and patterns
- **[`TUTORIAL_FIRST_PROJECT.md`](guides/TUTORIAL_FIRST_PROJECT.md)** - Step-by-step first project
- **[`ROUTER_MIGRATION_GUIDE.md`](guides/ROUTER_MIGRATION_GUIDE.md)** - Phoenix router migration
- **[`ADVANCED_ECTO_GUIDE.md`](guides/ADVANCED_ECTO_GUIDE.md)** - Database integration patterns
- **[`TYPE_SAFE_ASSIGNS.md`](guides/TYPE_SAFE_ASSIGNS.md)** - Type-safe Phoenix assigns and socket abstractions
- **[`WATCHER_DEVELOPMENT_GUIDE.md`](guides/WATCHER_DEVELOPMENT_GUIDE.md)** - File watcher workflow
- **[`PHOENIX_LIVEVIEW_GUIDE.md`](guides/PHOENIX_LIVEVIEW_GUIDE.md)** - **NEW**: Step-by-step Phoenix LiveView implementation with Haxe

### 2. Architecture Documentation (`/documentation/architecture/`)
**Purpose**: Explain system design and implementation details

- **[`ARCHITECTURE.md`](architecture/ARCHITECTURE.md)** - Complete system architecture
- **[`COMPILER_INHERITANCE.md`](architecture/COMPILER_INHERITANCE.md)** - Compiler class hierarchy
- **[`TESTING.md`](architecture/TESTING.md)** - Testing architecture and philosophy
- **[`TESTING_ARCHITECTURE_COMPLETE.md`](architecture/TESTING_ARCHITECTURE_COMPLETE.md)** - Detailed test infrastructure

### 2a. Standard Library Architecture (`/documentation/`)
**Purpose**: Standard library design patterns and solutions

- **[`HAXE_STDLIB_ELIXIR_ARCHITECTURE.md`](HAXE_STDLIB_ELIXIR_ARCHITECTURE.md)** - Haxe stdlib → idiomatic Elixir compilation strategy
- **[`ABSTRACT_TYPES_SOLUTION.md`](ABSTRACT_TYPES_SOLUTION.md)** - Abstract types solution for field access issues
- **[`STANDARD_LIBRARY_COMPILATION_CONTEXT.md`](STANDARD_LIBRARY_COMPILATION_CONTEXT.md)** - Critical learnings about `untyped __elixir__()` in std/
- **[`CRITICAL_ARCHITECTURE_LESSONS.md`](CRITICAL_ARCHITECTURE_LESSONS.md)** - **MANDATORY**: Never repeat architectural mistakes
- **[`ELIXIR_INJECTION_GUIDE.md`](ELIXIR_INJECTION_GUIDE.md)** - Complete `__elixir__()` usage guide with cross-target comparison
- **[`ELIXIR_SYNTAX_IMPLEMENTATION.md`](ELIXIR_SYNTAX_IMPLEMENTATION.md)** - **NEW**: Complete elixir.Syntax implementation analysis and success documentation
- **[`EXTERN_CLASS_SYNTAX_INJECTION.md`](EXTERN_CLASS_SYNTAX_INJECTION.md)** - Extern class vs regular class approaches for syntax injection
- **[`LIX_VENDORED_DEPENDENCIES.md`](LIX_VENDORED_DEPENDENCIES.md)** - **NEW**: Lix vendored dependency management patterns and best practices
- **[`JAVASCRIPT_PATTERNS.md`](JAVASCRIPT_PATTERNS.md)** - **NEW**: Modern Haxe JavaScript patterns, async/await, and DOM handling
- **[`TESTING_ARCHITECTURE.md`](TESTING_ARCHITECTURE.md)** - **NEW**: Complete testing strategy for compiler and applications

### 3. Reference Documentation (`/documentation/reference/`)
**Purpose**: API references and feature specifications

- **[`ANNOTATIONS.md`](reference/ANNOTATIONS.md)** - All supported annotations
- **[`FEATURES.md`](reference/FEATURES.md)** - Feature list and production readiness
- **[`MIX_TASKS.md`](reference/MIX_TASKS.md)** - Available Mix tasks
- **[`EXTERN_CREATION_GUIDE.md`](reference/EXTERN_CREATION_GUIDE.md)** - Creating extern definitions

### 4. Paradigm Documentation (`/documentation/paradigms/`)
**Purpose**: Bridge the gap between imperative Haxe and functional Elixir

- **[`PARADIGM_BRIDGE.md`](paradigms/PARADIGM_BRIDGE.md)** - Comprehensive paradigm transformation guide

### 5. Phoenix Integration (`/documentation/phoenix/`)
**Purpose**: Phoenix-specific patterns and integration

- **[`HAXE_FOR_PHOENIX.md`](phoenix/HAXE_FOR_PHOENIX.md)** - Phoenix development with Haxe advantages
- **[`PHOENIX_DIRECTORY_STRUCTURE.md`](PHOENIX_DIRECTORY_STRUCTURE.md)** - Phoenix conventions vs Haxe organization
- **[`PHOENIX_LIVEVIEW_ARCHITECTURE.md`](PHOENIX_LIVEVIEW_ARCHITECTURE.md)** - **NEW**: Core LiveView philosophy and server-centric patterns
- **[`PHOENIX_LIVEVIEW_PATTERNS.md`](PHOENIX_LIVEVIEW_PATTERNS.md)** - **NEW**: Where Haxe makes LiveView better with compile-time safety
- **[`PHOENIX_LIVEVIEW_TESTING.md`](PHOENIX_LIVEVIEW_TESTING.md)** - **NEW**: Multi-layer testing strategy for LiveView apps

### 6. LLM/AI Documentation (`/documentation/llm/`)
**Purpose**: AI-optimized documentation for agents and LLMs

- **[`LLM_DOCUMENTATION_GUIDE.md`](llm/LLM_DOCUMENTATION_GUIDE.md)** - How to document for AI
- **[`HAXE_FUNDAMENTALS.md`](llm/HAXE_FUNDAMENTALS.md)** - Essential Haxe knowledge
- **[`REFLAXE_ELIXIR_BASICS.md`](llm/REFLAXE_ELIXIR_BASICS.md)** - Core Reflaxe concepts
- **[`QUICK_START_PATTERNS.md`](llm/QUICK_START_PATTERNS.md)** - Copy-paste patterns
- **[`LLM_DEBUGGING_STRATEGY.md`](llm/LLM_DEBUGGING_STRATEGY.md)** - Debugging approach
- **[`LLM_WORKFLOW_COMPATIBILITY.md`](llm/LLM_WORKFLOW_COMPATIBILITY.md)** - Workflow integration

### 7. Plans and PRDs (`/documentation/plans/`)
**Purpose**: Development plans and product requirements

- **[`AGENT_INSTRUCTIONS.md`](plans/AGENT_INSTRUCTIONS.md)** - How to use Shrimp + PRDs
- **[`staging/`](plans/staging/)** - Active development plans
  - **[`README.md`](plans/staging/README.md)** - Current active plan status
  - **[`2025-08-14_paradigm_todoapp_compiler_plan.md`](plans/staging/2025-08-14_paradigm_todoapp_compiler_plan.md)** - Current PRD
- **`approved/`** - Finalized plans
- **`archive/`** - Completed plans

### 8. History and Progress (`/documentation/history/`)
**Purpose**: Track project evolution and learnings

- **[`LEARNINGS.md`](history/LEARNINGS.md)** - Key insights and discoveries

### 9. Testing Documentation (`/documentation/`)
**Purpose**: Comprehensive testing guidance

- **[`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md)** - Complete testing guide for all test types
- **[`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md)** - Core testing philosophy
- **[`TEST_SUITE_DEEP_DIVE.md`](TEST_SUITE_DEEP_DIVE.md)** - What each test validates
- **[`TEST_INFRASTRUCTURE.md`](TEST_INFRASTRUCTURE.md)** - Test system architecture
- **[`TEST_TYPES.md`](TEST_TYPES.md)** - Different test categories
- **[`TEST_ERROR_EXPECTATIONS.md`](TEST_ERROR_EXPECTATIONS.md)** - Error handling in tests

### 10. Core Project Files (Root)
**Purpose**: Project-wide documentation

- **[`TASK_HISTORY.md`](TASK_HISTORY.md)** - Completed task documentation
- **[`SESSION_LESSONS_TYPE_ORGANIZATION.md`](SESSION_LESSONS_TYPE_ORGANIZATION.md)** - Framework type organization lessons
- **[`TROUBLESHOOTING.md`](TROUBLESHOOTING.md)** - Common issues and solutions
- **[`MIX_INTEGRATION.md`](MIX_INTEGRATION.md)** - Mix build system integration
- **[`DEVELOPMENT_TOOLS.md`](DEVELOPMENT_TOOLS.md)** - Development environment setup
- **[`FUNCTIONAL_PATTERNS.md`](FUNCTIONAL_PATTERNS.md)** - Functional programming patterns
- **[`FUNCTIONAL_HELPERS_IMPLEMENTATION.md`](FUNCTIONAL_HELPERS_IMPLEMENTATION.md)** - Helper implementation plan

## 🎭 Documentation by Audience

### For End Users
- Start: [`guides/GETTING_STARTED.md`](guides/GETTING_STARTED.md)
- Examples: [`guides/EXAMPLES.md`](guides/EXAMPLES.md)
- Cookbook: [`guides/COOKBOOK.md`](guides/COOKBOOK.md)
- Features: [`reference/FEATURES.md`](reference/FEATURES.md)
- Troubleshooting: [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md)

### For Developers
- Architecture: [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md)
- Testing: [`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md)
- Patterns: [`guides/DEVELOPER_PATTERNS.md`](guides/DEVELOPER_PATTERNS.md)
- Paradigms: [`paradigms/PARADIGM_BRIDGE.md`](paradigms/PARADIGM_BRIDGE.md)

### For AI/Agents
- Instructions: [`plans/AGENT_INSTRUCTIONS.md`](plans/AGENT_INSTRUCTIONS.md)
- LLM Guide: [`llm/LLM_DOCUMENTATION_GUIDE.md`](llm/LLM_DOCUMENTATION_GUIDE.md)
- Current PRD: [`plans/staging/README.md`](plans/staging/README.md)
- This Index: You're reading it!

## 🔗 Reference Code Locations

### Reflaxe.Elixir Source
- **Compiler Source**: `/src/reflaxe/elixir/`
- **Test Suite**: `/test/`
- **Examples**: `/examples/`

### External Reference Code
**Location**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/`

Contains:
- **Reflaxe Projects**: Other Reflaxe compiler implementations for patterns
  - `reflaxe.CPP/` - C++ target (mature reference)
  - `reflaxe.CSharp/` - C# target
  - `reflaxe.GDScript/` - GDScript target
  - `reflaxe_go/` - Go target
- **Phoenix Projects**: 
  - `phoenix/` - Phoenix framework reference
  - `phoenix_live_view/` - LiveView implementation
  - `phoenix-liveview-chat-example/` - Working LiveView example
- **Haxe Source**: 
  - `haxe/` - Haxe compiler source code
  - `haxe/std/` - Standard library implementation
- **Macro Examples**:
  - `tink_hxx/` - HXX macro processing reference
  - `coconut.ui/` - UI macro patterns

## 📋 Task-Specific Documentation Guide

### When Adding a Compiler Feature
1. Check [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md)
2. Review [`reference/ANNOTATIONS.md`](reference/ANNOTATIONS.md)
3. Look at similar features in reference implementations
4. Follow [`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md) for testing

### When Writing Tests
1. Start with [`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md)
2. Follow patterns in [`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md)
3. Check [`TEST_SUITE_DEEP_DIVE.md`](TEST_SUITE_DEEP_DIVE.md) for examples

### When Working with Phoenix
1. Read [`phoenix/HAXE_FOR_PHOENIX.md`](phoenix/HAXE_FOR_PHOENIX.md)
2. Check Phoenix examples in reference folder
3. Review [`guides/ROUTER_MIGRATION_GUIDE.md`](guides/ROUTER_MIGRATION_GUIDE.md)

### When Dealing with Paradigm Issues
1. Study [`paradigms/PARADIGM_BRIDGE.md`](paradigms/PARADIGM_BRIDGE.md)
2. Apply patterns from [`guides/DEVELOPER_PATTERNS.md`](guides/DEVELOPER_PATTERNS.md)
3. Check [`FUNCTIONAL_PATTERNS.md`](FUNCTIONAL_PATTERNS.md)

## 🔄 Documentation Maintenance

### Keeping Docs Current
- Update relevant docs immediately after feature implementation
- Keep [`TASK_HISTORY.md`](TASK_HISTORY.md) updated after each session
- Move completed PRDs from `staging/` to `archive/`
- Update this index when adding new documentation

### Documentation Standards
- Use clear, descriptive titles
- Include code examples where possible
- Cross-reference related documentation
- Keep user docs separate from developer docs
- Follow DRY principle - don't duplicate information

## 🚀 Quick Start Paths

### New to Reflaxe.Elixir?
1. [`guides/GETTING_STARTED.md`](guides/GETTING_STARTED.md)
2. [`guides/EXAMPLES.md`](guides/EXAMPLES.md)
3. [`guides/COOKBOOK.md`](guides/COOKBOOK.md)

### Contributing to the Compiler?
1. [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md)
2. [`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md)
3. [`plans/ACTIVE_PRD.md`](plans/ACTIVE_PRD.md) (current work)

### Setting up Development?
1. [`DEVELOPMENT_TOOLS.md`](DEVELOPMENT_TOOLS.md)
2. [`guides/WATCHER_DEVELOPMENT_GUIDE.md`](guides/WATCHER_DEVELOPMENT_GUIDE.md)
3. [`MIX_INTEGRATION.md`](MIX_INTEGRATION.md)

## 🧠 Distributed CLAUDE.md Architecture

**Purpose**: Domain-specific context for AI agents working on different parts of the system

The project uses a hierarchical CLAUDE.md system where each subdirectory can have its own specialized AI context while inheriting from the main project conventions.

### Main Project Context
- **[`/CLAUDE.md`](/CLAUDE.md)** - Project-wide conventions, architecture, and core development principles

### Domain-Specific Contexts
- **[`src/reflaxe/elixir/CLAUDE.md`](/src/reflaxe/elixir/CLAUDE.md)** - Compiler development guidance
  - Macro-time vs runtime architecture patterns
  - AST processing best practices
  - Helper compiler development workflows
  - TypedExpr transformation guidelines

- **[`std/CLAUDE.md`](/std/CLAUDE.md)** - Standard library development patterns
  - Extern + Runtime Library pattern documentation
  - Type-safe API design principles
  - Framework integration standards
  - Cross-platform compatibility guidelines

- **[`test/CLAUDE.md`](/test/CLAUDE.md)** - Testing-specific methodology
  - 4-type testing architecture explanation
  - Snapshot testing vs Mix testing guidelines
  - Todo-app integration testing protocols
  - Macro-time testing limitations

- **[`examples/todo-app/CLAUDE.md`](/examples/todo-app/CLAUDE.md)** - Example-specific guidance
  - Never edit generated files rule
  - File watching workflow
  - Integration testing patterns
  - Phoenix development with Haxe

### Parent-Child Relationship
Each subdirectory CLAUDE.md includes a parent reference:
```markdown
> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions
```

This creates a hierarchical knowledge system that provides:
- **Domain expertise** available where needed
- **Consistent patterns** across all development areas
- **Scalable architecture** that grows with project complexity
- **Context inheritance** from parent to specialized domains

### For AI Agents
When working in any subdirectory, agents should:
1. Check for local CLAUDE.md file first
2. Inherit conventions from parent context
3. Apply domain-specific patterns and constraints
4. Maintain consistency with project-wide standards

---

**Remember**: This index is your map to all project documentation. When in doubt, start here!