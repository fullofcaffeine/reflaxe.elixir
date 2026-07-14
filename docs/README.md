# Reflaxe.Elixir Documentation

**Haxe->Elixir documentation for Phoenix/OTP integration**

This index helps you find the right docs quickly, whether you're building apps with Phoenix or working on the compiler.

> [!WARNING]
> Reflaxe.Elixir is currently on the pre-1.0 (`v0.x`) release line. Documented stable
> surfaces follow the project's pre-1.0 compatibility policy, while experimental/opt-in
> features remain clearly labeled. [Versioning & Stability](06-guides/VERSIONING_AND_STABILITY.md)
> is the canonical current status; [Production Hardening](06-guides/PRODUCTION_READINESS.md)
> is a graduation checklist, not a declaration that graduation has happened.

## 📚 Documentation Sections

### 🚀 Getting Started
**[01-getting-started/](01-getting-started/)** - Setup, quickstart, and basic concepts
- [Why Reflaxe.Elixir?](01-getting-started/WHY_REFLAXE_ELIXIR.md) - Product model, gradual adoption, Elixir-flavored Haxe, and an honest Gleam comparison
- [Start Here (Beginner Quickstart)](01-getting-started/START_HERE.md) - Run the todo-app and learn the mental model (Haxe/Phoenix newcomers)
- [Installation Guide](01-getting-started/installation.md) - Setup Haxe, Reflaxe, and dependencies
- [Development Workflow](01-getting-started/development-workflow.md) - Day-to-day development practices
- [Source Checkout vs Release Package](01-getting-started/SOURCE_VS_PACKAGE_LAYOUT.md) - Why Reflaxe uses two filesystem layouts for one implementation
- [Compiler Flags Guide](01-getting-started/compiler-flags-guide.md) - Recommended flags and anti-patterns
- [Cross-hx Guide](01-getting-started/cross-hx.md) - Target-conditional stdlib overrides
- [Quickstart](06-guides/QUICKSTART.md) - Fast track to productivity

### 📖 User Guide
**[02-user-guide/](02-user-guide/)** - Complete user documentation for application developers
- [Haxe Language Fundamentals](02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md) - Core concepts
- [Imperative→Functional Lowering](02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md) - How mutation/loops become immutable Elixir
- [Writing Idiomatic Haxe](02-user-guide/WRITING_IDIOMATIC_HAXE_FOR_ELIXIR.md) - Guidelines for clean, idiomatic Elixir output
- [Authoring Profiles: Portable vs Elixir-First](02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md) - Choose module-level strategy without changing compiler mode
- [`reflaxe_runtime` and Generated Elixir Helpers](02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md) - Compiler-development define, native-lowering order, and current helper inclusion policy
- [Interop With Existing Elixir Modules](02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md) - Typed extern-first workflow for calling hand-written Elixir from Haxe
- [Haxe→Elixir Mappings](02-user-guide/HAXE_ELIXIR_MAPPINGS.md) - Language conversion guide
- [Elixir Idioms & Hygiene](02-user-guide/ELIXIR_IDIOMS_AND_HYGIENE.md) - Naming, unused vars, enum shapes, loop semantics
- [Generated Output Ownership](02-user-guide/GENERATED_OUTPUT_OWNERSHIP.md) - Collision rejection, hashed ownership, transactional recovery, safe clean, and isolated/in-place modes
- [Canonical Generated Output Formatting](02-user-guide/GENERATED_OUTPUT_FORMATTING.md) - Optional Mix write/check lifecycle, ownership, Phoenix plugins, and CI pinning
- [Porting stdlib code (JS→Elixir)](02-user-guide/PORTING_STDLIB_CODE_JS_TO_ELIXIR.md) - Practical portability example
- [Phoenix Integration](02-user-guide/PHOENIX_INTEGRATION.md) - Building Phoenix applications
- [Type-Safe Phoenix Abstractions](02-user-guide/TYPE_SAFE_PHOENIX_ABSTRACTIONS.md) - Assigns/Socket/Flash typed surfaces
- [Phoenix LiveView Architecture](02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md) - Real-time UI patterns
- [Haxe for Phoenix](02-user-guide/haxe-for-phoenix.md) - Why Haxe makes Phoenix better
- [HXX Syntax & Comparison](02-user-guide/HXX_SYNTAX_AND_COMPARISON.md) - Typed HXX UX and comparison with Coconut UI & TSX
- [Ecto Integration Patterns](07-patterns/ECTO_INTEGRATION_PATTERNS.md) - Database integration patterns (canonical)
- [User Guide](02-user-guide/USER_GUIDE.md) - Comprehensive development guide

### ⚙️ Compiler Development
**[03-compiler-development/](03-compiler-development/)** - For contributors to the compiler itself
- [Compilation Pipeline](03-compiler-development/COMPILATION_PIPELINE_ARCHITECTURE.md) - How TypedExpr becomes Elixir
- [Compilation Flow](05-architecture/COMPILATION_FLOW.md) - Current builder, transformer, result-invariant, printer, and output stages
- [Lean Pass Pipeline](03-compiler-development/LEAN_PASS_PIPELINE.md) - Bundle boundaries, granular debugging, and pass-order guardrails
- [AST Pass Registry Inventory](05-architecture/PASS_REGISTRY_INVENTORY.md) - Effective phases, typed ownership scopes, scoped/all-pass byte parity, replay families, diagnostics, and profiling baseline
- [Macro Principles](03-compiler-development/MACRO_PRINCIPLES.md) - Macro-time compilation rules
- [Testing Infrastructure](03-compiler-development/TESTING_INFRASTRUCTURE.md) - Snapshot + integration testing system
- [Generated Elixir Quality Corpus](03-compiler-development/GENERATED_OUTPUT_QUALITY_CORPUS.md) - Handwritten comparisons, structural allowances, support footprint, and source/package parity
- [XRay Debugging](03-compiler-development/DEBUG_XRAY_SYSTEM.md) - Debugging methodology
- [Best Practices](03-compiler-development/COMPILER_BEST_PRACTICES.md) - Development patterns

### 📋 API Reference
**[04-api-reference/](04-api-reference/)** - Technical reference documentation
- [API Index](04-api-reference/API_INDEX.md) - User-facing API/tag index and coverage map
- [Annotations](04-api-reference/ANNOTATIONS.md) - @:router, @:liveview, @:schema reference
- [Phoenix API Reference](04-api-reference/PHOENIX_API_REFERENCE.md) - LiveView/Component/Channel/Presence user APIs
- [LiveSocket Assign API](04-api-reference/LIVE_SOCKET_ASSIGN_API.md) - `assign(_.field, value)` vs `assign({...})` vs typed keys
- [Ecto API Reference](04-api-reference/ECTO_API_REFERENCE.md) - Schema/Changeset/Repo/Query/Migration user APIs
- [Elixir Runtime API Reference](04-api-reference/ELIXIR_RUNTIME_API_REFERENCE.md) - Core runtime and OTP extern surfaces
- [OTP Support Contract](04-api-reference/OTP_SUPPORT_CONTRACT.md) - Exact runtime-tested local Process/Task/Agent subset, application-wiring evidence, and 1.0 exclusions
- [Type-Safe ChildSpec API](04-api-reference/TYPE_SAFE_CHILD_SPEC.md) - Typed OTP child-spec surfaces and explicit `*Unsafe` escape hatches
- [Atom Type](04-api-reference/ATOM_TYPE.md) - Type-safe atoms for Elixir APIs
- [Standard Library](04-api-reference/STANDARD_LIBRARY_HANDLING.md) - Stdlib strategy + guidance
- [Stdlib Support Matrix](04-api-reference/STDLIB_SUPPORT_MATRIX.md) - Target overrides, verified official fallback, and known gaps
- [Feature Flags](04-api-reference/FEATURE_FLAGS.md) - User-facing codegen toggles (gradual rollout / debugging)
- [Haxe Macro APIs](04-api-reference/HAXE_MACRO_APIS.md) - Correct macro API usage
- [Source Mapping](04-api-reference/SOURCE_MAPPING.md) - Experimental source map design/status
- [Router DSL](04-api-reference/ROUTER_DSL.md) - Phoenix router DSL reference
- [Mix Tasks](04-api-reference/MIX_TASKS.md) - Custom Mix task reference
- [Mix Task Generators](04-api-reference/MIX_TASK_GENERATORS.md) - `mix haxe.gen.*` scaffolds (Haxe-first)

### 🏗️ Architecture
**[05-architecture/](05-architecture/)** - System design and implementation details
- [Architecture](05-architecture/ARCHITECTURE.md) - Overall system design
- [Cross Overrides & Multi-Target Hardening](05-architecture/CROSS_OVERRIDES_AND_MULTI_TARGET_HARDENING.md) - `_std` / packaged `.cross.hx` ownership and sibling-target coexistence risks
- [Phoenix Output Model](05-architecture/PHOENIX_OUTPUT_MODEL.md) - In-place vs materialized Phoenix output, source roots vs target namespaces
- [HXML Architecture](05-architecture/HXML_ARCHITECTURE.md) - Build file patterns and anti-patterns
- [File Naming](05-architecture/FILE_NAMING_ARCHITECTURE.md) - snake_case conversion rules
- [HXX Templates](05-architecture/HXX_ARCHITECTURE.md) - Template compilation system
- [Elixir Injection](04-api-reference/ELIXIR_INJECTION_GUIDE.md) - `__elixir__()` / Syntax.code() patterns

### 📋 How-To Guides
**[06-guides/](06-guides/)** - Practical guides for specific tasks
- [Quickstart](06-guides/QUICKSTART.md) - Fast track to productivity
- [Phoenix (New App)](06-guides/PHOENIX_NEW_APP.md) - Greenfield Phoenix setup
- [Phoenix (Existing App)](06-guides/PHOENIX_GRADUAL_ADOPTION.md) - Gradual adoption in an existing app
- [Phoenix Gradual Adoption Tutorial](06-guides/PHOENIX_GRADUAL_ADOPTION_TUTORIAL.md) - Concrete domain module, LiveView, and test path
- [Scaffolding System](06-guides/SCAFFOLDING_SYSTEM.md) - How generators + marker blocks work
- [Adding Elixir Libraries From Haxe](06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md) - Thin extern + wrapper pattern
- [Phoenix Chat Tutorial (Hybrid)](06-guides/PHOENIX_CHAT_TUTORIAL.md) - Gradual adoption: feature logic in Haxe, core app/router wiring in Elixir
- [Phoenix Chat Tutorial (Haxe-First)](06-guides/PHOENIX_CHAT_TUTORIAL_HAXE_FIRST.md) - App/router/live/presence authored in Haxe
- [Portable Chat Tutorial](06-guides/PORTABLE_CHAT_TUTORIAL.md) - Shared Haxe domain logic pattern
- [Dogfooding](06-guides/DOGFOODING.md) - External Phoenix app upgrade validation
- [Todo-app Cowboy Toolchain](06-guides/TODOAPP_COWBOY_TOOLCHAIN.md) - Why the todo-app pins Cowboy deps
- [Production Readiness](06-guides/PRODUCTION_READINESS.md) - Current evidence scorecard, known blockers, and stable-graduation gate
- [Strict Mode](06-guides/STRICT_MODE.md) - Opt-in Gleam-like safety profile
- [Versioning & Stability](06-guides/VERSIONING_AND_STABILITY.md) - SemVer + stability tiers + deprecation policy
- [Production Deployment](06-guides/PRODUCTION_DEPLOYMENT.md) - CI/Docker/release patterns
- [VS Code Debugging (Source Maps)](06-guides/VSCODE_DEBUGGING.md) - Jump from `.ex` runtime locations back to Haxe
- [Performance Guide](06-guides/PERFORMANCE_GUIDE.md) - Compilation performance
- [Troubleshooting](06-guides/TROUBLESHOOTING.md) - Common issues and solutions
- [Known Limitations](06-guides/KNOWN_LIMITATIONS.md) - Sharp edges and experimental surfaces
- [Support Matrix](06-guides/SUPPORT_MATRIX.md) - CI-tested toolchain versions
- [Licensing & Distribution](06-guides/LICENSING_AND_DISTRIBUTION.md) - GPL notes (not legal advice)

Legacy guides (kept for link stability):
- [Getting Started (Legacy)](06-guides/GETTING_STARTED.md)
- [Phoenix Integration Guide (Legacy)](06-guides/PHOENIX_INTEGRATION_GUIDE.md)
- [Project Generator Guide (Legacy)](06-guides/PROJECT_GENERATOR_GUIDE.md)

### 🎯 Patterns & Examples
**[07-patterns/](07-patterns/)** - Code patterns and best practices
- [Quick Start Patterns](07-patterns/quick-start-patterns.md) - Copy-paste patterns
- [Functional Patterns](07-patterns/FUNCTIONAL_PATTERNS.md) - Result/Option and idioms
- [LiveView Patterns](07-patterns/PHOENIX_LIVEVIEW_PATTERNS.md) - Phoenix LiveView patterns
- [Ecto Patterns](07-patterns/ECTO_INTEGRATION_PATTERNS.md) - Ecto/Phoenix integration patterns
- [JavaScript Patterns](07-patterns/JAVASCRIPT_PATTERNS.md) - JS generation patterns

### 🗺️ Roadmap & Planning
**[08-roadmap/](08-roadmap/)** - Planning notes and long-term ideas
- [Vision](08-roadmap/vision.md) - Grounded product principles and long-term directions (not a stability contract)
- [1.0 Production Readiness Review](08-roadmap/1.0-production-readiness-review.md) - Independent adversarial baseline, evidence gaps, product position, and execution graph
- [Generated Elixir Idiomaticity Audit](08-roadmap/generated-elixir-idiomaticity-audit.md) - Evidence, tradeoffs, and the prioritized path toward handwritten-quality output
- [Phoenix Surface Parity](08-roadmap/phoenix-surface-parity.md) - Example-driven Phoenix/PubSub/Presence/LiveView API gap checklist
- [PhoenixHx Live Event Protocols](08-roadmap/phoenixhx-live-event-protocols.md) - Typed hook/server event protocols around Phoenix `pushEvent` and `handle_event/3`
- [RailsHx-to-PhoenixHx Migration Compiler RFC](08-roadmap/railshx-to-phoenixhx-migration-compiler.md) - Future R&D plan for evidence-driven RailsHx migration and coexistence

### 📜 History
**[09-history/](09-history/)** - Historical context for repository shape and decisions
- [Reflaxe Layout and Packaging History](09-history/REFLAXE_LAYOUT_AND_PACKAGING_HISTORY.md) - Why source checkouts use `_std` while releases contain generated `.cross.hx` files
- [Release Protocol History](09-history/RELEASE_PROTOCOL_HISTORY.md) - Predecessor release-commit evidence and the current tested-commit protocol

Prefer [`CHANGELOG.md`](../CHANGELOG.md) and [`ROADMAP.md`](../ROADMAP.md) for release/user-facing history.

### 🤝 Contributing
**[10-contributing/](10-contributing/)** - Contribution guidelines and processes
- [Contributing Guide](10-contributing/contributing.md) - How to contribute
- [Releasing](10-contributing/RELEASING.md) - semantic-release + GitHub Releases
- [Updating AGENTS.md](10-contributing/updating-agents-md.md) - AI context and unified documentation strategy
- [LLM Documentation Guide](10-contributing/llm-integration/LLM_DOCUMENTATION_GUIDE.md) - How to write LLM-friendly documentation
- [Documentation Philosophy](10-contributing/DOCUMENTATION_PHILOSOPHY.md) - How docs are organized and maintained
- [LLM Integration Index](10-contributing/llm-integration/INDEX.md) - Entry point for AI-facing docs

## 🤖 AI Assistant Integration

This documentation is optimized for AI assistant development with **AGENTS.md** files providing specialized context:

- **[AGENTS.md](AGENTS.md)** - Main AI instructions for documentation navigation
- **[03-compiler-development/AGENTS.md](03-compiler-development/AGENTS.md)** - Compiler-specific AI context

## 🔗 Quick Links

- **[Start Here](01-getting-started/START_HERE.md)** - Beginner quickstart (Haxe/Phoenix newcomers)
- **[Why Reflaxe.Elixir?](01-getting-started/WHY_REFLAXE_ELIXIR.md)** - Decide whether the adoption model and tradeoffs fit your project
- **[Installation](01-getting-started/installation.md)** - Get started in 5 minutes
- **[Quickstart](06-guides/QUICKSTART.md)** - Your first Haxe→Elixir project
- **[Phoenix (New App)](06-guides/PHOENIX_NEW_APP.md)** - Greenfield Phoenix setup
- **[Phoenix (Existing App)](06-guides/PHOENIX_GRADUAL_ADOPTION.md)** - Add Haxe to an existing Phoenix app
- **[Interop With Existing Elixir](02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md)** - Call pure Elixir modules from Haxe with typed boundaries
- **[Type-Safe ChildSpec API](04-api-reference/TYPE_SAFE_CHILD_SPEC.md)** - Canonical typed child-spec reference
- **[Phoenix Guide](02-user-guide/PHOENIX_INTEGRATION.md)** - Building Phoenix applications
- **[Troubleshooting](06-guides/TROUBLESHOOTING.md)** - Solve common issues
- **[Known Limitations](06-guides/KNOWN_LIMITATIONS.md)** - Sharp edges and experimental surfaces
- **[Support Matrix](06-guides/SUPPORT_MATRIX.md)** - CI-tested versions
- **[Versioning & Stability](06-guides/VERSIONING_AND_STABILITY.md)** - Canonical release line and compatibility policy
- **[Contributing](10-contributing/contributing.md)** - Help improve the project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/fullofcaffeine/reflaxe.elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/fullofcaffeine/reflaxe.elixir/discussions)
- **Documentation**: You're looking at it!

---

**Next Steps**: Start with [01-getting-started/installation.md](01-getting-started/installation.md) to begin your Haxe→Elixir journey.
