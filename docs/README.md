# Reflaxe.Elixir Documentation

**Type-safe Haxe→Elixir compilation with Phoenix framework integration**

Welcome to the comprehensive documentation for Reflaxe.Elixir, a Haxe compilation target that generates idiomatic Elixir code with complete Phoenix/OTP integration.

## 📚 Documentation Sections

### 🚀 Getting Started
**[01-getting-started/](01-getting-started/)** - Setup, quickstart, and basic concepts
- [Installation Guide](01-getting-started/installation.md) - Setup Haxe, Reflaxe, and dependencies
- [Development Workflow](01-getting-started/development-workflow.md) - Day-to-day development practices
- [Compiler Flags Guide](01-getting-started/compiler-flags-guide.md) - Recommended flags and anti-patterns
- [Cross-hx Guide](01-getting-started/cross-hx.md) - Target-conditional stdlib overrides
- [Quickstart](06-guides/QUICKSTART.md) - Fast track to productivity

### 📖 User Guide
**[02-user-guide/](02-user-guide/)** - Complete user documentation for application developers
- [Haxe Language Fundamentals](02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md) - Core concepts
- [Haxe→Elixir Mappings](02-user-guide/HAXE_ELIXIR_MAPPINGS.md) - Language conversion guide
- [Phoenix Integration](02-user-guide/PHOENIX_INTEGRATION.md) - Building Phoenix applications
- [Phoenix LiveView Architecture](02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md) - Real-time UI patterns
- [Haxe for Phoenix](02-user-guide/haxe-for-phoenix.md) - Why Haxe makes Phoenix better
- [HXX Syntax & Comparison](02-user-guide/HXX_SYNTAX_AND_COMPARISON.md) - Typed HXX UX and comparison with Coconut UI & TSX
- [Ecto Integration Patterns](02-user-guide/ECTO_INTEGRATION_PATTERNS.md) - Database integration
- [User Guide](02-user-guide/USER_GUIDE.md) - Comprehensive development guide

### ⚙️ Compiler Development
**[03-compiler-development/](03-compiler-development/)** - For contributors to the compiler itself
- [Compilation Pipeline](03-compiler-development/COMPILATION_PIPELINE_ARCHITECTURE.md) - How TypedExpr becomes Elixir
- [Macro Principles](03-compiler-development/MACRO_PRINCIPLES.md) - Macro-time compilation rules
- [Testing Infrastructure](03-compiler-development/TESTING_INFRASTRUCTURE.md) - Snapshot + integration testing system
- [XRay Debugging](03-compiler-development/DEBUG_XRAY_SYSTEM.md) - Debugging methodology
- [Best Practices](03-compiler-development/COMPILER_BEST_PRACTICES.md) - Development patterns
  
Most internal research notes were archived to **[09-history/archive/docs/03-compiler-development/](09-history/archive/docs/03-compiler-development/)** during post‑1.0 cleanup. The links above are the curated, up‑to‑date entry points.

### 📋 API Reference
**[04-api-reference/](04-api-reference/)** - Technical reference documentation
- [Annotations](04-api-reference/ANNOTATIONS.md) - @:router, @:liveview, @:schema reference
- [Standard Library](04-api-reference/STANDARD_LIBRARY_HANDLING.md) - Stdlib strategy + guidance
- [Haxe Macro APIs](04-api-reference/HAXE_MACRO_APIS.md) - Correct macro API usage
- [Source Mapping](04-api-reference/SOURCE_MAPPING.md) - Source map architecture + usage
- [Router DSL](04-api-reference/ROUTER_DSL.md) - Phoenix router DSL reference
- [Mix Tasks](04-api-reference/MIX_TASKS.md) - Custom Mix task reference

### 🏗️ Architecture
**[05-architecture/](05-architecture/)** - System design and implementation details
- [Architecture](05-architecture/ARCHITECTURE.md) - Overall system design
- [HXML Architecture](05-architecture/HXML_ARCHITECTURE.md) - Build file patterns and anti-patterns
- [File Naming](05-architecture/FILE_NAMING_ARCHITECTURE.md) - snake_case conversion rules
- [HXX Templates](05-architecture/HXX_ARCHITECTURE.md) - Template compilation system
- [Elixir Injection](04-api-reference/ELIXIR_INJECTION_GUIDE.md) - `__elixir__()` / Syntax.code() patterns
  
Additional (uncurated) architecture notes were archived to **[09-history/archive/docs/05-architecture/](09-history/archive/docs/05-architecture/)**.

### 📋 How-To Guides
**[06-guides/](06-guides/)** - Practical guides for specific tasks
- [Quickstart](06-guides/QUICKSTART.md) - Fast track to productivity
- [Getting Started](06-guides/GETTING_STARTED.md) - Practical onboarding
- [Phoenix Integration Guide](06-guides/PHOENIX_INTEGRATION_GUIDE.md) - Phoenix app setup + patterns
- [Project Generator Guide](06-guides/PROJECT_GENERATOR_GUIDE.md) - CLI project generation
- [Performance Guide](06-guides/PERFORMANCE_GUIDE.md) - Compilation performance
- [Troubleshooting](06-guides/TROUBLESHOOTING.md) - Common issues and solutions

### 🎯 Patterns & Examples
**[07-patterns/](07-patterns/)** - Code patterns and best practices
- [Quick Start Patterns](07-patterns/quick-start-patterns.md) - Copy-paste patterns
- [Functional Patterns](07-patterns/FUNCTIONAL_PATTERNS.md) - Result/Option and idioms
- [LiveView Patterns](07-patterns/PHOENIX_LIVEVIEW_PATTERNS.md) - Phoenix LiveView patterns
- [Ecto Patterns](07-patterns/ECTO_INTEGRATION_PATTERNS.md) - Ecto/Phoenix integration patterns
- [JavaScript Patterns](07-patterns/JAVASCRIPT_PATTERNS.md) - JS generation patterns

### 🗺️ Roadmap & Planning
**[08-roadmap/](08-roadmap/)** - Project direction and future plans
- [Vision](08-roadmap/vision.md) - Long-term project vision
  
Most 1.0 planning docs and historical PRDs were archived under **[09-history/archive/docs/08-roadmap/](09-history/archive/docs/08-roadmap/)** during post‑1.0 cleanup.

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
- [Updating AGENTS.md](10-contributing/updating-agents-md.md) - AI context and unified documentation strategy
- [LLM Documentation Guide](10-contributing/llm-integration/LLM_DOCUMENTATION_GUIDE.md) - How to write LLM-friendly documentation
- [Documentation Philosophy](10-contributing/DOCUMENTATION_PHILOSOPHY.md) - How docs are organized and maintained
- [LLM Integration Index](10-contributing/llm-integration/INDEX.md) - Entry point for AI-facing docs

## 🤖 AI Assistant Integration

This documentation is optimized for AI assistant development with **AGENTS.md** files providing specialized context:

- **[AGENTS.md](AGENTS.md)** - Main AI instructions for documentation navigation
- **[03-compiler-development/AGENTS.md](03-compiler-development/AGENTS.md)** - Compiler-specific AI context

## 🔗 Quick Links

- **[Installation](01-getting-started/installation.md)** - Get started in 5 minutes
- **[Quickstart](06-guides/QUICKSTART.md)** - Your first Haxe→Elixir project
- **[Phoenix Guide](02-user-guide/PHOENIX_INTEGRATION.md)** - Building Phoenix applications
- **[Troubleshooting](06-guides/TROUBLESHOOTING.md)** - Solve common issues
- **[Contributing](10-contributing/contributing.md)** - Help improve the project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/fullofcaffeine/reflaxe.elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/fullofcaffeine/reflaxe.elixir/discussions)
- **Documentation**: You're looking at it!

---

**Next Steps**: Start with [01-getting-started/installation.md](01-getting-started/installation.md) to begin your Haxe→Elixir journey.
