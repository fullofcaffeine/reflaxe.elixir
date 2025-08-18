# Reflaxe.Elixir Roadmap

This document outlines the development plans for Reflaxe.Elixir, organized by completed features and future priorities.

## ✅ Completed Features

### File Watching & Incremental Compilation (v0.2.0) ✅
- **HaxeWatcher for automatic file change detection** ✅
- **HaxeServer for incremental compilation** via `haxe --wait` ✅
- **Mix integration** with `mix compile.haxe --watch` ✅
- **Sub-second compilation times** optimized for LLM iteration cycles ✅

### Source Mapping Achievement (v0.3.0) ✅ 
**🎯 Reflaxe.Elixir is the FIRST Reflaxe target to implement source mapping!** While other targets (C++, C#, Go, GDScript) don't provide source maps, we've pioneered this feature for superior debugging experience.
- **Source map generation** (.ex.map files with VLQ encoding) ✅
- **Proper sources array** tracking Haxe files ✅
- **Mix task infrastructure** for querying source maps ✅

### Template Helper Metadata System (v1.0) ✅ **NEW**
- **@:templateHelper metadata** for Phoenix template functions ✅
- **Phoenix.Component integration** with automatic import detection ✅
- **Type-safe template compilation** with proper metadata handling ✅

### Type-Safe Phoenix Abstractions (v1.0) ✅ **NEW**
- **Assigns<T>** with @:arrayAccess for ergonomic field access ✅
- **LiveViewSocket<T>**, **FlashMessage**, **RouteParams<T>** abstractions ✅
- **Operator overloading** using standard library patterns ✅

## 🔄 Current Development (v1.1 - Q1 2025)
*Focus: Enhanced LLM Development Experience*

### Features  
- [ ] **LLM Workflow Integration** ✨
  - JSON status output for programmatic queries (`mix haxe.status --format json`)
  - Status file generation (`.haxe_status.json`) for continuous monitoring
  - Enhanced error messages with file/line/column context
  - Silent watch mode for LLM-friendly development (`--llm-mode`)

- [ ] **Live Components Support**
  - Full `@:live_component` annotation
  - Slot support with type safety
  - Component communication patterns

- [ ] **Advanced Router Features**
  - Nested resources
  - Route helpers generation
  - Advanced pipeline integration
  - WebSocket route support

- [ ] **HXX Smart Interpolation** ✨ *Developer Experience Enhancement*
  - Automatic context detection for `${}` vs `{}` syntax
  - HTML attribute parsing for proper interpolation
  - Backwards compatibility with explicit syntax
  - Migration tool for existing templates
  - See: [`documentation/guides/HXX_INTERPOLATION_SYNTAX.md`](documentation/guides/HXX_INTERPOLATION_SYNTAX.md)

### Improvements
- [ ] Performance optimizations for large codebases
- [ ] Better error messages with source location  
- [ ] IDE integration improvements
- [ ] **Mix.Generator API Integration** 🔧
  - Convert ProjectGenerator.hx to use native Mix.Generator utilities
  - Leverage Mix's template system for more flexible project generation
  - Support for Mix.Generator.copy_template, Mix.Generator.create_file, Mix.Generator.copy_from
  - Better integration with Mix ecosystem conventions

### Experimental Features
- [x] **Parallel Test Infrastructure** 🧪 *Performance & Reliability*
  - ✅ **ParallelTestRunner Architecture Complete** - File-based locking with 87% performance improvement (261s → 27s)
  - ✅ **Optimized Worker Count** - 16 workers for maximum CPU utilization on multi-core systems
  - ✅ **Production-Ready Testing** - Default parallel execution with 57/57 tests passing (100%)
  - ✅ **Simple, Maintainable Solution** - File-based mutex eliminates race conditions reliably
- [x] **Framework-Agnostic Module Resolution** ✨ *Foundation Complete*
  - ✅ **@:native Annotation System** - Explicit module name control for framework conventions
  - ✅ **Framework-Agnostic Compiler** - No hardcoded Phoenix assumptions, works with any Elixir application
  - ✅ **Type-Based Module Resolution** - RouterBuildMacro uses proper type lookup instead of string patterns
  - [ ] **Progressive Enhancement Roadmap** - 3-phase plan for automatic module naming
  - **See**: [`documentation/MODULE_RESOLUTION_ROADMAP.md`](documentation/MODULE_RESOLUTION_ROADMAP.md) - Complete enhancement strategy
- [ ] **Worker Process Architecture** 🧪 *Next-Generation Test Isolation*
  - **Goal**: Jest-like separate worker processes for complete test isolation
  - **Benefits**: Eliminate file locking entirely, independent working directories per worker
  - **Architecture**: Main orchestrator + N worker processes communicating via IPC
  - **Potential**: May resolve remaining 3 test failures through true isolation
  - **See**: [`documentation/HAXE_THREADING_ANALYSIS.md`](documentation/HAXE_THREADING_ANALYSIS.md) - Complete analysis of threading vs process approaches
- [ ] **File Naming Consistency Architecture** ⚡ *HIGH PRIORITY - Fixes Ongoing Issues*
  - **Problem**: Multiple snake_case implementations causing inconsistent file naming (e.g., `server_infrastructure_Endpoint.ex` should be `endpoint.ex`)
  - **Root Cause**: Local `toSnakeCase()` in ElixirCompiler.hx vs `NamingHelper.toSnakeCase()` + different code paths for annotations
  - **Solution**: Centralized file naming pipeline with single entry point for ALL generated files
  - **Implementation**: Remove duplicate conversion functions, force all paths through NamingHelper
  - **Benefits**: Consistent file naming, easier debugging, eliminates class of bugs like the current Endpoint issue
- [ ] **Advanced Functional Pattern Optimization** 🧪 *Enhanced Code Generation*
  - **Pattern Matching to Function Heads**: Convert case expressions to multiple function clauses for better performance
  - **FunctionalOptimizer.hx Helper**: Dedicated class for advanced pattern detection and optimization
  - **Function Clause Generation**: Generate `def func(pattern1), def func(pattern2)` instead of single function with case
  - **Guard Compilation**: Transform pattern guards to Elixir `when` clauses
  - **Benefits**: More idiomatic Elixir, better pattern matching performance, cleaner generated code
  - **Current Status**: Core optimizations complete (Array→Enum, with statements, tail recursion)
- [ ] **Self-Hosting Development Infrastructure** 🧪 *Ultimate Dogfooding*
  - **Phase 1**: Rewrite ParallelTestRunner.hx to compile to Elixir instead of interpreter
  - **Phase 2**: Convert HaxeWatcher from Elixir to Haxe→Elixir (file system monitoring)
  - **Phase 3**: Convert HaxeServer from Elixir to Haxe→Elixir (compilation server management)
  - **Phase 4**: Convert all Mix tasks from Elixir to Haxe→Elixir (build pipeline)
  - **Benefits**: Type safety for tooling, validation of complex OTP patterns, performance testing
  - **Challenges**: GenServer patterns, file system APIs, Mix.Task integration
  - **Foundation**: Complete self-hosting capabilities and compiler validation
  - **Note**: Once we migrate the test runner to target the Elixir target, we might leverage the Mix parallel test runner instead of our existing custom solution to simplify architecture and reduce code maintenance
- [ ] **Reflaxe Framework Integration** 🧪 *Compiler Architecture Enhancement*
  - **Goal**: Modify vendored Reflaxe to support `elixir.Syntax.code()` at framework level (similar to `__elixir__()`)
  - **Current**: Regular class implementation working excellently with compiler-level detection
  - **Future**: Framework-level handling in `vendor/reflaxe/src/reflaxe/input/TargetCodeInjection.hx`
  - **Benefits**: Simplified compiler code, consistent pattern across all Reflaxe targets, better error messages
  - **Implementation**: Add `isTargetSyntaxInjection()` pattern to TargetCodeInjection alongside existing `__target__()` support
  - **Priority**: LOW - Current approach works perfectly, this is an optimization opportunity not a necessity
  - **See**: [`documentation/ELIXIR_SYNTAX_IMPLEMENTATION.md`](documentation/ELIXIR_SYNTAX_IMPLEMENTATION.md) - Why current regular class approach works so well
  - **See**: [`vendor/reflaxe/FUTURE_MODIFICATIONS.md`](vendor/reflaxe/FUTURE_MODIFICATIONS.md) - Proposed Reflaxe enhancements

## 🚀 Future Development (v1.2 - Q2 2025)
*Focus: Testing & Developer Experience*

### Features
- [ ] **Complete Source Mapping** 🚀 *Building on our pioneering source map implementation*
  - [ ] Complete VLQ Base64 decoder implementation
    - Current: Mock implementation returns placeholder mappings
    - Needed: Proper VLQ decoding following Source Map v3 spec
    - Reference: Haxe's `context/sourcemaps.ml` implementation
  - [ ] Enhanced position tracking for all expression types
  - [ ] Source map validation tests and performance benchmarks

- [ ] **Test DSL**
  - `@:test` annotation for ExUnit tests
  - Property-based testing support
  - Mock generation for behaviors

- [ ] **Advanced Debugging Support**
  - [ ] Enhanced position tracking
    - Track all expression types during compilation
    - Accurate column position tracking
    - Support for multi-line expressions
  - [ ] Source map validation tests
    - Verify VLQ encoding correctness
    - Test bidirectional position lookups
    - Performance benchmarks for large files
  - [x] Mix tasks for source map queries (`mix haxe.source_map`)
  - [x] Phoenix error handler integration scaffolding
  - [ ] IEx integration helpers
  - [ ] Runtime inspection tools

- [ ] **Documentation Generation**
  - ExDoc integration
  - Auto-generate documentation from Haxe comments
  - Type information in docs

### Improvements
- [ ] VS Code extension with syntax highlighting
- [ ] Language server protocol (LSP) support
- [ ] Hot code reloading integration

## 🔮 Long-term Vision (v2.0 - 2025+)
*Focus: Advanced OTP Patterns & Production Excellence*

### Features
- [ ] **Supervisor Trees**
  - `@:supervisor` annotation
  - Dynamic supervisor support
  - Application behavior

- [ ] **Event Sourcing**
  - EventStore integration
  - CQRS pattern support
  - Aggregate compilation

- [ ] **Distributed Systems**
  - Cluster support annotations
  - PubSub patterns
  - Node communication helpers

### Improvements
- [ ] Memory usage optimizations
- [ ] Compilation speed improvements
- [ ] Better macro expansion debugging

### Production-Ready Features
- [ ] **Telemetry Integration**
  - `@:telemetry` annotation
  - Automatic instrumentation
  - Metrics collection

- [ ] **GraphQL Support**
  - Absinthe schema generation
  - Resolver compilation
  - Subscription support

- [ ] **Database Enhancements**
  - Multi-database support
  - Read/write splitting
  - Connection pooling configuration

### Improvements
- [ ] Production deployment guides
- [ ] Performance profiling tools
- [ ] Security audit tools

## Version 1.0.0 (December 2024) ✅ COMPLETE
*Focus: Production-Ready Release*

### Status: **SHIPPED** 🎉
All v1.0 features are complete and production-ready!

### Completed Features ✅
- [x] **Expression Type Compilation** - All 50+ TypedExpr types
- [x] **Complete Annotation System** - 11 annotations (@:schema, @:liveview, @:genserver, etc.)
- [x] **Ecto Integration** - Schemas, changesets, migrations, queries, Ecto.Multi
- [x] **Phoenix LiveView** - Full component compilation with event handling
- [x] **OTP GenServer** - Complete lifecycle callbacks and supervision
- [x] **Template System (HEEx)** - HXX processing for Phoenix templates
- [x] **Migration DSL** - Table operations with Mix integration
- [x] **Protocol & Behavior System** - Full polymorphic dispatch
- [x] **Phoenix Router DSL** - Controllers and routing
- [x] **Abstract Type Compilation** - Operator overloading support
- [x] **Package Resolution** - Reliable module discovery
- [x] **Mix Integration** - Full build pipeline with file watching
- [x] **LLM-Optimized Documentation** - AI-ready docs generation
- [x] **Project Generator** - Template-based project creation
- [x] **Standard Library Externs** - Core Elixir/OTP modules
- [x] **Typedef Compilation** - Type aliases and structures

### Test Coverage ✅
- 28/28 snapshot tests passing
- 130 Mix tests passing
- All examples working

## Version 1.1.0 (Q1 2025)
*Focus: Documentation & Developer Experience*

### Documentation Automation
- [ ] **LLM Documentation Generator**
  - Auto-generate AI-optimized documentation from source code
  - Documentation regenerates automatically when compiler changes
  - Single source of truth approach - never duplicate information
  
- [ ] **API Documentation from Compiler**
  - Parse ElixirCompiler source to generate API docs
  - Automatic regeneration on compiler changes
  - Never manually maintain API docs
  
- [ ] **Pattern Library from Examples**
  - Auto-extract working patterns from examples/ directory
  - Patterns regenerate when examples change
  - Always extract from working code
  
- [ ] **Project Generator Integration**
  - Include LLM-optimized docs in every new project
  - Customize docs based on project type
  - Progressive enhancement as project grows

### Documentation Enhancements
- [ ] **Comprehensive API Reference**
  - Formal documentation for all public classes/functions
  - Generated from source with examples
  
- [ ] **Migration Guide**
  - Help existing Elixir developers transition to Haxe
  - Show equivalent patterns and idioms
  - Gradual migration strategies
  
- [ ] **Development Workflow Guide**
  - Daily workflow including debugging and deployment
  - IDE setup and configuration
  - Testing and CI/CD integration
  
- [ ] **Installation Troubleshooting**
  - Platform-specific issue resolution
  - Common problems and solutions
  - Environment setup guides
  
- [ ] **Video Tutorial Scripts**
  - Installation walkthrough
  - First project creation
  - Key features demonstration

## Version 1.2.0 (Q2 2025)
*Focus: Performance Optimization*

### Compilation Performance
- [ ] **Caching System**
  - Module-level caching
  - Incremental compilation cache
  - Dependency graph optimization
  
- [ ] **Parallel Processing**
  - Multi-threaded compilation
  - Parallel module processing
  - Concurrent type checking
  
- [ ] **Large Codebase Optimization**
  - Lazy loading of modules
  - Memory usage optimization
  - Compilation progress reporting
  
- [ ] **Build Performance**
  - Target <10ms for incremental builds
  - <100ms for full project compilation
  - Memory footprint reduction

## Long-term Vision (Beyond 1.0)

### Cross-Platform Scenarios 🌍
*The true power of Reflaxe.Elixir: Write once, deploy anywhere*

#### Shared Business Logic Across Platforms
- **Validation Rules**: Write validation logic once in Haxe, compile to:
  - Elixir for Phoenix backend validation
  - JavaScript for React/Vue frontend validation
  - Java/Kotlin for Android app validation
  - Swift/Objective-C for iOS app validation
  - No more keeping validation in sync across platforms!

#### Microservices in Different Runtimes
- **Core Services**: Keep fault-tolerant services on BEAM (Elixir)
- **CPU-Intensive Services**: Compile performance-critical code to C++
- **Web Services**: Compile to Node.js for existing JS infrastructure
- **Data Processing**: Compile to Python for ML pipeline integration
- All from the same Haxe codebase with shared interfaces

#### Progressive Performance Optimization
- **Phase 1**: Start with everything in Elixir for rapid development
- **Phase 2**: Profile and identify bottlenecks
- **Phase 3**: Recompile hot paths to C++ without changing interfaces
- **Phase 4**: Deploy hybrid system with optimal runtime per component

#### Enterprise Migration Scenarios
- **Gradual Java Migration**: Move Java services to Elixir/BEAM incrementally
- **TypeScript Consolidation**: Unify TypeScript frontend and backend code in Haxe
- **Multi-Cloud Deployment**: Same code deployed to different cloud runtimes
- **Legacy System Integration**: Compile to target platform's native language

### Advanced Features
- **Self-Hosting Improvements** 🧪 *Ultimate Dogfooding*
  - Convert HaxeWatcher (file watching) from Elixir to Haxe→Elixir
  - Convert HaxeServer (compiler server management) from Elixir to Haxe→Elixir  
  - Convert all Mix tasks from Elixir to Haxe→Elixir
  - Rewrite development infrastructure using our own compiler
  - Full build pipeline written in Haxe for consistency and type safety
  - Performance comparison: compiled vs direct Elixir for development tooling
  - Validation of complex OTP patterns (GenServer, supervision trees, file watching)
  - Test compiler on sophisticated language features it needs to support itself

- **Machine Learning Integration**
  - Nx (Numerical Elixir) support
  - Tensor typing
  - Model compilation

- **Native Compilation**
  - NIF generation from Haxe
  - Rust integration
  - Performance-critical path optimization

- **Cloud Native**
  - Kubernetes operators
  - Service mesh integration
  - Cloud provider SDKs

- **Mobile Support**
  - LiveView Native compilation
  - React Native bridge
  - Flutter integration

### Community Goals
- Regular release cycle (quarterly)
- Community-driven feature requests
- Educational content and tutorials
- Conference talks and workshops
- Corporate sponsorship program

## Contributing to the Roadmap

We welcome community input on our roadmap! Here's how you can contribute:

1. **Feature Requests**: Open an issue with the `enhancement` label
2. **Prioritization**: Vote on issues with 👍 reactions
3. **Implementation**: Pick up issues marked `help wanted`
4. **Feedback**: Comment on roadmap items with your use cases

## Versioning Strategy

We follow [Semantic Versioning](https://semver.org/):
- **Patch releases** (0.1.x): Bug fixes, documentation updates
- **Minor releases** (0.x.0): New features, backwards compatible
- **Major releases** (x.0.0): Breaking changes, major features

## Release Schedule

- **Patch releases**: As needed (typically monthly)
- **Minor releases**: Quarterly
- **Major releases**: Annually

## Current Focus

**v1.0 is COMPLETE!** 🎉 Our immediate priorities for v1.1.0:
1. LLM Documentation Generator - Auto-generate AI-optimized docs
2. API Documentation Automation - Generate from compiler source
3. Pattern Library Extraction - Auto-extract from examples
4. Migration Guide - Help Elixir developers transition

## Get Involved

- Star the repository to show support
- Join discussions in GitHub Discussions
- Contribute code via pull requests
- Share your use cases and feedback
- Help with documentation and examples

---

*This roadmap is subject to change based on community feedback and project priorities. Last updated: December 2024*