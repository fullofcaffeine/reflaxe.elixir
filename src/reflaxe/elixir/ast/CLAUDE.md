# AST Development Context for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) and [/src/reflaxe/elixir/CLAUDE.md](/src/reflaxe/elixir/CLAUDE.md) for project-wide conventions

This file contains AST-specific development guidance for agents working on the Reflaxe.Elixir AST transformation pipeline.

## 🚨 CRITICAL: ElixirASTBuilder.hx Size Crisis - EXTRACT AND REFACTOR

### ⚠️ RULE: MODIFY BUT EXTRACT - Keep ElixirASTBuilder.hx Maintainable

**CURRENT SIZE**: 11,137 lines (as of January 2025)
**VIOLATION LEVEL**: 10x larger than recommended maximum (1,000 lines)
**STATUS**: EMERGENCY - Needs aggressive refactoring while fixing issues

### The Directive

**When modifying ElixirASTBuilder.hx, you MUST follow SOLID principles:**

- ✅ **FIX issues directly** - Don't work around bugs in other files
- ✅ **EXTRACT while fixing** - Move related code to specialized builders
- ✅ **REFACTOR as you go** - Improve structure, don't just add code
- ❌ **NO net increase in size** - Every fix should extract more than it adds
- ❌ **NO quick patches** - Fix properly and refactor simultaneously
- ❌ **NO monolithic additions** - Large features go to specialized modules

### Where New Code MUST Go Instead

All new AST-related functionality MUST be placed in:

1. **Specialized Builders** (`src/reflaxe/elixir/ast/builders/`)
   - Create new builder classes for specific AST node types
   - Example: `LoopBuilder.hx`, `PatternMatchBuilder.hx`

2. **Transformation Passes** (`src/reflaxe/elixir/ast/transformers/`)
   - Add new transformation passes to `ElixirASTTransformer.hx`
   - Create specialized transformers like `AnnotationTransforms.hx`

3. **Helper Classes** (`src/reflaxe/elixir/helpers/`)
   - Extract utility functions to dedicated helper classes
   - Example: `VariableCompiler.hx`, `PatternMatchingCompiler.hx`

### Historical Context

**Failed Modularization Attempt (Commit ecf50d9d - September 2025)**
- An attempt was made to extract ElixirASTBuilder into modular builders
- Multiple builder files were created then deleted:
  - `ModuleBuilder.hx` (1,492 lines)
  - `LoopBuilder.hx` (448 lines)
  - `PatternMatchBuilder.hx` (388 lines)
  - `ArrayBuilder.hx` (386 lines)
  - `ControlFlowBuilder.hx` (375 lines)
  - `ExUnitCompiler.hx` (345 lines)
  - `CallExprBuilder.hx` (322 lines - later re-added)
  - `ClassBuilder.hx` (451 lines)
- The refactoring was incomplete and abandoned
- Critical functionality (like @:application handling) was lost in the process
- **LESSON**: Modularization must be done incrementally with full testing at each step

### Why This Rule Exists

1. **Unmaintainable Size**: At 11,137 lines, the file is impossible to navigate or understand
2. **Single Responsibility Violation**: The file does EVERYTHING - a complete violation of SRP
3. **Performance Impact**: Compilation is slower due to massive file size
4. **Bug Breeding Ground**: Finding and fixing bugs in 11k lines is nearly impossible
5. **Merge Conflicts**: Every change conflicts with other changes in such a large file
6. **Testing Nightmare**: Cannot unit test a monolithic file effectively

### The Refactoring Plan

**Phase 1: Stop the Bleeding** (CURRENT)
- Enforce absolute prohibition on additions
- All new features go to specialized modules

**Phase 2: Incremental Extraction** (FUTURE)
- Extract logical sections one at a time
- Each extraction must maintain full test suite passing
- Target: Reduce to under 2,000 lines

**Phase 3: Final Architecture** (GOAL)
- ElixirASTBuilder becomes a thin orchestrator
- All logic in specialized, testable modules
- Each module under 500 lines

### Enforcement

**If you're about to add code to ElixirASTBuilder.hx:**

1. **STOP** - Do not add the code
2. **IDENTIFY** - What type of functionality is it?
3. **CREATE** - Make a new specialized builder or transformer
4. **INTEGRATE** - Call your new module from the appropriate place
5. **TEST** - Ensure full test suite passes

**NO EXCEPTIONS** - Not even for "critical fixes" or "temporary solutions"

### Verification Checklist

Before ANY commit:
- [ ] ElixirASTBuilder.hx line count has NOT increased
- [ ] New functionality is in a specialized module
- [ ] All tests pass
- [ ] No "TODO: extract later" comments

## 🏗️ AST Pipeline Architecture

The AST pipeline is the core of the Reflaxe.Elixir compiler, transforming Haxe's TypedExpr into idiomatic Elixir code through three phases:

1. **Builder Phase** (`ElixirASTBuilder.hx`) - Converts TypedExpr → ElixirAST
2. **Transformer Phase** (`ElixirASTTransformer.hx`) - Applies idiomatic transformations
3. **Printer Phase** (`ElixirASTPrinter.hx`) - Generates final Elixir strings

---

**Remember**: Every line added to ElixirASTBuilder.hx makes the compiler harder to maintain, debug, and extend. The prohibition is absolute and non-negotiable.