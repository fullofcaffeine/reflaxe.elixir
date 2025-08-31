# Import System Architecture

## Overview

Reflaxe.Elixir implements a **hybrid import system** that combines automatic import detection for language features with optional extern-based imports for library functions. This provides both seamless language integration and typed library access.

## Table of Contents
1. [The Hybrid Philosophy](#the-hybrid-philosophy)
2. [Implicit Imports (Automatic Detection)](#implicit-imports-automatic-detection)
3. [Explicit Imports (Extern-Based)](#explicit-imports-extern-based)
4. [Implementation Architecture](#implementation-architecture)
5. [When to Use Each Approach](#when-to-use-each-approach)
6. [Adding New Import Support](#adding-new-import-support)

## The Hybrid Philosophy

### Why Hybrid?

The hybrid approach serves two distinct purposes:
1. **Language Integration** - Native language features work transparently
2. **Library Access** - Typed APIs for Elixir libraries when needed
3. **Framework Conventions** - Phoenix/LiveView patterns apply automatically

### Core Principles

- **Language features are always implicit** - Bitwise ops, pattern matching work naturally
- **Framework conventions are automatic** - LiveView gets CoreComponents, Components get ~H
- **Library functions can be explicit** - Use typed externs for Jason, Logger, etc.
- **No unnecessary boilerplate** - Import only what adds value

## Implicit Imports (Automatic Detection)

### How It Works

Implicit imports use **AST pattern detection** during the transformation phase to automatically add necessary imports based on code usage.

```
Haxe Source → TypedExpr → ElixirAST → [Transformation Passes] → Final AST → Elixir Code
                                              ↑
                                    Import Detection Happens Here
```

### Current Implicit Import Triggers

#### 1. Bitwise Operators → `import Bitwise` (Language Feature)

**Why Implicit:** Bitwise operations are native language features in Haxe. Users write `a & b`, not library calls. The compiler transparently handles the transformation to Elixir's triple operators.

**Haxe → Elixir Operator Mapping:**
- `&` → `&&&` (bitwise AND)
- `|` → `|||` (bitwise OR)
- `^` → `^^^` (bitwise XOR)
- `<<` → `<<<` (left shift)
- `>>>` → `>>>` (right shift)
- `~` → `~~~` (bitwise NOT)

**Example:**
```haxe
// Natural Haxe syntax
class Example {
    function test() {
        var masked = value & 0xFF;    // Haxe operator
        var shifted = value << 2;     // Haxe operator
    }
}
```

**Generated Elixir:**
```elixir
defmodule Example do
  import Bitwise  # Auto-added because Elixir requires it
  
  def test() do
    masked = value &&& 255         # Transformed operator
    shifted = value <<< 2          # Transformed operator
  end
end
```

**Implementation:** `bitwiseImportPass` in `ElixirASTTransformer.hx` - Detects Elixir's triple operators in the AST and adds the required import.

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

Explicit imports provide typed access to Elixir library functions through extern classes. These are for library APIs, not language features.

### The @:autoimport Metadata (Future Enhancement)

Extern classes can be marked with `@:autoimport` to generate appropriate import/alias statements:

```haxe
// std/elixir/Jason.hx - JSON library
@:native("Jason")
@:autoimport("alias")    // Would generate: alias Jason
extern class Jason {
    static function encode(term: Dynamic): Result<String, Dynamic>;
    static function decode(json: String): Result<Dynamic, Dynamic>;
}

// std/elixir/Logger.hx - Logging
@:native("Logger")
@:autoimport("require")  // Would generate: require Logger
extern class Logger {
    static function debug(message: String): Void;
    static function info(message: String): Void;
    static function error(message: String): Void;
}
```

### Real-World Usage Examples

```haxe
// Using typed library APIs
import elixir.Jason;
import elixir.Logger;

class ApiHandler {
    static function handleRequest(body: String) {
        // Typed JSON operations
        switch(Jason.decode(body)) {
            case Ok(data):
                Logger.info("Request received");
                processData(data);
            case Error(reason):
                Logger.error('JSON decode failed: $reason');
        }
    }
}
```

**Generated Elixir:**
```elixir
defmodule ApiHandler do
  alias Jason       # Added by @:autoimport
  require Logger    # Added by @:autoimport
  
  def handle_request(body) do
    case Jason.decode(body) do
      {:ok, data} ->
        Logger.info("Request received")
        process_data(data)
      {:error, reason} ->
        Logger.error("JSON decode failed: #{reason}")
    end
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

### Implicit Imports Are For:
- **Language features** - Bitwise operators, pattern matching
- **Framework conventions** - Phoenix.Component, CoreComponents
- **Common patterns** - Detected automatically by the compiler

### Explicit Imports Are For:
- **Library functions** - Jason, Logger, Decimal, Timex
- **Third-party packages** - Any Hex package with typed externs
- **Custom modules** - Your own application modules
- **Migration scenarios** - Integrating with existing Elixir code

### Decision Matrix

| Category | Example | Import Type | Why |
|----------|---------|-------------|-----|
| **Language Operators** | `a & b`, `a << 2` | Always Implicit | Natural Haxe syntax |
| **Framework Patterns** | ~H sigils, LiveView | Always Implicit | Convention over configuration |
| **JSON Operations** | `Jason.encode()` | Explicit (Extern) | Library function, not language feature |
| **Logging** | `Logger.info()` | Explicit (Extern) | Application choice |
| **Process Operations** | `Process.self()` | Explicit (Extern) | OTP library function |
| **Custom Modules** | `MyApp.Users` | Explicit (Import) | Application-specific |

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
1. **@:autoimport implementation** - Generate imports from extern usage
2. **Import optimization** - Remove unused imports
3. **Import grouping** - Organize imports by type
4. **Import aliases** - Support `import X, as: Y`

### Candidates for New Implicit Imports
*Note: These should only be added if they represent language-level features or universal framework conventions*
- Pattern matching constructs that require imports in Elixir
- Other sigil types that need specific modules
- Universal OTP patterns (if any)

### Candidates for New Externs
*These are library functions that benefit from typed APIs*
- **Elixir Standard Library**: Logger, Task, Agent, Registry
- **Popular Libraries**: Decimal, Timex, Oban, Broadway
- **Phoenix Modules**: PubSub, Presence, Token
- **Testing**: ExUnit assertions, Mox, Faker

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
- **Natural language use** - Operators work like native Haxe
- **Library type safety** - Typed access to Elixir libraries
- **Framework alignment** - Matches Elixir/Phoenix philosophy
- **Clear mental model** - Language vs library distinction

### Language Features vs Library Functions

**Language Features** (Always Implicit):
- Written using Haxe's native syntax (`a & b`, `a << 2`)
- Part of the core language semantics
- Should work transparently without user intervention
- Examples: Bitwise operators, pattern matching, string interpolation

**Library Functions** (Can Be Explicit):
- Called as functions (`Jason.encode()`, `Logger.info()`)
- Part of standard library or third-party packages
- Benefit from typed APIs and documentation
- Examples: JSON operations, logging, process management

## Summary

The hybrid import system provides:
- ✅ **Natural language integration** - Haxe operators work seamlessly
- ✅ **Typed library access** - Optional externs for Elixir libraries
- ✅ **Framework conventions** - Phoenix patterns apply automatically
- ✅ **Clear distinction** - Language features vs library functions
- ✅ **No unnecessary complexity** - Import only what adds value

This design ensures that:
- **Language features** (like bitwise operators) work naturally without any user intervention
- **Library functions** (like JSON operations) can have typed APIs when desired
- **Framework patterns** (like LiveView) follow conventions automatically
- **The compiler handles the complexity** of Elixir's import requirements transparently