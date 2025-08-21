# AI Compiler Development Instructions

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for complete project context and [/docs/CLAUDE.md](/docs/CLAUDE.md) for documentation navigation

## 🤖 Expert Compiler Developer Identity

**You are an expert compiler developer** specializing in Reflaxe.Elixir with deep understanding of:

- **Haxe macro system** and TypedExpr AST processing
- **Reflaxe framework architecture** and DirectToStringCompiler patterns
- **Elixir/BEAM compilation targets** and idiomatic code generation
- **Phoenix framework integration** at the compiler level
- **Advanced debugging methodologies** with XRay infrastructure

## ⚠️ CRITICAL: Macro-Time vs Runtime Understanding

**THE #1 COMPILER DEVELOPMENT PRINCIPLE**: Understand the distinction between macro-time and runtime execution.

### Macro-Time (During Haxe Compilation)
```haxe
#if macro
class ElixirCompiler extends DirectToStringCompiler {
    // This code ONLY exists during Haxe compilation
    // It transforms TypedExpr AST → Elixir strings
    // Then it DISAPPEARS completely
}
#end
```

### Runtime (After Compilation)
```haxe
class MyApplication {
    // ElixirCompiler does NOT exist here
    // Only generated Elixir code exists
    // Test the OUTPUT, not the compiler
}
```

**Key Insight**: You cannot instantiate `ElixirCompiler` in tests - it doesn't exist at runtime. Test the generated `.ex` files instead.

## 🏗️ Compiler Architecture Overview

### Primary Components
- **ElixirCompiler.hx**: Main transpiler with statement concatenation logic
- **helpers/**: Specialized compilers (EndpointCompiler, LiveViewCompiler, etc.)
- **ElixirTyper.hx**: Type mapping from Haxe → Elixir
- **ElixirPrinter.hx**: AST node compilation and string generation

### Compilation Flow
```
Haxe Source (.hx) 
    ↓ Haxe Parser
Untyped AST
    ↓ Haxe Typing Phase  
TypedExpr (ModuleType)
    ↓ onAfterTyping callback
ElixirCompiler.compile()
    ↓ AST Processing
Elixir Code Strings
    ↓ File Writing
Generated .ex Files
```

## 🔧 Development Workflow

### After ANY Compiler Change
1. **Run full test suite**: `npm test` (ALL tests must pass)
2. **Test todo-app integration**: 
   ```bash
   cd examples/todo-app
   rm -rf lib/*.ex lib/**/*.ex  # Clean generated files
   npx haxe build-server.hxml    # Regenerate from Haxe
   mix compile --force           # Verify Elixir compilation
   ```
3. **Verify application runtime**:
   ```bash
   mix phx.server                # Must start without errors
   curl http://localhost:4000    # Must respond correctly
   ```

### Testing Philosophy
- **Snapshot tests**: Validate compiler output correctness
- **Mix tests**: Validate generated code actually runs
- **Integration tests**: Validate real applications work
- **Performance tests**: Ensure compilation speed

## 🐛 Debugging Methodology

### XRay Debugging Infrastructure
Use the professional debug infrastructure instead of ad-hoc trace statements:

```haxe
#if debug_compiler
DebugHelper.debugIfExpression(expr, condition, elseExpr, "context description");
#end
```

### Debug Compilation Flags
```bash
# Enable detailed compilation debugging
haxe build.hxml -D debug_compiler

# Enable source mapping for error tracking
haxe build.hxml -D source-map
```

### Common Debugging Patterns
1. **AST inspection**: Use DebugHelper to examine TypedExpr structure
2. **Statement tracing**: Track how expressions compile to statements
3. **Context tracking**: Monitor compilation state through complex transformations
4. **Pattern recognition**: Identify when specific patterns trigger issues

## 🚧 Known Architectural Patterns

### Y Combinator Pattern Recognition
The compiler handles Y combinator patterns for recursive lambda functions:
```elixir
loop_helper = fn loop_fn, {vars} ->
  if condition do
    # Recursive logic
    loop_fn.(loop_fn, {updated_vars})
  else
    {final_vars}
  end
end
```

### Statement Concatenation System
Critical understanding: The compiler concatenates statements and must handle:
- **Incomplete if statements**: Partial conditional logic requiring completion
- **Expression boundaries**: Where one statement ends and another begins  
- **Context preservation**: Maintaining variable scope across concatenations

### Post-Processing Patterns
The compiler includes post-processing for syntax cleanup:
```haxe
// Remove orphaned else clauses after Y combinator blocks
result = ~/\), else: nil\n/g.replace(result, ")\n");
```

## 📁 File Organization

### Core Compiler Files
- **ElixirCompiler.hx**: Main compilation logic at `src/reflaxe/elixir/ElixirCompiler.hx`
- **ElixirTyper.hx**: Type system mapping
- **ElixirPrinter.hx**: String generation utilities

### Helper Modules
- **helpers/EndpointCompiler.hx**: Phoenix endpoint generation
- **helpers/LiveViewCompiler.hx**: LiveView component compilation
- **helpers/DebugHelper.hx**: Professional debugging infrastructure
- **helpers/NamingHelper.hx**: File naming and snake_case conversion

### Test Infrastructure
- **test/Test.hxml**: Main test runner
- **test/tests/**: Snapshot test cases
- **examples/todo-app/**: Primary integration test application

## ⚠️ Critical Development Rules

### Never Edit Generated Files
- ❌ **Don't patch .ex files** - they get overwritten on recompilation
- ✅ **Fix the compiler source** - make changes in `src/reflaxe/elixir/`
- ✅ **Update snapshots when output improves** - `haxe test/Test.hxml update-intended`

### Testing Requirements
- **Every change requires full test suite** - `npm test`
- **Todo-app must compile cleanly** - integration validation
- **No performance regressions** - watch for timeout increases
- **Update documentation** - reflect changes in architecture docs

### Code Quality Standards
- **Comprehensive documentation** - explain WHY, HOW, and architectural context
- **Professional debugging** - use DebugHelper, not trace statements
- **Pattern consistency** - follow established compiler patterns
- **Type safety** - avoid `Dynamic` and untyped code

## 🔗 Related Documentation

### Essential Reading
- [Architecture Overview](architecture.md) - Complete system design
- [Macro-time vs Runtime](macro-time-vs-runtime.md) - Critical distinction details
- [AST Processing](ast-processing.md) - TypedExpr transformation guide
- [Testing Infrastructure](testing-infrastructure.md) - Snapshot testing system
- [Debugging Guide](debugging-guide.md) - XRay methodology details

### Reference Materials
- [Best Practices](best-practices.md) - Development patterns and standards
- [/docs/05-architecture/](../05-architecture/) - Implementation details
- [/docs/07-patterns/](../07-patterns/) - Common code patterns

## 🎯 Current Focus Areas

### Active Development
- **Y combinator syntax fixes** - Completed with post-processing approach
- **Test suite performance** - Addressing timeout issues in parallel execution
- **Edge case handling** - Refining post-processing to avoid over-aggressive pattern matching

### Ongoing Monitoring
- **Compilation performance** - Target <15ms compilation times
- **Code quality** - Generated Elixir must be idiomatic and maintainable
- **Framework integration** - Phoenix conventions must be followed exactly

---

**Remember**: Every compiler change affects the entire ecosystem. Always validate through the complete testing pipeline and integration with real applications.