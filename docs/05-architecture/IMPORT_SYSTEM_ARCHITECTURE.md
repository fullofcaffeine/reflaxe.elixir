# Import System Architecture

## Overview

Reflaxe.Elixir implements a **hybrid import system** that combines automatic import detection with explicit extern-based imports. This provides both convenience and control, allowing developers to choose between zero-friction development and type-safe APIs.

## Table of Contents
1. [The Hybrid Philosophy](#the-hybrid-philosophy)
2. [Implicit Imports (Automatic Detection)](#implicit-imports-automatic-detection)
3. [Explicit Imports (Extern-Based)](#explicit-imports-extern-based)
4. [Implementation Architecture](#implementation-architecture)
5. [When to Use Each Approach](#when-to-use-each-approach)
6. [Adding New Import Support](#adding-new-import-support)

## The Hybrid Philosophy

### Why Hybrid?

The hybrid approach balances three competing needs:
1. **Developer Convenience** - Write code without import boilerplate
2. **Type Safety** - Access to typed APIs when desired
3. **Framework Conventions** - Follow Elixir/Phoenix idioms automatically

### Core Principles

- **Framework conventions are automatic** - LiveView always gets CoreComponents
- **Language features offer choice** - Use typed externs or rely on auto-import
- **App-specific modules require explicit imports** - Your own modules must be imported
- **No magic, just smart defaults** - Predictable behavior with escape hatches

## Implicit Imports (Automatic Detection)

### How It Works

Implicit imports use **AST pattern detection** during the transformation phase to automatically add necessary imports based on code usage.

```
Haxe Source → TypedExpr → ElixirAST → [Transformation Passes] → Final AST → Elixir Code
                                              ↑
                                    Import Detection Happens Here
```

### Current Implicit Import Triggers

#### 1. Bitwise Operators → `import Bitwise`

**Detected Patterns:**
- `&&&` (bitwise AND)
- `|||` (bitwise OR)
- `^^^` (bitwise XOR)
- `<<<` (left shift)
- `>>>` (right shift)
- `~~~` (bitwise NOT)

**Example:**
```haxe
// Haxe input
class Example {
    function test() {
        var masked = value &&& 0xFF;  // Triggers import
    }
}
```

**Generated Elixir:**
```elixir
defmodule Example do
  import Bitwise  # Auto-added
  
  def test() do
    masked = value &&& 0xFF
  end
end
```

**Implementation:** `bitwiseImportPass` in `ElixirASTTransformer.hx`

#### 2. HEEx Templates → `use Phoenix.Component`

**Detected Patterns:**
- `ESigil` nodes with type "H" (generated from `HXX.hxx()` calls)

**Example:**
```haxe
// Haxe input
class MyComponent {
    function render() {
        return HXX.hxx('<div>{@name}</div>');
    }
}
```

**Generated Elixir:**
```elixir
defmodule MyComponent do
  use Phoenix.Component  # Auto-added
  
  def render(assigns) do
    ~H"""
    <div>{@name}</div>
    """
  end
end
```

**Implementation:** `phoenixComponentImportPass` in `ElixirASTTransformer.hx`

#### 3. LiveView Components → `import AppWeb.CoreComponents`

**Detected Patterns:**
- Module name contains "Live"
- ~H sigils contain component calls (`<.button`, `<.input`, etc.)

**Example:**
```haxe
@:liveview
class UserLive {
    function render() {
        return HXX.hxx('<.button>Click</.button>');
    }
}
```

**Generated Elixir:**
```elixir
defmodule TodoAppWeb.UserLive do
  use Phoenix.Component
  import TodoAppWeb.CoreComponents  # Auto-added
  
  def render(assigns) do
    ~H"""
    <.button>Click</.button>
    """
  end
end
```

**Implementation:** `liveViewCoreComponentsImportPass` in `ElixirASTTransformer.hx`

### AST Transformation Pipeline

The transformation passes run in this order:
1. Identity (pass-through base)
2. BitwiseImport (early, adds imports)
3. PhoenixComponentImport (early, adds imports)
4. LiveViewCoreComponentsImport (after Phoenix)
5. Other optimization passes...

### Detection Implementation Details

Each import pass follows this pattern:
1. **Scan Phase**: Recursively traverse AST looking for trigger patterns
2. **Decision Phase**: Determine if import is needed
3. **Injection Phase**: Add import to module if not already present

```haxe
// Simplified implementation pattern
static function someImportPass(ast: ElixirAST): ElixirAST {
    // Phase 1: Detect usage
    var needsImport = false;
    function detectUsage(node: ElixirAST): Void {
        switch(node.def) {
            case TriggerPattern:
                needsImport = true;
            default:
                iterateAST(node, detectUsage);
        }
    }
    detectUsage(ast);
    
    // Phase 2: Add import if needed
    if (!needsImport) return ast;
    
    return transformNode(ast, function(node) {
        // Inject import into module
    });
}
```

## Explicit Imports (Extern-Based)

### How It Works

Explicit imports use Haxe's standard import mechanism with specially-annotated extern classes that signal the compiler to generate Elixir imports.

### The @:autoimport Metadata

Extern classes marked with `@:autoimport` trigger import generation when imported in Haxe:

```haxe
// std/elixir/Bitwise.hx
@:native("Bitwise")
@:autoimport           // Generates: import Bitwise
extern class Bitwise {
    static function band(a: Int, b: Int): Int;
}

// std/phoenix/Component.hx
@:native("Phoenix.Component")
@:autoimport("use")    // Generates: use Phoenix.Component
extern class Component {
    // API definitions
}
```

### Usage Example

```haxe
// Explicit import with typed API
import elixir.Bitwise;

class BitwiseExample {
    static function main() {
        // Typed, IDE-friendly API
        var result = Bitwise.band(0xFF, 0x0F);  // Full intellisense
        var shifted = Bitwise.bsl(1, 8);        // Go-to definition works
    }
}
```

**Generated Elixir:**
```elixir
defmodule BitwiseExample do
  import Bitwise  # Added due to extern import
  
  def main() do
    result = 0xFF &&& 0x0F
    shifted = 1 <<< 8
  end
end
```

### Benefits of Explicit Imports

1. **Type Safety** - Full typing for all operations
2. **IDE Support** - Autocomplete, parameter hints, go-to definition
3. **Documentation** - JavaDoc on extern methods
4. **Refactoring Safety** - IDE can track usage across codebase
5. **Explicit Dependencies** - Clear what each file depends on

## Implementation Architecture

### Compiler Integration Points

#### 1. Import Detection (ElixirCompiler.hx)
```haxe
function processImports(classType: ClassType): Array<String> {
    var imports = [];
    
    for (importExpr in classType.imports) {
        var importedType = Context.getType(importExpr);
        
        switch(importedType) {
            case TInst(cl, _):
                var classRef = cl.get();
                
                // Check for @:autoimport metadata
                if (classRef.meta.has(":autoimport")) {
                    var native = extractNativeName(classRef);
                    var importType = extractImportType(classRef);
                    
                    imports.push(formatImport(importType, native));
                }
            default:
        }
    }
    
    return imports;
}
```

#### 2. Deduplication Logic

Both implicit and explicit systems check for existing imports to avoid duplicates:

```haxe
// In transformation pass
var hasImport = false;
for (stmt in statements) {
    switch(stmt.def) {
        case EImport(module, _, _):
            if (module == targetModule) {
                hasImport = true;
                break;
            }
    }
}
if (!hasImport) {
    // Add import
}
```

### Priority System

When both implicit and explicit imports could apply:
1. **Explicit imports take precedence** - Developer choice overrides automation
2. **No duplicate imports** - Deduplication prevents multiple imports
3. **Framework conventions always apply** - Can't opt out of Phoenix patterns

## When to Use Each Approach

### Use Implicit Imports When:
- Writing quick prototypes
- Following standard patterns
- Working with framework conventions
- Minimizing boilerplate

### Use Explicit Imports When:
- Need type safety and IDE support
- Working in large codebases
- Teaching or documenting code
- Using less common operations

### Framework-Specific Guidelines

| Feature | Implicit | Explicit | Recommendation |
|---------|----------|----------|----------------|
| Bitwise operations | ✅ Automatic | ✅ Available | Use explicit for complex bit manipulation |
| Phoenix.Component | ✅ Automatic | ✅ Available | Implicit usually sufficient |
| CoreComponents | ✅ Automatic | ❌ N/A | Always automatic in LiveView |
| Custom modules | ❌ N/A | ✅ Required | Must explicitly import |

## Adding New Import Support

### Adding Implicit Import Support

1. **Create transformation pass** in `ElixirASTTransformer.hx`:
```haxe
static function myFeatureImportPass(ast: ElixirAST): ElixirAST {
    // Detection and injection logic
}
```

2. **Register the pass** in `getEnabledPasses()`:
```haxe
passes.push({
    name: "MyFeatureImport",
    description: "Add import for MyFeature",
    enabled: true,
    pass: myFeatureImportPass
});
```

3. **Test the detection** with snapshot tests

### Adding Explicit Import Support

1. **Create extern** in appropriate std directory:
```haxe
@:native("ElixirModule")
@:autoimport
extern class MyFeature {
    // Typed API
}
```

2. **Ensure compiler processes imports** (already implemented for @:autoimport)

3. **Document the API** with JavaDoc

4. **Test both implicit and explicit** work together

## Testing Strategy

### Test Categories

1. **Implicit Import Tests** (`test/tests/ImplicitImports/`)
   - Verify automatic detection works
   - Test all trigger patterns
   - Ensure no unnecessary imports

2. **Explicit Import Tests** (`test/tests/ExplicitImports/`)
   - Verify extern imports work
   - Test typed API compilation
   - Check IDE features (manual testing)

3. **Hybrid Import Tests** (`test/tests/HybridImports/`)
   - Test both systems together
   - Verify no conflicts
   - Test precedence rules

### Test Verification

```bash
# Run import-related tests
make test-ImplicitImports
make test-ExplicitImports
make test-HybridImports

# Update expected output after changes
make update-intended TEST=ImplicitImports
```

## Future Enhancements

### Planned Features
1. **Import optimization** - Remove unused imports
2. **Import grouping** - Organize imports by type
3. **Conditional imports** - Based on compile flags
4. **Import aliases** - Support `import X, as: Y`

### Potential Implicit Imports
- `Logger` for logging operations
- `Jason` for JSON operations
- `Process` for process operations
- `GenServer` for OTP patterns

### Potential Explicit Externs
- Complete Elixir standard library
- Popular hex packages (Ecto, Phoenix, etc.)
- OTP behaviors
- Testing frameworks

## Design Decisions and Rationale

### Why AST Transformation for Implicit?
- **Accurate detection** - Not fooled by strings or comments
- **Composable passes** - Easy to add/remove/reorder
- **Testable** - Each pass can be tested independently
- **Performance** - Single pass through AST

### Why @:autoimport for Explicit?
- **Follows Haxe conventions** - Uses standard import mechanism
- **Metadata-driven** - Flexible and extensible
- **Clean separation** - Import logic separate from API definition
- **IDE-friendly** - Standard imports work with all tools

### Why Hybrid Instead of One Approach?
- **Best of both worlds** - Convenience AND control
- **Progressive disclosure** - Start simple, add types as needed
- **Framework alignment** - Matches Elixir/Phoenix philosophy
- **Future-proof** - Can evolve each system independently

## Summary

The hybrid import system provides:
- ✅ **Zero-friction development** with implicit imports
- ✅ **Type-safe APIs** with explicit externs
- ✅ **Framework conventions** automatically applied
- ✅ **Clear mental model** for developers
- ✅ **Extensible architecture** for future needs

This design allows Reflaxe.Elixir to feel natural to both Haxe developers (familiar imports) and Elixir developers (automatic conventions) while providing maximum flexibility for different use cases and project sizes.