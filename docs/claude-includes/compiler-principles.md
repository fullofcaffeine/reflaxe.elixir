# Core Compiler Development Principles

## 🔄 Compilation Architecture Understanding

**CRITICAL: Reflaxe.Elixir is a macro-time transpiler**, not a runtime library. All transpilation happens during Haxe compilation, not at test runtime.

### Compilation Flow
```
Haxe Source (.hx) → Haxe Parser → TypedExpr (ModuleType) → ElixirCompiler → Elixir Code (.ex)
```

**Key Points**:
- **TypedExpr is created by Haxe**, not by our compiler
- **ElixirCompiler receives TypedExpr** as input (fully typed AST)
- **Transpilation happens at macro-time** via Context.onAfterTyping
- **No runtime component exists** - the transpiler disappears after compilation

## 🧪 Testing Requirements

**MANDATORY: Every compiler change MUST be validated through complete testing pipeline**

### After ANY Compiler Change
1. **Run Full Test Suite**: `npm test` - ALL tests must pass
2. **Test Todo-App Integration**: 
   ```bash
   cd examples/todo-app
   npx haxe build-server.hxml && mix compile --force
   ```
3. **Verify Application Runtime**: `mix phx.server && curl localhost:4000`

## ⚠️ Code Quality Standards

- **NEVER edit generated .ex files** - Fix the compiler source instead
- **Examples are compiler tests** - Failures reveal compiler bugs, not user errors
- **Type safety everywhere** - Avoid Dynamic, use abstracts for structured data
- **Idiomatic Elixir generation** - Code must look hand-written, not machine-generated

## 🔧 Development Loop Validation

**Rule**: If ANY step in validation loop fails, the development change is incomplete:
1. Snapshot tests pass
2. Mix tests pass  
3. Todo-app compiles
4. Generated Elixir syntax valid
5. Application responds correctly