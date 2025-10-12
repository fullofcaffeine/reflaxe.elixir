# Vendor Directory Context for Reflaxe.Elixir

> **Parent Context**: See [/AGENTS.md](/AGENTS.md) for project-wide conventions

## 📦 Vendored Dependencies

This directory contains vendored dependencies for the Reflaxe.Elixir compiler.

### vendor/reflaxe/

**Purpose**: Core Reflaxe framework - the foundation for all Reflaxe-based compilers

**Source**: https://github.com/SomeRanDev/reflaxe

**Why Vendored**:
- Allows modifications for Elixir-specific requirements
- Ensures compiler stability with known Reflaxe version
- Enables custom fixes without waiting for upstream PRs

### vendor/genes/

**Purpose**: Modern ES6 JavaScript generator for full-stack development

**Source**: https://github.com/fullofcaffeine/genes

**Why Vendored**:
- Modified to support async/await patterns for Phoenix LiveView hooks
- Enables full-stack Haxe development (Elixir backend + JavaScript frontend)
- Custom AsyncMacro integration for clean async function generation

## ⚠️ CRITICAL: Reflaxe Source Modification Policy

**DIRECTIVE**: You CAN modify vendored Reflaxe source IF NEEDED, but as a **LAST RESORT**.

### When to Modify Reflaxe Source

**✅ ACCEPTABLE Reasons**:
1. **Bug fixes** that block compiler functionality and have no workaround
2. **Critical features** needed for Elixir idioms that can't be achieved via extension
3. **Performance issues** that can only be fixed at the Reflaxe level
4. **Integration problems** where Reflaxe's architecture doesn't fit Elixir's needs

**❌ AVOID Modifying** when you can:
1. **Extend via inheritance** - Override methods in ElixirCompiler
2. **Use AST transformations** - Handle in ElixirASTTransformer passes
3. **Apply compiler-level fixes** - Fix in ElixirASTBuilder or other compiler modules
4. **Work around via metadata** - Use metadata flags to control behavior

### The Decision Flow

```
Issue with Reflaxe behavior
         ↓
Can I fix it in ElixirCompiler? → YES → Fix in ElixirCompiler
         ↓ NO
Can I fix it in AST pipeline? → YES → Fix in ElixirASTBuilder/Transformer
         ↓ NO
Can I work around with metadata? → YES → Use metadata flags
         ↓ NO
Is this a fundamental architectural issue? → YES → Consider modifying Reflaxe
         ↓
Document WHY Reflaxe modification is necessary
Write comprehensive comment in modified code
Consider upstream PR to Reflaxe project
```

### Documentation Requirements for Reflaxe Modifications

**MANDATORY**: Every Reflaxe source modification MUST include:

1. **File header comment** explaining the modification:
   ```haxe
   // ⚠️ REFLAXE SOURCE MODIFIED FOR ELIXIR COMPILER
   //
   // MODIFICATION: Brief description (e.g., "Added async/await detection")
   // WHY: Explanation of why this couldn't be fixed in ElixirCompiler
   // DATE: YYYY-MM-DD
   // AUTHOR: Your name
   // UPSTREAM: Link to upstream issue/PR if applicable
   ```

2. **Inline comments** at modification sites:
   ```haxe
   // BEGIN ELIXIR-SPECIFIC MODIFICATION
   // This handles Elixir's string interpolation requirements
   if (insideString) {
       finalCode += '#{$argStr}';
   }
   // END ELIXIR-SPECIFIC MODIFICATION
   ```

3. **Changelog entry** in vendor/CHANGELOG.md documenting:
   - What was changed
   - Why it was necessary
   - Impact on Elixir compiler functionality
   - Date of modification

### Historical Modifications (Examples)

**Example 1: genes AsyncMacro** (January 2025)
- **File**: `vendor/genes/src/genes/AsyncMacro.hx`
- **Modification**: Added `__async_marker__` pattern detection for native async functions
- **Why**: Default genes didn't support async/await needed for Phoenix LiveView hooks
- **Result**: Clean ES6 async/await generation for client-side JavaScript

**Example 2: Reflaxe TargetCodeInjection** (Considered but not needed - January 2025)
- **File**: `vendor/reflaxe/src/reflaxe/compiler/TargetCodeInjection.hx`
- **Issue**: __elixir__() calls not generating proper string interpolation
- **Resolution**: Fixed in CallExprBuilder.hx instead - did NOT need Reflaxe modification
- **Lesson**: Always try compiler-level fixes first

### Upstream Contribution Guidelines

When modifying Reflaxe source:

1. **Consider upstream value**: Could other Reflaxe compilers benefit from this change?
2. **Create issue**: Open issue in Reflaxe repository describing the problem
3. **Submit PR**: If modification is generally useful, submit PR to upstream
4. **Document in vendor/**: Even if PR is pending, document the modification locally

**Benefits of Upstream Contribution**:
- Other Reflaxe compilers benefit from improvements
- Reduces maintenance burden on our fork
- Community review improves code quality
- Ensures compatibility with future Reflaxe versions

### Version Management

**Current Reflaxe Version**: Check `vendor/reflaxe/haxelib.json` for version info

**Updating Reflaxe**:
1. Document current modifications in vendor/CHANGELOG.md
2. Pull latest upstream Reflaxe
3. Re-apply necessary modifications
4. Test full compiler test suite
5. Update version documentation

**When to Update**:
- New Reflaxe features needed for Elixir compiler
- Bug fixes in upstream Reflaxe
- Security updates
- Performance improvements

### Migration Strategy

**Long-term Goal**: Minimize Reflaxe modifications over time

**Approach**:
1. **Identify modification patterns** - What types of changes do we keep making?
2. **Propose Reflaxe extensions** - Can Reflaxe add hooks/callbacks for our needs?
3. **Contribute to Reflaxe** - Make Reflaxe more extensible for all compilers
4. **Reduce fork divergence** - Aim for zero local Reflaxe modifications eventually

## 🔧 Vendor Update Process

### Updating genes

```bash
# 1. Check current version
cat vendor/genes/haxelib.json

# 2. Pull latest from upstream
cd vendor/genes
git pull origin main

# 3. Test full-stack compilation
cd ../../examples/todo-app
npx haxe build-client.hxml  # JavaScript generation

# 4. Verify no regressions
npm run test:full-stack
```

### Updating Reflaxe

```bash
# 1. Document current state
cat vendor/CHANGELOG.md

# 2. Pull latest Reflaxe
cd vendor/reflaxe
git pull origin main

# 3. Re-apply modifications (if any)
# Check vendor/CHANGELOG.md for list of modifications

# 4. Test compiler
cd ../../
npm test

# 5. Test integration
cd examples/todo-app && mix compile --force
```

## 📚 Related Documentation

- [Reflaxe Framework Documentation](https://github.com/SomeRanDev/reflaxe)
- [genes JavaScript Generator](https://github.com/fullofcaffeine/genes)
- [Contributing to Reflaxe](https://github.com/SomeRanDev/reflaxe/blob/main/CONTRIBUTING.md)

---

**Remember**: Vendor modifications are technical debt. The goal is to minimize them over time through upstream contributions and better compiler architecture.