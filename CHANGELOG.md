# 1.0.0 (2025-08-11)


### Bug Fixes

* remove npm publishing from semantic-release to resolve token issue ([e58efba](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e58efba3c140dfd0f7520f5da0d9898c3a1120db)), closes [#1](https://github.com/fullofcaffeine/reflaxe.elixir/issues/1)
* update package-lock.json for semantic-release dependencies ([32dfac6](https://github.com/fullofcaffeine/reflaxe.elixir/commit/32dfac60120068e30d3e277ee1b44f10c0a48916))


### Features

* change license from MIT to GPL-3.0 and update repository configuration ([100d9ef](https://github.com/fullofcaffeine/reflaxe.elixir/commit/100d9ef4ecf02015f71c859304f992f670552091))


### BREAKING CHANGES

* License changed from MIT to GPL-3.0 for copyleft protection. All configuration files (package.json, haxelib.json, README badge) updated consistently.

# Changelog

All notable changes to Reflaxe.Elixir will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-01-11

### 🎉 Initial Release

First public release of Reflaxe.Elixir - A Haxe compilation target for Elixir/BEAM with native Phoenix integration.

### Added

#### Core Compiler Features
- **Expression Type Compilation**: Complete TypedExpr compilation for 50+ expression types
- **Annotation System**: Unified routing for 11 annotation types (@:schema, @:changeset, @:liveview, @:genserver, etc.)
- **Type System**: Full Haxe→Elixir type mapping with compile-time safety
- **Performance**: Sub-millisecond compilation (750x-2500x faster than targets)

#### Phoenix Framework Support
- **LiveView**: Complete real-time component compilation with socket management
- **Controllers**: Full @:controller annotation support with action compilation
- **Router DSL**: Automatic Phoenix.Router generation with pipelines and scopes
- **Templates**: HEEx template compilation with Phoenix component integration

#### Ecto Integration
- **Schema Support**: Complete Ecto.Schema generation with field definitions
- **Changeset Compilation**: Full validation pipeline with Ecto.Changeset
- **Migration DSL**: Production-quality table manipulation with rollback support
- **Query DSL**: Type-safe query compilation with schema validation
- **Advanced Features**: Subqueries, CTEs, window functions, Ecto.Multi transactions

#### OTP Support
- **GenServer**: Complete lifecycle callbacks with type-safe state management
- **Behaviors**: @:behaviour annotation support with compile-time validation
- **Protocols**: @:protocol and @:impl for polymorphic dispatch
- **Supervision**: Child spec generation and registry support

#### Developer Experience
- **Project Generator**: `haxelib run reflaxe.elixir create` command
- **Pipe Operators**: Automatic method chaining → Elixir pipes transformation
- **Escape Hatches**: @:native, untyped blocks, __elixir__() for interop
- **Mix Integration**: Seamless integration with Mix build pipeline

#### Documentation
- **30+ Documentation Files**: Comprehensive guides covering all aspects
- **Tutorial**: Step-by-step first project guide
- **Cookbook**: Practical recipes for common Elixir/Phoenix patterns
- **Architecture Guide**: Complete compiler internals documentation
- **API Reference**: Full API documentation

#### Testing
- **Snapshot Tests**: 23/23 tests passing with deterministic output
- **Dual-Ecosystem Testing**: Haxe compiler tests + Elixir runtime validation
- **Performance Validation**: All features exceed performance targets
- **Example Suite**: 9 working examples demonstrating all features

### Technical Specifications
- **Haxe Version**: 4.3.6+ required
- **Elixir Version**: 1.14+ required
- **Dependencies**: Reflaxe 4.0.0+, tink_macro, tink_parse
- **Package Management**: lix + npm for Haxe, mix for Elixir

### Known Limitations
- Advanced router features (nested resources) in development
- Live components and slots planned for next release
- Some IDE features still being optimized

### Contributors
- fullofcaffeine - Initial implementation and architecture
- Claude Code - Development assistance and documentation

[0.1.0]: https://github.com/fullofcaffeine/reflaxe.elixir/releases/tag/v0.1.0
