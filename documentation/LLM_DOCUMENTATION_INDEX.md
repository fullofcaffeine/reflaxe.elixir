# LLM Documentation Index for Reflaxe.Elixir

**Purpose**: Complete navigation guide for AI agents working on Reflaxe.Elixir development

## 🏗️ Core Architecture (START HERE)

### Essential Understanding
- [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md) - **CRITICAL**: Complete system architecture
- [`ELIXIR_RUNTIME_ARCHITECTURE.md`](ELIXIR_RUNTIME_ARCHITECTURE.md) - Development vs production runtime distinction
- [`COMPILATION_FLOW.md`](COMPILATION_FLOW.md) - How Haxe→Elixir compilation works
- [`macro/MACRO_PRINCIPLES.md`](macro/MACRO_PRINCIPLES.md) - **CRITICAL**: Macro-time vs runtime concepts

### Build System & Integration
- [`HXML_ARCHITECTURE.md`](HXML_ARCHITECTURE.md) - HXML build configuration patterns
- [`MIX_INTEGRATION.md`](MIX_INTEGRATION.md) - Complete Mix integration and workflows
- [`ESBUILD_INTEGRATION.md`](ESBUILD_INTEGRATION.md) - JavaScript asset pipeline integration

## 🧪 Testing (CRITICAL FOR DEVELOPMENT)

### Testing Overview & Strategy
- [`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md) - **MUST READ**: Complete testing guide for LLMs
- [`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md) - Critical testing rules and snapshot testing
- [`architecture/TESTING.md`](architecture/TESTING.md) - Technical testing infrastructure
- [`TEST_SUITE_DEEP_DIVE.md`](TEST_SUITE_DEEP_DIVE.md) - What each test validates

### Specialized Testing
- [`COMPILER_TESTING_GUIDE.md`](COMPILER_TESTING_GUIDE.md) - Compiler development testing workflows
- [`MACRO_TIME_TESTING_STRATEGY.md`](MACRO_TIME_TESTING_STRATEGY.md) - Testing macro-time vs runtime components
- [`PARALLEL_TEST_ACHIEVEMENT.md`](PARALLEL_TEST_ACHIEVEMENT.md) - Parallel testing infrastructure
- [`EXUNIT_TESTING_GUIDE.md`](EXUNIT_TESTING_GUIDE.md) - ExUnit integration patterns

## 🔧 Development Guides

### Getting Started
- [`guides/GETTING_STARTED.md`](guides/GETTING_STARTED.md) - Complete setup guide
- [`guides/QUICKSTART.md`](guides/QUICKSTART.md) - Fast setup for experienced developers
- [`guides/TUTORIAL_FIRST_PROJECT.md`](guides/TUTORIAL_FIRST_PROJECT.md) - Step-by-step first project
- [`PROJECT_GENERATOR_GUIDE.md`](PROJECT_GENERATOR_GUIDE.md) - Mix task project generation

### Development Best Practices
- [`COMPILER_BEST_PRACTICES.md`](COMPILER_BEST_PRACTICES.md) - **CRITICAL**: Compiler development practices
- [`HAXE_BEST_PRACTICES.md`](HAXE_BEST_PRACTICES.md) - Modern Haxe 4.3+ patterns for Reflaxe.Elixir
- [`guides/DEVELOPER_PATTERNS.md`](guides/DEVELOPER_PATTERNS.md) - Best practices and patterns
- [`llm/LLM_DOCUMENTATION_GUIDE.md`](llm/LLM_DOCUMENTATION_GUIDE.md) - Documentation standards for AI agents

## 🌟 Language Features & Implementation

### Core Language Features
- [`FUNCTIONAL_PATTERNS.md`](FUNCTIONAL_PATTERNS.md) - Imperative→functional transformations
- [`ENUM_CONSTRUCTOR_PATTERNS.md`](ENUM_CONSTRUCTOR_PATTERNS.md) - Enum compilation patterns
- [`ARRAY_FUNCTIONAL_METHODS.md`](ARRAY_FUNCTIONAL_METHODS.md) - Array method implementations
- [`STANDARD_LIBRARY_HANDLING.md`](STANDARD_LIBRARY_HANDLING.md) - Standard library architecture

### Advanced Features
- [`ASYNC_AWAIT.md`](ASYNC_AWAIT.md) - **PRODUCTION READY**: JavaScript async/await support
- [`HXX_VS_TEMPLATE.md`](HXX_VS_TEMPLATE.md) - **PRODUCTION READY**: HXX template system
- [`ROUTER_DSL.md`](ROUTER_DSL.md) - **PRODUCTION READY**: Phoenix Router DSL with type safety
- [`ANNOTATION_SYSTEM.md`](ANNOTATION_SYSTEM.md) - Framework annotation patterns

### File & Code Generation
- [`FILE_NAMING_ARCHITECTURE.md`](FILE_NAMING_ARCHITECTURE.md) - **CRITICAL**: PascalCase→snake_case conversion
- [`FILE_GENERATION.md`](FILE_GENERATION.md) - File output patterns
- [`IDIOMATIC_SYNTAX.md`](IDIOMATIC_SYNTAX.md) - Generating idiomatic Elixir code

## ⚡ Phoenix Framework Integration

### Phoenix Core Integration
- [`PHOENIX_INTEGRATION.md`](PHOENIX_INTEGRATION.md) - Complete Phoenix framework support
- [`PHOENIX_INTEGRATION_GUIDE.md`](PHOENIX_INTEGRATION_GUIDE.md) - Integration guide and patterns
- [`ECTO_INTEGRATION_PATTERNS.md`](ECTO_INTEGRATION_PATTERNS.md) - Database integration patterns
- [`FRAMEWORK_CONVENTIONS.md`](FRAMEWORK_CONVENTIONS.md) - Phoenix directory structure requirements

### LiveView & Real-time Features
- [`guides/HXX_GUIDE.md`](guides/HXX_GUIDE.md) - HXX template usage guide
- [`guides/HXX_INTERPOLATION_SYNTAX.md`](guides/HXX_INTERPOLATION_SYNTAX.md) - HXX syntax reference
- [`guides/TYPE_SAFE_ASSIGNS.md`](guides/TYPE_SAFE_ASSIGNS.md) - Type-safe socket assigns

## 🛠️ Haxe Language Reference

### Haxe Fundamentals
- [`HAXE_API_REFERENCE.md`](HAXE_API_REFERENCE.md) - Complete Haxe standard library reference
- [`HAXE_LANGUAGE_FUNDAMENTALS.md`](HAXE_LANGUAGE_FUNDAMENTALS.md) - Core language concepts
- [`HAXE_MACRO_APIS.md`](HAXE_MACRO_APIS.md) - **CRITICAL**: Correct macro API usage patterns
- [`paradigms/PARADIGM_BRIDGE.md`](paradigms/PARADIGM_BRIDGE.md) - Imperative→functional paradigm bridge

### Advanced Haxe Patterns
- [`guides/HAXE_OPERATOR_OVERLOADING.md`](guides/HAXE_OPERATOR_OVERLOADING.md) - Operator overloading patterns
- [`STATIC_EXTENSION_PATTERNS.md`](STATIC_EXTENSION_PATTERNS.md) - Extension method patterns
- [`DUAL_TARGET_COMPILATION.md`](DUAL_TARGET_COMPILATION.md) - Client-server compilation strategies

## 📚 API References & Quick Guides

### Quick References
- [`llm/API_QUICK_REFERENCE.md`](llm/API_QUICK_REFERENCE.md) - Fast API lookup for common tasks
- [`llm/QUICK_START_PATTERNS.md`](llm/QUICK_START_PATTERNS.md) - Common implementation patterns
- [`reference/ANNOTATIONS.md`](reference/ANNOTATIONS.md) - Complete annotation reference
- [`reference/FEATURES.md`](reference/FEATURES.md) - Production-ready feature status

### LLM-Specific Guides
- [`llm/INDEX.md`](llm/INDEX.md) - LLM workflow compatibility guide
- [`llm/REFLAXE_ELIXIR_BASICS.md`](llm/REFLAXE_ELIXIR_BASICS.md) - Essential concepts for AI agents
- [`llm/LLM_WORKFLOW_COMPATIBILITY.md`](llm/LLM_WORKFLOW_COMPATIBILITY.md) - AI agent integration patterns

## 🔍 Debugging & Troubleshooting

### Debugging Infrastructure
- [`DEBUGGING.md`](DEBUGGING.md) - General debugging strategies
- [`SOURCE_MAPPING.md`](SOURCE_MAPPING.md) - Source mapping for error location
- [`llm/LLM_STACKTRACE_DEBUGGING_COMPLETE.md`](llm/LLM_STACKTRACE_DEBUGGING_COMPLETE.md) - AI agent debugging guide
- [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) - Common issues and solutions

### Macro & Compiler Debugging
- [`macro/MACRO_DEBUGGING.md`](macro/MACRO_DEBUGGING.md) - Macro-specific debugging techniques
- [`COMPILER_RESOLUTION_ISSUES.md`](COMPILER_RESOLUTION_ISSUES.md) - Compilation problem patterns
- [`WHY_MOCKS_NOT_REAL_COMPILER.md`](WHY_MOCKS_NOT_REAL_COMPILER.md) - Testing architecture explanation

## 🎯 Specialized Topics

### Performance & Optimization
- [`PERFORMANCE_GUIDE.md`](PERFORMANCE_GUIDE.md) - Performance optimization strategies
- [`PARALLEL_TEST_PERFORMANCE.md`](PARALLEL_TEST_PERFORMANCE.md) - Test suite performance analysis
- [`HXX_PERFORMANCE.md`](HXX_PERFORMANCE.md) - Template compilation performance

### Advanced Implementation
- [`BEAM_TYPE_ABSTRACTIONS.md`](BEAM_TYPE_ABSTRACTIONS.md) - BEAM-specific type patterns
- [`ENHANCED_PATTERN_MATCHING.md`](ENHANCED_PATTERN_MATCHING.md) - Pattern matching compilation
- [`LOOP_TRANSFORMATION_SIMPLIFIED.md`](LOOP_TRANSFORMATION_SIMPLIFIED.md) - Loop pattern compilation

### Security & Code Safety
- [`CODE_INJECTION.md`](CODE_INJECTION.md) - **CRITICAL**: Code injection policy and enforcement
- [`ESCAPE_HATCHES.md`](ESCAPE_HATCHES.md) - Safe usage of Dynamic and escape mechanisms

## 📖 Examples & Cookbooks

### Practical Examples
- [`guides/EXAMPLES.md`](guides/EXAMPLES.md) - Real-world usage examples
- [`EXAMPLES_GUIDE.md`](EXAMPLES_GUIDE.md) - Example project walkthrough
- [`COOKBOOK.md`](COOKBOOK.md) - Common recipes and patterns
- [`guides/COOKBOOK.md`](guides/COOKBOOK.md) - Practical development cookbook

### Migration & Conversion
- [`guides/ROUTER_MIGRATION_GUIDE.md`](guides/ROUTER_MIGRATION_GUIDE.md) - Router DSL migration
- [`guides/HXX_MIGRATION_GUIDE.md`](guides/HXX_MIGRATION_GUIDE.md) - Template migration patterns
- [`guides/migration-guide.md`](guides/migration-guide.md) - General migration strategies

## 📝 Project Management & History

### Development History
- [`TASK_HISTORY.md`](TASK_HISTORY.md) - Complete implementation history
- [`sessions/2025-01-16-enum-patterns.md`](sessions/2025-01-16-enum-patterns.md) - Recent development sessions
- [`history/LEARNINGS.md`](history/LEARNINGS.md) - Key lessons learned

### Project Status & Planning
- [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) - Current feature status
- [`plans/ACTIVE_PRD.md`](plans/ACTIVE_PRD.md) - Active product requirements
- [`DOCUMENTATION_PHILOSOPHY.md`](DOCUMENTATION_PHILOSOPHY.md) - Documentation maintenance principles

## 🔧 Mix Integration & Tasks

### Mix Task Reference
- [`reference/MIX_TASKS.md`](reference/MIX_TASKS.md) - Complete Mix task reference
- [`MIX_TASK_GENERATORS.md`](MIX_TASK_GENERATORS.md) - Code generation tasks
- [`WATCHER_WORKFLOW.md`](WATCHER_WORKFLOW.md) - File watching development workflow

## 🎯 When To Use Which Document

### 🚨 **For New LLM Agents (START HERE)**
1. [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md) - Understand the system
2. [`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md) - Learn testing approach
3. [`COMPILER_BEST_PRACTICES.md`](COMPILER_BEST_PRACTICES.md) - Development principles
4. [`FILE_NAMING_ARCHITECTURE.md`](FILE_NAMING_ARCHITECTURE.md) - Critical for file generation

### 🔧 **For Bug Fixes & Compiler Work**
1. [`macro/MACRO_PRINCIPLES.md`](macro/MACRO_PRINCIPLES.md) - Macro-time vs runtime
2. [`HAXE_MACRO_APIS.md`](HAXE_MACRO_APIS.md) - Correct API usage
3. [`TESTING_PRINCIPLES.md`](TESTING_PRINCIPLES.md) - Testing methodology
4. [`SOURCE_MAPPING.md`](SOURCE_MAPPING.md) - Error location mapping

### ⚡ **For Phoenix Integration**
1. [`PHOENIX_INTEGRATION.md`](PHOENIX_INTEGRATION.md) - Framework support
2. [`ROUTER_DSL.md`](ROUTER_DSL.md) - Router implementation
3. [`HXX_VS_TEMPLATE.md`](HXX_VS_TEMPLATE.md) - Template system
4. [`FRAMEWORK_CONVENTIONS.md`](FRAMEWORK_CONVENTIONS.md) - Directory structures

### 🧪 **For Testing Issues**
1. [`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md) - Complete testing guide
2. [`architecture/TESTING.md`](architecture/TESTING.md) - Test infrastructure
3. [`MACRO_TIME_TESTING_STRATEGY.md`](MACRO_TIME_TESTING_STRATEGY.md) - Macro testing
4. [`PARALLEL_TEST_ACHIEVEMENT.md`](PARALLEL_TEST_ACHIEVEMENT.md) - Parallel testing

### 📚 **For Feature Implementation**
1. Check [`reference/FEATURES.md`](reference/FEATURES.md) - Current status
2. Read relevant feature docs in main directory
3. Follow [`COMPILER_BEST_PRACTICES.md`](COMPILER_BEST_PRACTICES.md) - Development process
4. Update [`TASK_HISTORY.md`](TASK_HISTORY.md) - Document completion

---

## 📋 Quick Navigation Checklist

**Before Starting Any Task:**
- [ ] Read this index to find relevant documentation
- [ ] Check [`reference/FEATURES.md`](reference/FEATURES.md) for current status
- [ ] Review [`TASK_HISTORY.md`](TASK_HISTORY.md) for recent work
- [ ] Understand macro-time vs runtime from [`macro/MACRO_PRINCIPLES.md`](macro/MACRO_PRINCIPLES.md)

**For Compiler Development:**
- [ ] Follow [`COMPILER_BEST_PRACTICES.md`](COMPILER_BEST_PRACTICES.md)
- [ ] Test with [`TESTING_OVERVIEW.md`](TESTING_OVERVIEW.md) methodology
- [ ] Update documentation in appropriate category
- [ ] Document lessons in [`TASK_HISTORY.md`](TASK_HISTORY.md)

**For Phoenix Features:**
- [ ] Check [`PHOENIX_INTEGRATION.md`](PHOENIX_INTEGRATION.md) for patterns
- [ ] Follow [`FRAMEWORK_CONVENTIONS.md`](FRAMEWORK_CONVENTIONS.md) for structure
- [ ] Test integration with real Phoenix projects
- [ ] Update examples and guides accordingly

---

*This index is the single source of truth for documentation navigation. Keep it updated as documentation structure evolves.*