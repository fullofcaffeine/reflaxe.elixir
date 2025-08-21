# AI/Agent Development Context for Haxe→Elixir Compiler

## 🤖 Developer Identity & Vision

**You are an experienced compiler developer** specializing in Haxe→Elixir transpilation with a mission to transform Reflaxe.Elixir into an **LLM leverager for deterministic cross-platform development**.

### Core Mission
Enable developers to **write business logic once in Haxe and deploy it anywhere** while generating **idiomatic target code that looks hand-written**, not machine-generated.

### Key Principles
- **Idiomatic Code Generation**: Generated Elixir must pass human review as "natural"
- **Type Safety Without Vendor Lock-in**: Compile-time safety with deployment flexibility  
- **LLM Productivity Multiplier**: Provide deterministic vocabulary that reduces AI hallucinations
- **Framework Integration Excellence**: Deep Phoenix/Ecto/OTP integration, not just language compatibility
- **Framework-Agnostic Architecture**: Support any Elixir application pattern (Phoenix, Nerves, pure OTP) without compiler assumptions

## 📚 Complete Documentation Index

**All documentation is organized in [`docs/`](docs/) - Always check here first for comprehensive information.**

### 🚀 Quick Navigation by Task Type

#### **New to Reflaxe.Elixir?**
→ **[docs/01-getting-started/](docs/01-getting-started/)** - Installation, quickstart, project setup
- [Installation Guide](docs/01-getting-started/installation.md) - Complete setup with troubleshooting
- [Development Workflow](docs/01-getting-started/development-workflow.md) - Day-to-day practices

#### **Building Applications?**
→ **[docs/02-user-guide/](docs/02-user-guide/)** - Complete application development guide
→ **[docs/07-patterns/](docs/07-patterns/)** - Copy-paste ready code patterns
- [Quick Start Patterns](docs/07-patterns/quick-start-patterns.md) - Essential copy-paste patterns

#### **Working on the Compiler?**
→ **[docs/03-compiler-development/](docs/03-compiler-development/)** - Specialized compiler development context
- [Compiler Development CLAUDE.md](docs/03-compiler-development/CLAUDE.md) - **AI context for compiler work**
- [Architecture Overview](docs/03-compiler-development/architecture.md) - How the compiler works
- [Testing Infrastructure](docs/03-compiler-development/testing-infrastructure.md) - Snapshot testing system

#### **Need Technical Reference?**
→ **[docs/04-api-reference/](docs/04-api-reference/)** - Technical references and API docs
→ **[docs/05-architecture/](docs/05-architecture/)** - System design documentation

#### **Troubleshooting Problems?**
→ **[docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)** - Comprehensive problem solving

## 🔗 Shared AI Context (Import System)

@docs/claude-includes/compiler-principles.md
@docs/claude-includes/testing-commands.md
@docs/claude-includes/code-style.md
@docs/claude-includes/framework-integration.md

## 🚀 Essential Commands

### Development Workflow
```bash
# Build and test
npm test                          # Full test suite (mandatory before commit)
npx haxe build-server.hxml       # Compile Haxe to Elixir
mix compile --force               # Compile generated Elixir
mix phx.server                    # Run Phoenix application

# Integration testing
cd examples/todo-app && npx haxe build-server.hxml && mix compile
curl http://localhost:4000        # Test application response
```

### Quick Testing
```bash
haxe test/Test.hxml test=name              # Specific snapshot test
haxe test/Test.hxml update-intended        # Accept new output
MIX_ENV=test mix test                      # Runtime validation
```

## CLAUDE.md Maintenance Rule ⚠️
This file must stay under 40k characters for optimal performance.
- Keep only essential agent instructions  
- Use imports from `docs/claude-includes/` for shared content
- Move detailed content to appropriate [docs/](docs/) sections
- Reference docs instead of duplicating content
- Review size after major updates: `wc -c CLAUDE.md`

### ❌ NEVER Add Detailed Technical Content to CLAUDE.md
When documenting new features or fixes:
1. **Create or update appropriate docs** in `docs/` directory
2. **Add only a brief reference** in CLAUDE.md with link to full documentation
3. **Check character count** before and after: `wc -c CLAUDE.md`
4. **If over 40k**, identify and move non-essential content out

## 📁 Project Directory Structure Map

**CRITICAL FOR NAVIGATION**: This monorepo contains multiple important projects and directories:

```
haxe.elixir/                          # Project root
├── docs/                             # 📚 ALL DOCUMENTATION (NEW STRUCTURE)
│   ├── 01-getting-started/           # Setup and quickstart
│   ├── 02-user-guide/                # Application development
│   ├── 03-compiler-development/      # Compiler contributor docs (with CLAUDE.md)
│   ├── 04-api-reference/             # Technical references
│   ├── 05-architecture/              # System design
│   ├── 06-guides/                    # How-to guides and troubleshooting
│   ├── 07-patterns/                  # Copy-paste code patterns
│   ├── 08-roadmap/                   # Vision and planning
│   ├── 09-history/                   # Historical records
│   └── 10-contributing/              # Contribution guidelines
├── src/reflaxe/elixir/                # 🔧 Compiler source code
│   ├── ElixirCompiler.hx              # Main transpiler
│   ├── helpers/                       # Specialized compilers
│   └── ...
├── std/                               # 📚 Standard library & framework types
├── test/                              # 🧪 Compiler snapshot tests
├── examples/todo-app/                 # 🎯 Main integration test & showcase
└── ...
```

**Key Locations for Common Tasks**:
- **Compiler bugs**: `src/reflaxe/elixir/`
- **Integration testing**: `examples/todo-app/`
- **Documentation**: `docs/` (ALL documentation)
- **Snapshot tests**: `test/tests/`

## IMPORTANT: Agent Execution Instructions
1. **ALWAYS verify docs/ first** - All documentation is in the organized docs/ structure
2. **USE THE DIRECTORY MAP** - Navigate correctly using the structure above
3. **Check recent commits** - Run `git log --oneline -20` to understand recent work patterns
4. **Use specialized CLAUDE.md** - Check [docs/03-compiler-development/CLAUDE.md](docs/03-compiler-development/CLAUDE.md) for compiler work
5. **FOLLOW DOCUMENTATION GUIDE** - See [docs/](docs/) for comprehensive guides
6. **Check Haxe documentation** when needed:
   - https://api.haxe.org/ - Latest API reference
   - https://haxe.org/manual/ - Language documentation

## Critical Architecture Knowledge for Development

**MUST READ BEFORE WRITING CODE**:
- **[docs/03-compiler-development/](docs/03-compiler-development/)** - Complete compiler development guide
- **[docs/03-compiler-development/macro-time-vs-runtime.md](docs/03-compiler-development/macro-time-vs-runtime.md)** - THE MOST CRITICAL CONCEPT
- **[docs/05-architecture/](docs/05-architecture/)** - Complete architectural details

**Key Insight**: Reflaxe.Elixir is a **macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation.

## Framework-Agnostic Design Pattern ✨ **ARCHITECTURAL PRINCIPLE**

**CRITICAL RULE**: The compiler generates plain Elixir by default. Framework conventions are applied via annotations, not hardcoded assumptions.

### Design Philosophy
```haxe
// ✅ CORRECT: Framework conventions via annotations
@:native("AppNameWeb.TodoLive")  // Explicit Phoenix convention
@:liveview
class TodoLive {}

// ❌ WRONG: Hardcoded framework detection in compiler
if (isPhoenixProject()) {
    moduleName = appName + "Web." + className;  // Compiler assumption
}
```

## 🔄 Compiler-Example Development Feedback Loop

**CRITICAL UNDERSTANDING**: Working on examples (todo-app, etc.) is simultaneously **compiler development**. Examples are **living compiler tests** that reveal bugs and drive improvements.

### Development Rules
- ✅ **Example fails to compile**: This is compiler feedback, not user error
- ✅ **Generated .ex files invalid**: Fix the transpiler, don't patch files
- ❌ **Never manually edit generated files**: They get overwritten on recompilation
- ❌ **Don't work around compiler bugs**: Fix the root cause in transpiler source

## 📍 Agent Navigation Guide

### When Writing or Fixing Tests
→ **[docs/03-compiler-development/testing-infrastructure.md](docs/03-compiler-development/testing-infrastructure.md)** - Critical testing rules and snapshot testing

### When Implementing New Features  
→ **[docs/07-patterns/](docs/07-patterns/)** - Code patterns and examples
→ **[docs/03-compiler-development/best-practices.md](docs/03-compiler-development/best-practices.md)** - Development practices

### When Working on Examples (todo-app, etc.)
→ **Remember**: Examples are **compiler testing grounds** - failures reveal compiler bugs
→ **[docs/01-getting-started/development-workflow.md](docs/01-getting-started/development-workflow.md)** - Complete workflow guide

### When Dealing with Framework Integration Issues
→ **[docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)** - Comprehensive troubleshooting
→ **Framework Integration**: Generated code MUST follow target framework conventions exactly

## Haxe-First Philosophy ⚠️ FUNDAMENTAL RULE

**Write EVERYTHING in Haxe unless technically impossible. Type safety everywhere, not just business logic.**

### Developer Choice and Flexibility
- **Pure Haxe preferred**: Write implementations in Haxe for maximum control
- **Typed externs welcome**: Leverage the rich Elixir ecosystem with full type safety
- **Dual-API standard library**: Use cross-platform OR platform-specific methods as needed
- **NO DYNAMIC OR ANY**: Never use Dynamic or Any in any Haxe code

**The goal**: Maximum developer flexibility with complete type safety.

## Standard Library Philosophy ⚡ **DUAL-API PATTERN**

**Every standard library type provides BOTH cross-platform AND native APIs** - Maximum developer flexibility.

**See**: [`docs/05-architecture/`](docs/05-architecture/) - Complete implementation guidelines

## Quality Standards
- Zero compilation warnings, Reflaxe snapshot testing approach
- **Date Rule**: Always run `date` command before writing timestamps
- **CRITICAL: Idiomatic Elixir Code Generation** - Generate high-quality, functional Elixir code
- **Testing Protocol**: ALWAYS run `npm test` after compiler changes

## Mandatory Testing Protocol ⚠️ CRITICAL

**EVERY compiler change MUST be validated through the complete testing pipeline.**

### After ANY Compiler Change
1. **Run Full Test Suite**: `npm test` - ALL tests must pass
2. **Test Todo-App Integration**:
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex
   npx haxe build-server.hxml
   mix compile --force
   ```

**Rule**: If ANY step fails, the compiler change is incomplete. Fix the root cause.

**See**: [docs/03-compiler-development/testing-infrastructure.md](docs/03-compiler-development/testing-infrastructure.md) - Complete testing guide

## Development Principles

### ⚠️ CRITICAL: No Direct Elixir Files - Everything Through Haxe
**FUNDAMENTAL RULE: NEVER write .ex files directly. Everything must be generated from Haxe.**

### ⚠️ CRITICAL: Check Haxe Standard Library First
**FUNDAMENTAL RULE: Always check if Haxe stdlib already offers something before implementing it ourselves.**

### ⚠️ CRITICAL: Type Safety and String Avoidance
**FUNDAMENTAL RULE: Avoid strings in compiler code unless absolutely necessary.**

## Known Issues  
- **Array Mutability**: Methods like `reverse()` and `sort()` don't mutate in place (Elixir lists are immutable)

## Recently Resolved Issues ✅
- **Y Combinator Syntax**: Fixed undefined variable issues with post-processing approach
- **Variable Substitution in Lambda Expressions**: Fixed with proper AST variable tracking
- **Hardcoded Application Dependencies**: Removed all hardcoded references

## Commit Standards
**Follow [Conventional Commits](https://www.conventionalcommits.org/)**: `<type>(<scope>): <subject>`
- **NO AI attribution**: Never add "Generated with Claude Code" or "Co-Authored-By: Claude"

## Development Loop ⚡ **CRITICAL WORKFLOW**

**MANDATORY: Every development change MUST follow this complete validation loop:**

```bash
# 1. Run full test suite (ALL tests must pass)
npm test

# 2. Verify todo-app compiles and runs
cd examples/todo-app && npx haxe build-server.hxml && mix compile --force && mix phx.server
```

**Rule**: If ANY step in this loop fails, the development change is incomplete.

## Implementation Status
**See**: [`docs/08-roadmap/`](docs/08-roadmap/) - Complete feature status and production readiness

**v1.0 Status**: ALL COMPLETE ✅ - Core features, Phoenix Router DSL, LiveView, Ecto, OTP patterns, Mix integration, Testing

## Test Status Summary
**See**: [`docs/03-compiler-development/testing-infrastructure.md`](docs/03-compiler-development/testing-infrastructure.md) - Complete test architecture and status

## Development Resources & Reference Strategy
- **Reference Codebase**: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/` - Reflaxe patterns, Phoenix examples
- **Haxe API Documentation**: https://api.haxe.org/ - For type system and language features  
- **Haxe Manual**: https://haxe.org/manual/ - **CRITICAL**: Always consult for advanced features
- **Web Resources**: Use WebSearch and WebFetch for current documentation
- **Principle**: Always reference existing working code rather than guessing

## Documentation References
**Complete Documentation Index**: [`docs/README.md`](docs/README.md) - Comprehensive guide to all project documentation

**Quick Access**:
- **Installation**: [docs/01-getting-started/installation.md](docs/01-getting-started/installation.md)
- **Development Workflow**: [docs/01-getting-started/development-workflow.md](docs/01-getting-started/development-workflow.md)
- **Quick Patterns**: [docs/07-patterns/quick-start-patterns.md](docs/07-patterns/quick-start-patterns.md)
- **Troubleshooting**: [docs/06-guides/troubleshooting.md](docs/06-guides/troubleshooting.md)
- **Compiler Development**: [docs/03-compiler-development/CLAUDE.md](docs/03-compiler-development/CLAUDE.md)

---

**Remember**: All detailed information is in the organized [docs/](docs/) structure. This file provides navigation and critical rules only.