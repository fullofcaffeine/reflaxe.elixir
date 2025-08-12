# Reflaxe.Elixir Roadmap

This document outlines the future development plans for Reflaxe.Elixir, organized by release targets and priorities.

## Version 0.2.0 (Q1 2025)
*Focus: LLM Development Experience*

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

### Improvements
- [x] **File Watching & Incremental Compilation** ✅
  - HaxeWatcher for automatic file change detection
  - HaxeServer for incremental compilation via `haxe --wait`
  - Mix integration with `mix compile.haxe --watch` 
  - Sub-second compilation times optimized for LLM iteration cycles

- [ ] Performance optimizations for large codebases
- [ ] Better error messages with source location  
- [ ] IDE integration improvements

## Version 0.3.0 (Q2 2024)
*Focus: Testing & Developer Experience*

### 🎯 Source Mapping Achievement
**Reflaxe.Elixir is the FIRST Reflaxe target to implement source mapping!** While other targets (C++, C#, Go, GDScript) don't provide source maps, we've pioneered this feature for superior debugging experience. Current status:
- ✅ Generating valid Source Map v3 files with real VLQ data
- ✅ Proper sources array tracking Haxe files
- ✅ Mix task infrastructure for querying source maps
- ⚠️ VLQ decoder needs completion for position lookups to work

### Features
- [ ] **Test DSL**
  - `@:test` annotation for ExUnit tests
  - Property-based testing support
  - Mock generation for behaviors

- [ ] **Debugging Support** 🚀 *First Reflaxe target with source mapping!*
  - [x] Source map generation (.ex.map files with VLQ encoding)
  - [ ] Complete VLQ Base64 decoder implementation
    - Current: Mock implementation returns placeholder mappings
    - Needed: Proper VLQ decoding following Source Map v3 spec
    - Reference: Haxe's `context/sourcemaps.ml` implementation
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

## Version 0.4.0 (Q3 2024)
*Focus: Advanced OTP Patterns*

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

## Version 0.5.0 (Q4 2024)
*Focus: Production Readiness*

### Features
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

## Version 1.0.0 (2025)
*Focus: Stable Release*

### Goals
- [ ] API stability guarantee
- [ ] Comprehensive documentation
- [ ] Full Phoenix feature parity
- [ ] Production-proven in real applications
- [ ] Performance benchmarks published
- [ ] Migration guides from Elixir

### Ecosystem
- [ ] Haxelib package registry
- [ ] Hex.pm package publishing
- [ ] Community templates and generators
- [ ] Plugin system for extensions

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
- **Self-Hosting Improvements**
  - Convert HaxeWatcher (file watching) from Elixir to Haxe→Elixir
  - Convert HaxeServer (compiler server management) from Elixir to Haxe→Elixir
  - Full build pipeline written in Haxe for consistency

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

Our immediate priorities for the next release (0.2.0):
1. Live Components support
2. Advanced router features
3. Performance optimizations
4. Better error messages

## Get Involved

- Star the repository to show support
- Join discussions in GitHub Discussions
- Contribute code via pull requests
- Share your use cases and feedback
- Help with documentation and examples

---

*This roadmap is subject to change based on community feedback and project priorities. Last updated: January 2024*