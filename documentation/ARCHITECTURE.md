# Reflaxe.Elixir Architecture

## Table of Contents
- [Overview](#overview)
- [Compilation Flow](#compilation-flow)
- [Macro-Time vs Runtime](#macro-time-vs-runtime)
- [Component Architecture](#component-architecture)
- [Helper System](#helper-system)
- [Testing Architecture](#testing-architecture)

## Overview

Reflaxe.Elixir is a **Haxe macro-based transpiler** that converts Haxe code to Elixir during the Haxe compilation phase. It's built on the [Reflaxe framework](https://github.com/SomeRanDev/reflaxe), which provides infrastructure for creating custom Haxe compilation targets.

### Key Concepts
- **Transpilation happens at macro-time** (during Haxe compilation)
- **No runtime component** - the transpiler doesn't exist when tests run
- **TypedExpr input** - receives Haxe's typed AST, not raw source code
- **Direct string generation** - outputs Elixir source code as strings

## Compilation Flow

### Complete Compilation Pipeline

```
┌─────────────────┐
│  Haxe Source    │  (.hx files)
│     Code        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Haxe Parser   │  (Built into Haxe compiler)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Untyped AST    │  (Abstract Syntax Tree without type information)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Typing Phase   │  (Haxe's type inference and checking)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   TypedExpr     │  (Fully typed AST with ModuleType nodes)
│  (ModuleType)   │
└────────┬────────┘
         │
         ▼  Context.onAfterTyping callback
┌─────────────────┐
│    Reflaxe      │  ReflectCompiler.onAfterTyping(moduleTypes)
│   Framework     │  - Filters types
│                 │  - Manages output
└────────┬────────┘
         │
         ▼  Calls compiler methods
┌─────────────────┐
│ ElixirCompiler  │  compileClassImpl(classType, vars, funcs)
│  (macro-time)   │  compileEnumImpl(enumType, options)
│                 │  compileExpressionImpl(expr, topLevel)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Elixir Code    │  (.ex files written to disk)
│    Output       │
└─────────────────┘
```

### Phase Details

#### 1. Haxe Compilation Start
- Developer runs `haxe build.hxml` or `npx haxe build.hxml`
- Haxe loads the Reflaxe.Elixir library via `-lib reflaxe_elixir`
- `CompilerInit.Start()` macro is invoked via `--macro`

#### 2. Registration Phase
```haxe
// In CompilerInit.hx
public static function Start() {
    haxe.macro.Context.onAfterInitMacros(Begin);
}

public static function Begin() {
    ReflectCompiler.AddCompiler(new ElixirCompiler(), {
        fileOutputExtension: ".ex",
        outputDirDefineName: "elixir_output",
        fileOutputType: FilePerModule
    });
}
```

#### 3. Haxe Processing
- Haxe **parses** source files into untyped AST
- Haxe **types** the AST, producing TypedExpr with full type information
- Haxe **calls** `Context.onAfterTyping` with all ModuleTypes

#### 4. Reflaxe Processing
```haxe
// In ReflectCompiler.hx
static function onAfterTyping(moduleTypes: Array<ModuleType>) {
    haxeProvidedModuleTypes = moduleTypes;
}

static function onAfterGenerate() {
    // ElixirCompiler is invoked here
    startCompiler(validCompilers[0]);
}
```

#### 5. ElixirCompiler Transformation
- **Receives**: Typed AST nodes (ClassType, EnumType, TypedExpr)
- **Processes**: Each module through specialized helpers
- **Outputs**: Elixir source code strings

## Macro-Time vs Runtime

### Critical Distinction

```haxe
#if (macro || reflaxe_runtime)
// This code EXISTS during Haxe compilation
// ElixirCompiler lives here
class ElixirCompiler extends DirectToStringCompiler {
    // Transforms Haxe AST to Elixir strings
}
#end

#if !macro
// This code EXISTS at runtime (when tests run)
// Test code lives here
@:asserts
class MyTest {
    // Tests run AFTER compilation is complete
    // ElixirCompiler no longer exists!
}
#end
```

### Implications for Testing

1. **Cannot directly test ElixirCompiler at runtime** - it doesn't exist
2. **Must use mocks for runtime testing** - simulate compiler behavior
3. **Real testing happens through compilation** - generate .ex files and validate
4. **tink_unittest bridges the gap** - allows testing of macro-generated code

## Component Architecture

### Core Class Hierarchy

```
BaseCompiler (abstract)
    ↓
GenericCompiler<T,T,T,T,T> (abstract)
    ↓
DirectToStringCompiler (abstract)
    ↓
ElixirCompiler (concrete)
```

### ElixirCompiler Methods

#### Required Overrides
```haxe
public function compileClassImpl(
    classType: ClassType, 
    varFields: Array<ClassVarData>, 
    funcFields: Array<ClassFuncData>
): Null<String>

public function compileEnumImpl(
    enumType: EnumType, 
    options: Array<EnumOptionData>
): Null<String>

public function compileExpressionImpl(
    expr: TypedExpr, 
    topLevel: Bool
): Null<String>
```

#### Annotation Routing
The `AnnotationSystem` detects and routes special annotations:
- `@:schema` → SchemaCompiler
- `@:changeset` → ChangesetCompiler
- `@:liveview` → LiveViewCompiler
- `@:genserver` → OTPCompiler
- `@:migration` → MigrationDSL
- `@:template` → TemplateCompiler
- `@:query` → QueryCompiler

## Helper System

### Specialized Compilers
Each helper handles specific Elixir/Phoenix features:

```
helpers/
├── AnnotationSystem.hx    # Annotation detection and routing
├── ClassCompiler.hx       # Standard class/module compilation
├── EnumCompiler.hx        # Enum to tagged tuple compilation
├── PatternMatcher.hx      # Pattern matching compilation
├── GuardCompiler.hx       # Guard clause compilation
├── SchemaCompiler.hx      # Ecto.Schema generation
├── ChangesetCompiler.hx   # Ecto.Changeset generation
├── LiveViewCompiler.hx    # Phoenix.LiveView generation
├── OTPCompiler.hx         # GenServer generation
├── QueryCompiler.hx       # Ecto.Query DSL compilation
├── MigrationDSL.hx        # Ecto.Migration generation
├── TemplateCompiler.hx    # Phoenix template compilation
└── NamingHelper.hx        # Haxe→Elixir naming conventions
```

### Compilation Flow Example

```haxe
// Input: Haxe class with @:liveview
@:liveview
class CounterLive {
    var count: Int = 0;
    
    function mount(params, session, socket) {
        return {:ok, socket.assign(count: 0)};
    }
}

// ElixirCompiler.compileClassImpl detects @:liveview
// Routes to LiveViewCompiler.compileFullLiveView
// Output: Elixir LiveView module
defmodule CounterLive do
  use Phoenix.LiveView
  
  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end
end
```

## Testing Architecture

### Three-Layer Testing Strategy

The project employs three distinct testing approaches to validate different aspects of the transpiler:

#### Layer 1: Macro-Time Compiler Tests
**Purpose**: Direct testing of the real `ElixirCompiler` during compilation  
**Examples**: `SimpleCompilationTest.hx`, `TestElixirCompiler.hx`  
**Execution**: `haxe test.hxml --interp` with `-D reflaxe_runtime`  
**Framework**: None (use trace/try-catch)  

These tests instantiate the actual compiler and test AST transformation logic:
```haxe
// Runs during compilation, tests REAL compiler
var compiler = new ElixirCompiler();
var result = compiler.compileClassImpl(classType, vars, funcs);
trace(result);
```

#### Layer 2: Runtime Mock Tests  
**Purpose**: Validate expected compilation patterns using mocks  
**Examples**: `OTPCompilerTest.hx`, `SimpleTest.hx`, `AdvancedEctoTest.hx`  
**Execution**: Compile then run with tink_unittest  
**Framework**: tink_unittest + tink_testrunner  

These tests cannot access the real compiler (doesn't exist at runtime):
```haxe
// Runtime mock simulates what compiler would generate
class MockOTPCompiler {
    public static function compileGenServer(name: String): String {
        return 'defmodule $name do\n  use GenServer\nend';
    }
}
```

#### Layer 3: Mix Integration Tests
**Purpose**: End-to-end validation of generated Elixir code  
**Location**: Elixir project `test/` directory  
**Execution**: `npm run test:mix`  
**Framework**: ExUnit  

These provide the ultimate validation:
1. Create `.hx` source files
2. Run Haxe compiler (invokes real ElixirCompiler)
3. Validate generated `.ex` files compile and run
4. Test Phoenix/Ecto/OTP integration

### Dual-Ecosystem Approach

1. **Haxe Tests** (`npm run test:haxe`)
   - Combines macro-time and runtime tests
   - Tests compilation logic and patterns
   - Uses mocks for runtime testing
   - Framework: tink_unittest (for runtime tests only)

2. **Elixir Tests** (`npm run test:mix`)
   - Tests the generated Elixir code
   - Validates Phoenix/Ecto integration
   - Runs in BEAM VM
   - Framework: ExUnit

### Why Runtime Mocks?

```haxe
// In test file
#if (macro || reflaxe_runtime)
import reflaxe.elixir.helpers.OTPCompiler;  // Real compiler
#end

#if !(macro || reflaxe_runtime)
// Mock for runtime testing
class OTPCompiler {
    public static function compileFullGenServer(data: Dynamic): String {
        // Simulated compilation for testing
        return 'defmodule ${data.className} do\n  use GenServer\nend';
    }
}
#end
```

### Test Execution Flow

```
npm test
    ├── npm run test:haxe
    │   ├── Compile test files with Reflaxe.Elixir
    │   ├── Run tink_unittest tests
    │   └── Validate compilation behavior
    │
    └── npm run test:mix
        ├── Create temporary Phoenix project
        ├── Add .hx source files
        ├── Run Mix.Tasks.Compile.Haxe
        ├── Validate generated .ex files
        └── Test Phoenix/Ecto integration
```

## Key Insights

1. **Reflaxe is purely a macro framework** - all work happens during Haxe compilation
2. **TypedExpr is Haxe's responsibility** - we receive it, we don't create it
3. **ElixirCompiler is a transformer** - TypedExpr in, Elixir string out
4. **Testing requires special handling** - macro code can't be tested at runtime
5. **Helper pattern provides modularity** - each Elixir feature has its own compiler

## References

- [Reflaxe Documentation](https://somerandev.github.io/reflaxe/)
- [Haxe Macro Documentation](https://haxe.org/manual/macro.html)
- [TypedExpr API](https://api.haxe.org/haxe/macro/TypedExpr.html)