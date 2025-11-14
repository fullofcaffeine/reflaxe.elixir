# Reflaxe.Elixir Documentation

**Type-safe Haxe→Elixir compilation with Phoenix framework integration**

Welcome to the comprehensive documentation for Reflaxe.Elixir, a Haxe compilation target that generates idiomatic Elixir code with complete Phoenix/OTP integration.

## 📚 Documentation Sections

### 🚀 Getting Started
**[01-getting-started/](01-getting-started/)** - Setup, quickstart, and basic concepts
- [Installation Guide](01-getting-started/installation.md) - Setup Haxe, Reflaxe, and dependencies
- [Quickstart Tutorial](01-getting-started/quickstart.md) - Hello World in 5 minutes
- [Project Structure](01-getting-started/project-structure.md) - Understanding the directory layout
- [Development Workflow](01-getting-started/development-workflow.md) - Day-to-day development practices

### 📖 User Guide
**[02-user-guide/](02-user-guide/)** - Complete user documentation for application developers
- [Haxe Language Fundamentals](02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md) - Core concepts
- [Haxe→Elixir Mappings](02-user-guide/HAXE_ELIXIR_MAPPINGS.md) - Language conversion guide
- [Phoenix Integration](02-user-guide/PHOENIX_INTEGRATION.md) - Building Phoenix applications
- [Phoenix LiveView Architecture](02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md) - Real-time UI patterns
- [Haxe for Phoenix](02-user-guide/haxe-for-phoenix.md) - Why Haxe makes Phoenix better
- [HXX Syntax & Comparison](02-user-guide/HXX_SYNTAX_AND_COMPARISON.md) - Typed HXX UX and comparison with Coconut UI & TSX
- [Todo App Specifics](02-user-guide/todo-app-specifics.md) - LiveView implementation patterns and project-specific guidance
- [Ecto Integration Patterns](02-user-guide/ECTO_INTEGRATION_PATTERNS.md) - Database integration
- [Bootstrap Code Generation](02-user-guide/bootstrap-code-generation.md) - Auto-execution for scripts
- [User Guide](02-user-guide/USER_GUIDE.md) - Comprehensive development guide

### ⚙️ Compiler Development
**[03-compiler-development/](03-compiler-development/)** - For contributors to the compiler itself
- [Architecture Overview](03-compiler-development/architecture.md) - How the compiler works
- [Macro-time vs Runtime](03-compiler-development/macro-time-vs-runtime.md) - Critical distinction
- [AST Processing](03-compiler-development/ast-processing.md) - TypedExpr transformation
- [Testing Infrastructure](03-compiler-development/testing-infrastructure.md) - Snapshot testing system
- [Debugging Guide](03-compiler-development/debugging-guide.md) - XRay debugging methodology
- [Best Practices](03-compiler-development/best-practices.md) - Development patterns

### 📋 API Reference
**[04-api-reference/](04-api-reference/)** - Technical reference documentation
- [Annotations](04-api-reference/annotations.md) - @:router, @:liveview, @:schema reference
- [Standard Library](04-api-reference/standard-library.md) - Haxe stdlib support matrix
- [Haxe Stdlib API Reference](04-api-reference/haxe-stdlib-api-reference.md) - Complete Haxe standard library API reference
- [Phoenix Externs](04-api-reference/phoenix-externs.md) - Phoenix framework type definitions
- [Compiler APIs](04-api-reference/compiler-apis.md) - Reflaxe framework APIs
- [Mix Tasks](04-api-reference/mix-tasks.md) - Custom Mix task reference

### 🏗️ Architecture
**[05-architecture/](05-architecture/)** - System design and implementation details
- [Compilation Pipeline](05-architecture/compilation-pipeline.md) - From Haxe AST to Elixir code
- [File Naming System](05-architecture/file-naming-system.md) - snake_case conversion rules
- [Module Resolution](05-architecture/module-resolution.md) - Phoenix naming conventions
- [HXX Templates](05-architecture/hxx-templates.md) - Template compilation system
- [Elixir Injection](05-architecture/elixir-injection.md) - Syntax.code() implementation

### 📋 How-To Guides
**[06-guides/](06-guides/)** - Practical guides for specific tasks
- [Migrating from Elixir](06-guides/migrating-from-elixir.md) - Elixir→Haxe migration guide
- [Creating Phoenix Apps](06-guides/creating-phoenix-app.md) - Phoenix from scratch
- [Writing Externs](06-guides/writing-externs.md) - External library integration
- [Performance Optimization](06-guides/optimizing-performance.md) - Compilation performance
- [Troubleshooting](06-guides/troubleshooting.md) - Common issues and solutions

### 🎯 Patterns & Examples
**[07-patterns/](07-patterns/)** - Code patterns and best practices
- [Functional Transformations](07-patterns/functional-transformations.md) - Imperative→functional patterns
- [OTP Patterns](07-patterns/otp-patterns.md) - GenServer, Supervisor integration
- [PubSub Patterns](07-patterns/pubsub-patterns.md) - Type-safe messaging
- [Error Handling](07-patterns/error-handling.md) - Result<T,E> usage patterns
- [Async Patterns](07-patterns/async-patterns.md) - Async/await in Haxe

### 🗺️ Roadmap & Planning
**[08-roadmap/](08-roadmap/)** - Project direction and future plans
- [Vision](08-roadmap/vision.md) - Long-term project vision
- [V1 Roadmap](08-roadmap/v1-roadmap.md) - Version 1.0 release goals
- [Compiler + Todo-App 1.0 PRD](prds/HAXE_ELIXIR_1_0_COMPILER_TODOAPP_PRD.md) - Combined compiler and todo-app quality bar for 1.0
- [Active PRD](08-roadmap/ACTIVE_PRD.md) - Current product requirements
- [Product Requirements Document](08-roadmap/product-requirements-document.md) - Comprehensive PRD

### 📜 History & Records
**[09-history/](09-history/)** - Historical documentation and decisions
- [Task History](09-history/task-history.md) - Complete implementation log (3200+ entries)
- [Legacy Development Guide](09-history/legacy-development-guide.md) - Previous development workflow
- [Legacy Installation Guide](09-history/legacy-installation-guide.md) - Previous setup instructions
- [Legacy Documentation Index](09-history/legacy-documentation-index.md) - Previous documentation structure
- [Archive](09-history/archive/) - Historical development plans and PRDs
- [Session Records](09-history/sessions/) - Development session archives

### 🤝 Contributing
**[10-contributing/](10-contributing/)** - Contribution guidelines and processes
- [Contributing Guide](10-contributing/contributing.md) - How to contribute
- [Code Style](10-contributing/code-style.md) - Coding standards
- [Updating AGENTS.md](10-contributing/updating-agents-md.md) - AI context and unified documentation strategy
- [LLM Documentation Guide](10-contributing/llm-integration/LLM_DOCUMENTATION_GUIDE.md) - How to write LLM-friendly documentation
- [LLM Documentation Index](10-contributing/llm-integration/LLM_DOCUMENTATION_INDEX.md) - Complete 232-file navigation index
- [Commit Conventions](10-contributing/commit-conventions.md) - Git conventions
- [Release Process](10-contributing/release-process.md) - Versioning and releases

## 🤖 AI Assistant Integration

This documentation is optimized for AI assistant development with **AGENTS.md** files providing specialized context:

- **[AGENTS.md](AGENTS.md)** - Main AI instructions for documentation navigation
- **[03-compiler-development/AGENTS.md](03-compiler-development/AGENTS.md)** - Compiler-specific AI context

## 🔗 Quick Links

- **[Installation](01-getting-started/installation.md)** - Get started in 5 minutes
- **[Quickstart](01-getting-started/quickstart.md)** - Your first Haxe→Elixir project
- **[Phoenix Guide](02-user-guide/phoenix-integration.md)** - Building Phoenix applications
- **[Troubleshooting](06-guides/troubleshooting.md)** - Solve common issues
- **[Contributing](10-contributing/contributing.md)** - Help improve the project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/fullofcaffeine/reflaxe.elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/fullofcaffeine/reflaxe.elixir/discussions)
- **Documentation**: You're looking at it!

---

**Next Steps**: Start with [01-getting-started/installation.md](01-getting-started/installation.md) to begin your Haxe→Elixir journey.
