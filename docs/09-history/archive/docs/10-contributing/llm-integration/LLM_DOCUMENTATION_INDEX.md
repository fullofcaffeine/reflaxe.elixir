# LLM Documentation Index for Reflaxe.Elixir

**Purpose**: Complete navigation guide for AI agents working on Reflaxe.Elixir development

> **Updated for New docs/ Structure**: All 232 documentation files organized with progressive disclosure

## 🏗️ Core Architecture (START HERE)

### Essential Understanding  
- [**05-architecture/ARCHITECTURE.md**](../05-architecture/ARCHITECTURE.md) - **CRITICAL**: Complete system architecture
- [**04-api-reference/ELIXIR_RUNTIME_ARCHITECTURE.md**](../04-api-reference/ELIXIR_RUNTIME_ARCHITECTURE.md) - Development vs production runtime
- [**05-architecture/COMPILATION_FLOW.md**](../05-architecture/COMPILATION_FLOW.md) - How Haxe→Elixir compilation works
- [**03-compiler-development/MACRO_PRINCIPLES.md**](../03-compiler-development/MACRO_PRINCIPLES.md) - **CRITICAL**: Macro-time vs runtime concepts

### Build System & Integration
- [**04-api-reference/HXML_ARCHITECTURE.md**](../04-api-reference/HXML_ARCHITECTURE.md) - HXML build configuration patterns
- [**04-api-reference/MIX_INTEGRATION.md**](../04-api-reference/MIX_INTEGRATION.md) - Complete Mix integration and workflows

## 🧪 Testing (CRITICAL FOR DEVELOPMENT)

### Testing Overview & Strategy
- [**03-compiler-development/TESTING_OVERVIEW.md**](../03-compiler-development/TESTING_OVERVIEW.md) - **MUST READ**: Complete testing guide for LLMs
- [**03-compiler-development/TESTING_PRINCIPLES.md**](../03-compiler-development/TESTING_PRINCIPLES.md) - Critical testing rules and snapshot testing
- [**05-architecture/TESTING_ARCHITECTURE.md**](../05-architecture/TESTING_ARCHITECTURE.md) - Technical testing infrastructure
- [**03-compiler-development/TEST_SUITE_DEEP_DIVE.md**](../03-compiler-development/TEST_SUITE_DEEP_DIVE.md) - What each test validates

### Specialized Testing
- [**03-compiler-development/COMPILER_TESTING_GUIDE.md**](../03-compiler-development/COMPILER_TESTING_GUIDE.md) - Compiler development testing workflows
- [**03-compiler-development/MACRO_TIME_TESTING_STRATEGY.md**](../03-compiler-development/MACRO_TIME_TESTING_STRATEGY.md) - Testing macro-time vs runtime components
- [**02-user-guide/PARALLEL_TEST_ACHIEVEMENT.md**](../02-user-guide/PARALLEL_TEST_ACHIEVEMENT.md) - Parallel testing infrastructure
- [**03-compiler-development/EXUNIT_TESTING_GUIDE.md**](../03-compiler-development/EXUNIT_TESTING_GUIDE.md) - ExUnit integration patterns

## 🚀 Getting Started & Quick References

### New User Onboarding
- [**01-getting-started/installation.md**](../01-getting-started/installation.md) - Complete setup with troubleshooting
- [**01-getting-started/development-workflow.md**](../01-getting-started/development-workflow.md) - Day-to-day development practices
- [**07-patterns/quick-start-patterns.md**](../07-patterns/quick-start-patterns.md) - Essential copy-paste patterns

### API References & Quick Guides  
- [**04-api-reference/haxe-stdlib-api-reference.md**](../04-api-reference/haxe-stdlib-api-reference.md) - Complete Haxe standard library reference
- [**04-api-reference/ANNOTATIONS.md**](../04-api-reference/ANNOTATIONS.md) - Complete annotation reference
- [**04-api-reference/FEATURES.md**](../04-api-reference/FEATURES.md) - Production-ready feature status

## 🎯 User Guide (30+ Complete Guides)

### Core Concepts
- [**02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md**](../02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md) - Core language concepts
- [**02-user-guide/HAXE_ELIXIR_MAPPINGS.md**](../02-user-guide/HAXE_ELIXIR_MAPPINGS.md) - Language conversion guide
- [**02-user-guide/IDIOMATIC_CODE_GENERATION.md**](../02-user-guide/IDIOMATIC_CODE_GENERATION.md) - Writing idiomatic output

### Phoenix & LiveView Integration
- [**02-user-guide/PHOENIX_INTEGRATION.md**](../02-user-guide/PHOENIX_INTEGRATION.md) - Building Phoenix applications
- [**02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md**](../02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md) - Real-time UI patterns
- [**02-user-guide/HXX_ARCHITECTURE.md**](../02-user-guide/HXX_ARCHITECTURE.md) - Template system architecture
- [**02-user-guide/HXX_IMPLEMENTATION.md**](../02-user-guide/HXX_IMPLEMENTATION.md) - Template implementation details

### Advanced Features
- [**02-user-guide/ASYNC_AWAIT.md**](../02-user-guide/ASYNC_AWAIT.md) - Async/await patterns
- [**02-user-guide/OTP_CHILD_SPECS.md**](../02-user-guide/OTP_CHILD_SPECS.md) - OTP integration patterns  
- [**02-user-guide/ESCAPE_HATCHES.md**](../02-user-guide/ESCAPE_HATCHES.md) - Using Elixir code from Haxe
- [**02-user-guide/MODULE_RESOLUTION_ROADMAP.md**](../02-user-guide/MODULE_RESOLUTION_ROADMAP.md) - Module naming strategies

## 🏗️ Complete Architecture Guide (40+ Documents)

### Core Architecture Patterns
- [**05-architecture/FUNCTIONAL_PATTERNS.md**](../05-architecture/FUNCTIONAL_PATTERNS.md) - Imperative→functional transformations
- [**05-architecture/BEAM_TYPE_ABSTRACTIONS.md**](../05-architecture/BEAM_TYPE_ABSTRACTIONS.md) - BEAM-specific type handling
- [**05-architecture/FILE_NAMING_ARCHITECTURE.md**](../05-architecture/FILE_NAMING_ARCHITECTURE.md) - Snake_case conversion system
- [**05-architecture/CONTEXT_SENSITIVE_COMPILATION.md**](../05-architecture/CONTEXT_SENSITIVE_COMPILATION.md) - Context-aware compilation

### Advanced Compilation Features
- [**05-architecture/ENHANCED_PATTERN_MATCHING.md**](../05-architecture/ENHANCED_PATTERN_MATCHING.md) - Pattern matching compilation
- [**05-architecture/ENUM_CONSTRUCTOR_PATTERNS.md**](../05-architecture/ENUM_CONSTRUCTOR_PATTERNS.md) - Enum compilation strategies
- [**05-architecture/VARIABLE_SUBSTITUTION.md**](../05-architecture/VARIABLE_SUBSTITUTION.md) - Variable renaming in compilation

## 📚 API Reference (40+ Technical References)

### Core APIs & Integration
- [**04-api-reference/ELIXIR_INJECTION_GUIDE.md**](../04-api-reference/ELIXIR_INJECTION_GUIDE.md) - Code injection patterns
- [**04-api-reference/EXTERN_CREATION_GUIDE.md**](../04-api-reference/EXTERN_CREATION_GUIDE.md) - Creating extern definitions
- [**04-api-reference/ROUTER_DSL.md**](../04-api-reference/ROUTER_DSL.md) - Phoenix router DSL
- [**04-api-reference/STANDARD_LIBRARY_HANDLING.md**](../04-api-reference/STANDARD_LIBRARY_HANDLING.md) - Standard library architecture

### Haxe Integration
- [**04-api-reference/HAXE_MACRO_APIS.md**](../04-api-reference/HAXE_MACRO_APIS.md) - **CRITICAL**: Correct macro API usage
- [**04-api-reference/HAXE_MODULE_SYSTEM.md**](../04-api-reference/HAXE_MODULE_SYSTEM.md) - Module system integration
- [**04-api-reference/HAXE_THREADING_ANALYSIS.md**](../04-api-reference/HAXE_THREADING_ANALYSIS.md) - Threading and parallelization

## 📋 Practical Guides (25+ How-To Guides)

### Development Workflows
- [**06-guides/TROUBLESHOOTING.md**](../06-guides/TROUBLESHOOTING.md) - Comprehensive problem solving
- [**06-guides/migration-guide.md**](../06-guides/migration-guide.md) - Migrating from Elixir to Haxe
- [**06-guides/PHOENIX_INTEGRATION_GUIDE.md**](../06-guides/PHOENIX_INTEGRATION_GUIDE.md) - Step-by-step Phoenix integration

### Advanced Topics
- [**06-guides/HXX_GUIDE.md**](../06-guides/HXX_GUIDE.md) - HXX template system guide
- [**06-guides/ADVANCED_ECTO_GUIDE.md**](../06-guides/ADVANCED_ECTO_GUIDE.md) - Advanced Ecto integration
- [**06-guides/PERFORMANCE_GUIDE.md**](../06-guides/PERFORMANCE_GUIDE.md) - Performance optimization

## 🎯 Code Patterns (20+ Copy-Paste Examples)

### Essential Patterns
- [**07-patterns/FUNCTIONAL_PATTERNS.md**](../07-patterns/FUNCTIONAL_PATTERNS.md) - Functional programming patterns
- [**07-patterns/PHOENIX_LIVEVIEW_PATTERNS.md**](../07-patterns/PHOENIX_LIVEVIEW_PATTERNS.md) - LiveView development patterns
- [**07-patterns/STATIC_EXTENSION_PATTERNS.md**](../07-patterns/STATIC_EXTENSION_PATTERNS.md) - Extension method patterns

### Compiler Development Patterns
- [**07-patterns/COMPILER_PATTERNS.md**](../07-patterns/COMPILER_PATTERNS.md) - Compiler development patterns
- [**07-patterns/MACRO_TIME_TESTING_STRATEGY.md**](../07-patterns/MACRO_TIME_TESTING_STRATEGY.md) - Testing strategy patterns

## 🗺️ Roadmap & Planning

### Vision & Strategy
- [**08-roadmap/vision.md**](../08-roadmap/vision.md) - Long-term project vision
- [**08-roadmap/ACTIVE_PRD.md**](../08-roadmap/ACTIVE_PRD.md) - Current product requirements
- [**08-roadmap/product-requirements-document.md**](../08-roadmap/product-requirements-document.md) - Comprehensive PRD

## 📜 Historical Context

### Implementation History
- [**09-history/TASK_HISTORY.md**](../09-history/TASK_HISTORY.md) - Complete implementation log (3200+ entries)
- [**09-history/archive/**](../09-history/archive/) - Historical development plans and PRDs

## 🤝 Contributing

### Development Guidelines
- [**updating-agents-md.md**](../updating-agents-md.md) - AI context and unified documentation strategy
- [**DOCUMENTATION_PHILOSOPHY.md**](../DOCUMENTATION_PHILOSOPHY.md) - Documentation principles

## 🔍 Cross-Cutting Topics

### Testing (All Documents)
Find testing documentation across sections:
- **03-compiler-development/**: TESTING_*.md, TEST_*.md, MACRO_TIME_TESTING_*.md
- **05-architecture/**: TESTING_ARCHITECTURE*.md, TEST_TYPES.md
- **06-guides/**: *TESTING*.md, COMPILER_TESTING_GUIDE.md
- **07-patterns/**: MACRO_TIME_TESTING_STRATEGY.md

### Phoenix Integration (All Documents)  
Find Phoenix documentation across sections:
- **02-user-guide/**: PHOENIX_*.md, HXX_*.md
- **04-api-reference/**: ROUTER_DSL.md
- **06-guides/**: PHOENIX_*.md
- **07-patterns/**: PHOENIX_*.md

### Architecture (All Documents)
Find architecture documentation across sections:
- **05-architecture/**: All 40+ architecture documents
- **03-compiler-development/**: COMPILATION_FLOW.md, MACRO_PRINCIPLES.md
- **04-api-reference/**: *_ARCHITECTURE.md files

---

**Total Documentation Coverage**: 232 markdown files across 10 organized sections with progressive disclosure for optimal learning paths.
