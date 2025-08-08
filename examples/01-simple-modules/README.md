# Simple Elixir Module Examples

This directory demonstrates the most basic usage of Haxe→Elixir compilation, focusing on creating simple Elixir modules using the `@:module` syntax.

## Learning Objectives

- Understand `@:module` annotation for clean syntax
- Learn pipe operator (`|>`) usage in Haxe
- Master public and private function patterns
- See the compilation output compared to hand-written Elixir

## Examples Overview

### 1. BasicModule.hx
**Demonstrates:** Core `@:module` syntax, basic functions
**Compiles to:** `BasicModule.ex`

### 2. MathHelper.hx  
**Demonstrates:** Pipe operators, functional composition
**Compiles to:** `MathHelper.ex`

### 3. UserUtil.hx
**Demonstrates:** Public/private functions, `@:private` annotation
**Compiles to:** `UserUtil.ex`

## Running the Examples

### Compile All Examples
```bash
cd examples/01-simple-modules
haxe compile-all.hxml
```

### Compile Individual Examples
```bash
# Basic module
haxe BasicModule.hxml

# Math helper with pipes
haxe MathHelper.hxml  

# User utilities with private functions
haxe UserUtil.hxml
```

### Compare Output
Each example includes:
- `.hx` source file (Haxe)
- `.hxml` compilation config
- `expected/` directory with hand-written Elixir equivalent
- `output/` directory with compiled result

```bash
# Compare compiled vs expected
diff output/BasicModule.ex expected/BasicModule.ex
```

## Key Concepts Demonstrated

### @:module Annotation
Eliminates the need to write `public static` on every function:

```haxe
@:module
class BasicModule {
    // Automatically becomes "def hello() do"
    function hello(): String {
        return "world";
    }
}
```

### Pipe Operators
Native Elixir-style functional composition:

```haxe
function calculate(x: Float): Float {
    return x
           |> multiplyByTwo()
           |> addTen()
           |> Math.round();
}
```

### Private Functions
Use `@:private` for defp generation:

```haxe
@:private
function validateInput(data: String): Bool {
    return data != null && data.length > 0;
}
```

## Next Steps

After mastering simple modules, continue to:
- [02-mix-project](../02-mix-project/) - Integration with Mix build system
- [03-phoenix-controllers](../03-phoenix-controllers/) - Web request handling
- [04-phoenix-liveview](../04-phoenix-liveview/) - Real-time interactivity

## Troubleshooting

**Compilation errors?**
- Ensure Haxe 4.3.6+ is installed
- Check that `reflaxe_runtime` flag is set in .hxml files
- Verify src/ directory is in classpath

**Output doesn't match expected?**
- This is normal as compiler output may include additional metadata
- Focus on the core function definitions and module structure