# Code Style & Conventions

## 📝 Documentation Standards

**JavaDoc-style documentation** following Haxe standard library conventions:

```haxe
/**
 * Brief description of the function's purpose
 * 
 * @param param Description of parameter
 * @return Description of return value
 */
public function exampleMethod(param: String): Bool {
    return true;
}
```

## 🎯 Code Quality Guidelines

### Haxe Code Style
- **NO comments unless asked** - Clean, self-documenting code preferred
- **Use `final` for immutable variables** - Leverage Haxe's type system
- **Prefer pattern matching** over if-else chains
- **Type annotations** - Explicit types for public APIs

### Generated Elixir Style
- **Snake_case for all files** - TodoApp.hx → todo_app.ex
- **Idiomatic patterns** - Use Map.merge, Enum.reduce, not loops
- **Proper Phoenix conventions** - Files in expected framework locations
- **Clean function signatures** - No arg0, arg1 parameter names

## 🚫 Anti-Patterns to Avoid

### Forbidden Patterns
- **Manual .ex file editing** - Everything through Haxe compilation
- **Dynamic types** except for debugging
- **String concatenation** for complex logic
- **Hardcoded file paths** - Use naming abstracts
- **Duplicate utility functions** - Centralize in helpers

### Code Smells
- **Empty function bodies** - Generate actual implementations
- **Generic parameter names** (arg0, arg1) - Extract meaningful names
- **Complex macro code** without documentation
- **Test workarounds** instead of fixing root causes

## 🔧 Development Practices

### File Organization
```
src/reflaxe/elixir/
├── ElixirCompiler.hx           # Main transpiler
├── helpers/                    # Specialized compilers
│   ├── ClassCompiler.hx        # Class compilation
│   └── EndpointCompiler.hx     # @:endpoint annotation
└── types/                      # Type abstractions
```

### Commit Conventions
- **Conventional commits**: `feat:`, `fix:`, `docs:`, `test:`
- **NO AI attribution** - Never add "Generated with Claude" 
- **Breaking changes**: Use `!` after type (e.g., `feat!:`)
- **Semantic release** handles changelog automatically