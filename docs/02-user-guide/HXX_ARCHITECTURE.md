# HXX Template Architecture: Compile-Time vs Runtime

## ⚠️ Critical Architectural Insight

**HXX is purely compile-time processing** - it transforms JSX-like syntax to Phoenix HEEx templates during Haxe→Elixir compilation. **There is no runtime HXX component.**

## Architecture Overview

### The Correct Model: Compile-Time Transformation

```
Haxe Source (JSX-like) → Haxe Compilation → Elixir Code (HEEx ~H sigils)
```

**HXX exists only during compilation step**. The generated Elixir contains standard Phoenix HEEx templates with no HXX dependencies.

### The Wrong Model: Runtime Processing ❌

```
Haxe Source → Elixir Code with HXX calls → Runtime HXX module → HEEx
```

**This was our initial mistake** - creating `std/phoenix/HXX.hx` as a runtime module. This is architecturally incorrect because:

1. **Templates should be static** - processed at compile time for performance
2. **No runtime dependencies** - generated Elixir should be pure Phoenix
3. **Type safety lost** - runtime processing can't provide compile-time checks

## How HXX Actually Works

### 1. Local HXX Placeholder

Each application has a local `HXX.hx` file:

```haxe
// src_haxe/HXX.hx
class HXX {
    public static function hxx(templateStr: String): String {
        // Placeholder for type checking - never executed
        return templateStr;
    }
}
```

**Purpose**: Provides function signature for Haxe type checking only.

### 2. Compiler Detection

`ElixirCompiler.hx` detects `HXX.hxx()` calls:

```haxe
// In compileExpression() - TCall handler
if (objStr == "HXX" && methodName == "hxx") {
    return compileHxxCall(args);  // Transform to HEEx
}
```

**Key**: Detection happens during AST processing, before the placeholder function would ever run.

### 3. Template Transformation

`compileHxxCall()` processes templates:

```haxe
case TConst(TString(s)):
    var processed = processHxxTemplate(s);      // JSX → HEEx syntax
    return formatHxxTemplate(processed);        // Wrap in ~H sigil

case TBinop(OpAdd, _, _):
    var rawContent = extractRawStringFromTBinop(args[0]);
    var processed = processHxxTemplate(rawContent);
    return formatHxxTemplate(processed);
```

**Result**: Direct generation of `~H"""..."""` strings in Elixir code.

### 4. Generated Output

Input Haxe:
```haxe
function render(assigns: Dynamic): String {
    return HXX.hxx('<div class="user">${assigns.user.name}</div>');
}
```

Generated Elixir:
```elixir
def render(assigns) do
  ~H"""
  <div class="user">{assigns.user.name}</div>
  """
end
```

**No HXX references in generated code** - pure Phoenix HEEx.

## Template Processing Pipeline

### 1. AST Analysis
- Detect `HXX.hxx()` calls in typed AST
- Extract raw template strings before escaping
- Handle both simple strings and multiline concatenations

### 2. Syntax Transformation
- Convert `${}` interpolation to `{}` (HEEx format)
- Transform component syntax (`<.button>` stays as-is)
- Process conditional rendering and loops
- Handle LiveView event attributes

### 3. HEEx Generation
- Wrap processed template in `~H"""..."""` sigil
- Ensure proper indentation and formatting
- Generate valid Phoenix template syntax

## Why No Runtime Module?

### Performance
- **Compile-time**: Templates processed once during build
- **Runtime**: Templates are static strings, no processing overhead
- **Caching**: Phoenix compiles templates to efficient bytecode

### Type Safety
- **Compile-time**: Template expressions type-checked by Haxe
- **Template validation**: Syntax errors caught during compilation
- **IDE support**: Autocomplete and error highlighting work

### Framework Integration
- **Standard Phoenix**: Generated code uses standard ~H sigils
- **Deployment**: No custom dependencies in production
- **Tooling**: Works with all Phoenix development tools

## Architectural Lessons

### 1. Distinguish Compile-Time vs Runtime
**Always ask**: "Does this need to exist when the application runs?"

- **Compile-time tools**: Transform source code (HXX, macros, code generators)
- **Runtime libraries**: Provide functionality during execution (Phoenix, Ecto)

### 2. Prefer Static Generation
When possible, generate static code rather than runtime processing:

```haxe
// ✅ GOOD: Compile-time generation
HXX.hxx('<div>Static template</div>') 
// → Generates: ~H"<div>Static template</div>"

// ❌ BAD: Runtime processing  
SomeModule.processTemplate('<div>Dynamic template</div>')
// → Runtime overhead, no compile-time validation
```

### 3. Framework Compatibility
Generated code should use standard framework patterns:

- **Phoenix**: Use ~H sigils, not custom template functions
- **Ecto**: Generate standard schema modules, not wrappers
- **OTP**: Create proper GenServer modules, not abstractions

### 4. Test the Architecture
Verify that generated code works without the compiler:

```bash
# Generated Elixir should compile and run independently
cd generated_project
mix compile  # Should work without Haxe/Reflaxe
mix test     # Should pass with standard Phoenix tools
```

## Common Mistakes to Avoid

### 1. Creating Runtime Modules for Compile-Time Features
```haxe
// ❌ WRONG: Runtime module for compile-time feature
class HXX {
    public static function hxx(templateStr: String): String {
        return processTemplate(templateStr);  // Runtime processing
    }
}
```

### 2. Over-Abstracting Framework Features
```haxe
// ❌ WRONG: Custom abstraction over Phoenix
class LiveViewHelper {
    public static function render(template: String): String {
        return "~H\"" + template + "\"";  // Runtime string manipulation
    }
}

// ✅ GOOD: Direct Phoenix integration
function render(assigns: Dynamic): String {
    return HXX.hxx('<div>Direct HEEx generation</div>');
}
```

### 3. Mixing Compilation Phases
```haxe
// ❌ WRONG: Trying to use compile-time tools at runtime
public static function renderDynamic(template: String): String {
    return HXX.hxx(template);  // Can't work - HXX is compile-time only
}

// ✅ GOOD: Separate concerns
public static function renderStatic(): String {
    return HXX.hxx('<div>Compile-time template</div>');
}
```

## Testing HXX Architecture

### Verify Compile-Time Processing
1. **Check generated .ex files** contain ~H sigils, not HXX calls
2. **Compile without Haxe** - Elixir project should be self-contained
3. **Performance test** - templates should be fast (no runtime processing)

### Validate Template Transformation
```haxe
// Input
HXX.hxx('<div class="user">${assigns.name}</div>')

// Expected output in .ex file
~H"""
<div class="user">{assigns.name}</div>
"""
```

## Related Documentation

- **[HXX Implementation](HXX_IMPLEMENTATION.md)** - Technical details of template processing
- **[HXX Guide](guides/HXX_GUIDE.md)** - User guide for writing templates
- **[Compilation Flow](COMPILATION_FLOW.md)** - Overall compilation architecture
- **[Haxe Language Fundamentals](HAXE_LANGUAGE_FUNDAMENTALS.md)** - Type system insights

## Key Takeaway

**HXX is a compile-time preprocessor, not a runtime library. Understanding this distinction is crucial for proper architecture and prevents creating unnecessary runtime dependencies.**