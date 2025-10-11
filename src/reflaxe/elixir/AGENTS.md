# Compiler Development Context for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions, architecture, and core development principles

This file contains compiler-specific development guidance for agents working on the Reflaxe.Elixir transpiler source code.

## 🏗️ Compiler Architecture Overview

### Core Components
- **ElixirCompiler.hx** - Main GenericCompiler<ElixirAST> implementation, entry point for compilation
- **ast/** directory - AST builder, transformer, and printer for pure AST-based compilation
- **ElixirTyper.hx** - Type mapping between Haxe and Elixir systems
- **schema/** directory - Schema introspection and metadata processing

## 🧭 Transform Design Principles (No Band-Aids)

- Shape to AST, then transform: convert `__elixir__()` injections for standard libs (Ecto.*, Phoenix.*, Ecto.Query.*) into proper AST (ERemoteCall/ECall) in builders so downstream passes can operate generically.
- Consolidate name alignment: one generic pass handles underscore→name, name→_name fallback, and numeric-suffix mapping across all modules and node types (patterns, nested matches, EFn args), run early and late.
- Avoid feature/app-specific passes: do not write transforms tied to a particular module or Phoenix feature (e.g., Presence-only fixes). Fix the underlying architecture so the general pass covers it.
  - Never couple transformers to example apps (e.g., todo-app). Passes must be generic, pattern-driven, and safe across any Elixir codebase. If a need arises from an example, encode it as a general language/framework pattern (e.g., {:ok, v} success tuples) — never by name matching (e.g., "todo").

### Hard Rule: No App-Specific Name Heuristics

- Do NOT key behavior on concrete variable names, atoms, or tags (e.g., "presenceSocket", "live_socket", "toggle_todo", "cancel_edit").
- Do NOT implement suffix/prefix name mappings (e.g., FooSocket→socket). That is app coupling.
- Allowed renames are only:
  - Shape-derived (AST structure),
  - snake_case equivalence to an existing binding, or
  - Clause-local usage-driven when unambiguous (exactly one undefined var used in body).
- Framework allowances must be shape/API-based (e.g., AppWeb.* → App.Repo via module name parts) — never domain strings.

Pre-merge checks:
- [ ] No literal example-name checks in logic
- [ ] No suffix/prefix heuristics against variable names
- [ ] hxdoc WHAT/WHY/HOW + generic examples included
- [ ] `rg -n "todo_|toggle_todo|cancel_edit|presenceSocket|live_socket|updated_todo" src/` returns zero (docs allowed)
- Pass ordering: Builders expose structure first, then generic normalizations, then cleanups. Don’t rely on ordering to paper over misdesigns.
- Enforce hxdoc and <2000 LOC per transformer; extract domain modules when needed.

Common pitfalls to avoid:
- Adding a new pass for a single module (e.g., PresenceVarTransforms). Instead, improve injection shaping and the generic variable alignment pass.
- Depending on ERaw for downstream rewrites; generic passes cannot “see” inside strings.

## ⚠️ CRITICAL: Haxe Metadata Storage Behavior

**FUNDAMENTAL RULE: Haxe ALWAYS strips the colon prefix from metadata when storing internally.**

### How Haxe Handles Metadata
When you write `@:test` in Haxe source code:
1. **Parser sees**: `@:test` (with colon)
2. **Storage**: Haxe strips the colon and stores as `"test"` 
3. **Access**: Use `field.meta.has("test")` NOT `field.meta.has(":test")`

### Correct Metadata Checking
```haxe
// ✅ CORRECT: Check without colon prefix
if (field.meta.has("test")) { ... }
if (field.meta.has("liveview")) { ... }
if (classType.meta.has("exunit")) { ... }

// ❌ WRONG: Checking with colon - will NEVER match
if (field.meta.has(":test")) { ... }      // This will always be false!
if (field.meta.has(":liveview")) { ... }  // Colon already stripped!
```

### Common Metadata Annotations and Their Storage
| Written in Haxe | Stored Internally | Check With |
|-----------------|------------------|------------|
| `@:test` | `"test"` | `meta.has("test")` |
| `@:liveview` | `"liveview"` | `meta.has("liveview")` |
| `@:exunit` | `"exunit"` | `meta.has("exunit")` |
| `@:native("Name")` | `"native"` | `meta.has("native")` |
| `@:schema` | `"schema"` | `meta.has("schema")` |
| `@:endpoint` | `"endpoint"` | `meta.has("endpoint")` |

### Why This Matters
- **No defensive programming needed**: Don't check both with and without colon
- **Consistent behavior**: This applies to ALL metadata in Haxe
- **Clean code**: Single check is sufficient and correct
- **Performance**: Avoid redundant string comparisons

### 📁 Complete Compiler File Structure

**⚠️ CRITICAL RULE: When adding new helper compilers, ALWAYS update this tree**

```
src/reflaxe/elixir/
├── ElixirCompiler.hx             # Main transpiler (MUST stay <2000 lines)
├── ElixirPrinter.hx              # AST to string conversion
├── ElixirTyper.hx                # Type mapping (Haxe → Elixir)
├── CLAUDE.md                     # THIS FILE - Keep updated!
└── helpers/                      # Specialized compilers (Single Responsibility)
    ├── AnnotationSystem.hx       # @:annotation processing system
    ├── ApplicationCompiler.hx   # @:application OTP app generation
    ├── ChangesetCompiler.hx      # @:changeset Ecto validation
    ├── ClassCompiler.hx          # Class/struct → module compilation
    ├── CompilerUtilities.hx      # ⚡ Shared utilities (NO DUPLICATION!)
    ├── ConditionalCompiler.hx    # Complex conditional expressions
    ├── EnumCompiler.hx           # Enum → tagged tuples + pattern matching
    ├── EndpointCompiler.hx       # @:endpoint Phoenix endpoint
    ├── GenServerCompiler.hx      # @:genserver OTP behavior
    ├── HxxCompiler.hx            # HXX → HEEx template compilation
    ├── LiveViewCompiler.hx       # @:liveview Phoenix LiveView
    ├── MigrationCompiler.hx      # @:migration Ecto migrations
    ├── NamingHelper.hx           # camelCase → snake_case conversion
    ├── OTPCompiler.hx            # OTP patterns (supervisors, child specs)
    ├── PatternAnalysisCompiler.hx # Pattern detection and analysis
    ├── PatternMatchingCompiler.hx # Switch/case → Elixir pattern matching
    ├── ProtocolCompiler.hx       # @:protocol/@:impl Elixir protocols
    ├── ReflectionCompiler.hx     # Reflect.* API implementation
    ├── RouterCompiler.hx         # @:router Phoenix router DSL
    ├── SchemaCompiler.hx         # @:schema Ecto models
    ├── StringMethodCompiler.hx   # String method → Elixir String module
    ├── TestCompiler.hx           # @:test ExUnit test generation
    └── VariableCompiler.hx       # Variable naming and tracking
```

### 📚 Utility Guidelines - PREVENT DUPLICATION

**CompilerUtilities.hx** is the SINGLE source of truth for shared functionality:
- String manipulation (stripQuotes, stripColon)
- Atom formatting (formatAsAtom)
- Code indentation (indentCode)
- Field extraction (extractFieldName)
- Variable naming (toElixirVarName)
- AST traversal helpers (findFirstTLocal)
- Multi-statement detection (containsMultipleStatements)

**⚠️ BEFORE ADDING ANY UTILITY FUNCTION:**
1. Check CompilerUtilities.hx first
2. Check if similar functionality exists
3. If not found, ADD to CompilerUtilities, NOT to individual compilers
4. Document with WHY/WHAT/HOW pattern
5. Update this CLAUDE.md file

## ⚠️ CRITICAL: CallExprBuilder Duplication and self() Bug (January 2025)

**INVESTIGATION RESULT**: Two CallExprBuilder files exist, but only ONE is actively used.

### File Status
- **✅ ACTIVE**: `src/reflaxe/elixir/ast/builders/CallExprBuilder.hx` (569 lines)
  - Package: `reflaxe.elixir.ast.builders`
  - Imported by: `ElixirASTBuilder.hx:28`
  - Has `static buildCall()` method
  - Contains Phoenix self() injection logic (lines 462-542)
  - **Contains the self() bug** (lines 489, 510)

- **❌ LEGACY/UNUSED**: `src/reflaxe/elixir/helpers/CallExprBuilder.hx` (250 lines)
  - Package: `reflaxe.elixir.helpers`
  - NOT imported anywhere
  - Has instance `buildCall()` method (requires `new`)
  - NO self() handling
  - Leftover from failed modularization attempt (commit ecf50d9d)

### The self() Bug in Active CallExprBuilder

**Location**: Lines 489 and 510 in `ast/builders/CallExprBuilder.hx`

**Buggy Code**:
```haxe
// Line 489 (PubSub) and 510 (Presence)
var selfCall = makeAST(ECall(makeAST(EVar("self")), "", []));
```

**What This Creates**:
- `target` = `EVar("self")` (variable "self" as target)
- `funcName` = `""` (empty function name)
- `args` = `[]`

**How Printer Interprets It** (`ElixirASTPrinter.hx:639-641`):
```haxe
if (funcName == "") {
    // Function variable call - use .() syntax
    print(target, indent) + '.(' + argStr + ')';  // Generates: self.()
}
```

**Result**: Generates `self.()` which is:
1. Invalid syntax (`self.()` vs `self()`)
2. Wrong semantics (function variable invocation vs kernel function call)
3. Causes compilation error: "undefined variable 'self'"

### The Fix

**Correct Pattern for Kernel Functions**:
```haxe
// For kernel functions like self(), spawn(), node(), etc.
var selfCall = makeAST(ECall(null, "self", []));
```

**Why This Works**:
- `target` = `null` (no module, no variable)
- `funcName` = `"self"` (the function name)
- `args` = `[]`

**Printer Handles It** (`ElixirASTPrinter.hx:659-661`):
```haxe
} else {
    funcName + '(' + argStr + ')';  // Generates: self()
}
```

**Result**: Generates correct `self()` kernel function call.

### ECall AST Pattern Reference

From `ElixirAST.hx:161`:
```haxe
/** Function call */
ECall(target: Null<ElixirAST>, funcName: String, args: Array<ElixirAST>);
```

**Three ECall Patterns**:
1. **Kernel/module function**: `ECall(null, "function_name", [args])` → `function_name(args)`
2. **Function variable**: `ECall(EVar("var"), "", [args])` → `var.(args)`
3. **Method call**: `ECall(target, "method", [args])` → `target.method(args)`

### Cleanup Action Needed

The legacy `helpers/CallExprBuilder.hx` should be deleted:
- Not imported anywhere
- Confusing to have two versions
- Part of abandoned refactoring (commit ecf50d9d)
- All functionality is in the active `ast/builders` version

### Git History Context

- `fc489696` - Extract CallExprBuilder from ElixirASTBuilder (active version)
- `f2acaa11` - Add CallExprBuilder helper (legacy version)
- `ecf50d9d` - Failed modularization attempt that created duplication

## ⚠️ CRITICAL: Understanding @:native Metadata in Reflaxe.Elixir

**FUNDAMENTAL LESSON (January 2025): @:native in Reflaxe compilers works differently than standard Haxe.**

### The @:native Pattern for Module Naming

**Standard Haxe @:native** (for externs only):
- Used on `extern` classes to map to external library names
- Example: `@:native("$") extern class JQuery` maps to jQuery's `$`
- ONLY works on actual extern classes

**Reflaxe @:native Pattern** (for generated code):
- Can be used on **regular (non-extern) classes** to control output names
- Example: `@:native("TodoAppWeb.Presence") class TodoPresence`
- Generates module named `TodoAppWeb.Presence` instead of `TodoPresence`
- This is **valid and standard** in Reflaxe compilers (see reflaxe/test/MyClass.hx)

### Why This Matters for Phoenix

Phoenix has strict module naming conventions:
- Presence modules must be `AppNameWeb.Presence`
- LiveView modules must be `AppNameWeb.SomethingLive`
- Router must be `AppNameWeb.Router`

Using `@:native` lets us:
- Write clean Haxe class names (`TodoPresence`)
- Generate idiomatic Elixir modules (`TodoAppWeb.Presence`)
- Follow Phoenix conventions without awkward Haxe names

### Known Issue: BehaviorTransformer with @:native Classes

**Problem**: Classes with both `@:presence` and `@:native` don't get proper self() injection.

**Root Cause**: When ModuleBuilder compiles methods, the BehaviorTransformer transformations are applied at the AST level but not preserved in the final output.

**Symptoms**:
- Debug shows "[BehaviorTransformer] Transformed Presence.track call"
- But generated code lacks self(): `track(socket, user_id, meta)` instead of `track(self(), socket, user_id, meta)`

**Fix Needed**: Ensure ModuleBuilder preserves BehaviorTransformer transformations when building function bodies.

## 🔄 Inheritance via Delegation Pattern

**STATUS**: Fully Implemented (September 2025)
**ARCHITECTURE**: Transforms OOP inheritance to Elixir's delegation pattern

### Overview
Since Elixir doesn't support traditional OOP inheritance, we transform Haxe's inheritance model into idiomatic Elixir delegation patterns. This system detects parent-child relationships at compile time and generates appropriate delegation calls.

### How It Works

#### 1. Parent Class Detection (ElixirCompiler.hx:1320-1354)
```haxe
// Detect parent class via ClassType.superClass
if (classType.superClass != null) {
    var parentClass = classType.superClass.t.get();
    var parentModuleName = parentClass.name;
    metadata.parentModule = parentModuleName;
    
    // Traverse inheritance chain for Exception detection
    var currentClass = parentClass;
    while (currentClass != null) {
        if (/* is haxe.Exception */) {
            metadata.isException = true;
            break;
        }
        currentClass = currentClass.superClass?.t.get();
    }
}
```

#### 2. Metadata Flow Through Pipeline
The inheritance information flows through the AST pipeline via `ElixirMetadata`:
```haxe
typedef ElixirMetadata = {
    ?parentModule: String,    // Parent class module name
    ?isException: Bool,       // Whether extends haxe.Exception
    // ... other metadata
}
```

#### 3. Super Method Transformation (ElixirASTTransformer.hx)
Super method calls are transformed in the `selfReferenceTransformPass`:
```haxe
// Transform: super.method(args)
// Into: ParentModule.method(struct, args)
case EField(EVar("super"), methodName):
    var parentModule = metadata.parentModule;
    return ERemoteCall(
        EVar(parentModule),    // Module reference (not atom!)
        methodName,
        [EVar("struct"), ...args]  // Prepend struct parameter
    );
```

#### 4. Exception Class Handling (ModuleBuilder.hx)
Classes that extend Exception get special treatment:
```haxe
if (metadata.isException == true) {
    // Generate defexception instead of defmodule
    // Implements Exception protocol automatically
}
```

### Example Transformations

#### Basic Inheritance
```haxe
// Haxe Input
class Parent {
    public function describe(): String {
        return "Parent";
    }
}

class Child extends Parent {
    override public function describe(): String {
        return super.describe() + " -> Child";
    }
}
```

```elixir
# Generated Elixir
defmodule Parent do
  def describe(struct) do
    "Parent"
  end
end

defmodule Child do
  def describe(struct) do
    Parent.describe(struct) <> " -> Child"  # Delegation
  end
end
```

#### Exception Classes
```haxe
// Haxe Input
class CustomError extends haxe.Exception {
    public function new(msg: String) {
        super(msg);
    }
}
```

```elixir
# Generated Elixir
defexception CustomError do
  @impl true
  def message(exception) do
    exception.message
  end
end
```

### Multi-Level Inheritance
The system correctly handles deep inheritance chains:
- GrandParent → Parent → Child → GrandChild
- Each level delegates to its immediate parent
- Exception detection traverses the entire chain

### Limitations & Future Work
1. **Interfaces**: Not yet implemented - could map to Elixir behaviors
2. **Abstract Classes**: Haxe doesn't have traditional abstract classes
3. **Constructor Chaining**: super() in constructors needs special handling
4. **Multiple Inheritance**: Not supported (Haxe limitation)

### Testing
Comprehensive tests in `test/snapshot/core/inheritance_delegation/` validate:
- Basic inheritance with method overrides
- Super method delegation
- Exception class generation
- Multi-level inheritance chains

## ⚡ Critical Compilation Concepts

### Macro-Time vs Runtime ⚠️ FUNDAMENTAL
**The compiler ONLY exists during Haxe compilation, NOT at runtime:**
```haxe
#if macro
class ElixirCompiler extends BaseCompiler {
    // This class exists ONLY while Haxe is compiling
    // It transforms TypedExpr AST → Elixir code strings
    // Then it DISAPPEARS forever
}
#end
```

**Key Implications:**
- You cannot unit test compiler classes directly
- All transpilation happens during `haxe build.hxml`
- TypedExpr AST is provided BY Haxe, not created by us
- Test the OUTPUT (.ex files), not the compiler internals

### GenericCompiler Architecture
We inherit from Reflaxe's `GenericCompiler`:
```haxe
class ElixirCompiler extends GenericCompiler<ElixirAST, ElixirAST, ElixirAST, ElixirAST, ElixirAST> {
    // Override specific methods for Elixir-specific behavior
    override function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<ElixirAST>
    override function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<ElixirAST>
    override function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<ElixirAST>
}
```

## 🎯 Development Rules ⚠️ CRITICAL

### ❌ NEVER Do This:
- Edit generated .ex files to "fix" compilation issues
- Add hardcoded TODOs in production code
- Use string manipulation instead of AST processing
- Skip testing with `npm test` after changes
- Commit without verifying todo-app compiles
- Add redundant `#if macro` guards inside files already wrapped in `#if (macro || reflaxe_runtime)`

### ✅ ALWAYS Do This:
- **Research idiomatic Elixir patterns FIRST** before translating any Haxe pattern
- **Adapt for immutability** - Elixir is immutable, Haxe often assumes mutability
- **Provide "Elixir way" constructs and APIs** - Allow users to write Haxe in a more Elixir-like style
- Test ALL changes with `npm test`
- Verify todo-app compilation after compiler changes
- Process TypedExpr AST until the last possible moment
- Apply transformations at AST level, not string level
- Fix root causes, never add workarounds

### Development Workflow
```bash
# 1. Make compiler changes
vim src/reflaxe/elixir/ElixirCompiler.hx

# 2. Test immediately
npm test

# 3. Verify integration
cd examples/todo-app && mix compile --force

# 4. Fix any failures, repeat
```

## 📝 AST Processing Patterns

### TypedExpr Processing Best Practices
```haxe
// ✅ GOOD: Build AST nodes with metadata
function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<ElixirAST> {
    var ast = switch(expr.expr) {
        case TCall(e, el): buildCallAST(e, el);     // Build AST nodes
        case TBinop(op, e1, e2): buildBinopAST(op, e1, e2);
        default: // Handle all cases
    }
    return ast;
}

// ❌ BAD: String manipulation instead of AST
function compileExpression(expr: TypedExpr): String {
    var str = simpleStringConversion(expr);
    return manipulateString(str); // Lost structural information
}
```

### Variable Substitution Pattern
When lambda parameters need different names:
```haxe
// 1. Find source variable in AST
var sourceVar = findLoopVariable(expr);

// 2. Apply recursive substitution  
var processedExpr = compileExpressionWithSubstitution(expr, sourceVar, "item");

// 3. Generate consistent output
return 'Enum.map(${array}, fn item -> ${processedExpr} end)';
```

## 🔧 Helper Compiler Development

### Creating New Helper Compilers
```haxe
class NewFeatureCompiler {
    var compiler: ElixirCompiler;
    
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }
    
    public function compileNewFeature(classType: ClassType): String {
        // 1. Extract metadata
        var meta = classType.meta.extract(":newfeature");
        
        // 2. Process class structure  
        var fields = processFields(classType.fields.get());
        
        // 3. Generate Elixir code
        return generateElixirModule(fields);
    }
}
```

### Integration with Main Compiler
```haxe
// In ElixirCompiler.hx
var newFeatureCompiler = new NewFeatureCompiler(this);

override function compileClass(classType: ClassType, varFields: Array<String>): String {
    if (classType.meta.has(":newfeature")) {
        return newFeatureCompiler.compileNewFeature(classType);
    }
    return super.compileClass(classType, varFields);
}
```

## 🚨 Common Mistakes to Avoid

### Redundant Conditional Compilation Guards
**MISTAKE**: Adding `#if macro` guards inside files already wrapped in `#if (macro || reflaxe_runtime)`

```haxe
// ❌ WRONG: Redundant guard
#if (macro || reflaxe_runtime)
abstract ElixirAtom(String) {
    #if macro  // <-- REDUNDANT!
    @:from static function fromEnumField(ef: EnumField): ElixirAtom {
        return new ElixirAtom(ef.name);
    }
    #end
}
#end

// ✅ RIGHT: File-level guard is sufficient
#if (macro || reflaxe_runtime)
abstract ElixirAtom(String) {
    @:from static function fromEnumField(ef: EnumField): ElixirAtom {
        return new ElixirAtom(ef.name);  // EnumField available in both macro and reflaxe_runtime
    }
}
#end
```

**KEY INSIGHT**: 
- `#if (macro || reflaxe_runtime)` means the code exists ONLY during compilation
- Both `macro` and `reflaxe_runtime` contexts have access to macro types like `EnumField`
- Additional `#if macro` is only needed if you want code ONLY in macro context, not reflaxe_runtime

## 🧪 Testing Compiler Changes

### Snapshot Test Creation
1. **Create test directory**: `test/tests/new_feature/`
2. **Add compile.hxml**: Configure compilation
3. **Add Main.hx**: Test source code
4. **Run initial compilation**: `haxe test/Test.hxml test=new_feature`
5. **Review output**: Check `out/` directory
6. **Accept if correct**: `haxe test/Test.hxml test=new_feature update-intended`

### Debug Compilation Issues
```haxe
// Add debug output (remove before commit)
trace('Processing expression: ${expr}');
trace('Generated result: ${result}');

// Use Haxe's Position for error reporting
Context.error('Custom error message', expr.pos);
```

## 🎨 Code Generation Patterns

### Idiomatic Elixir Output
**Goal**: Generated code should look hand-written by Elixir experts
```elixir
# ✅ GOOD: Idiomatic Elixir
def process_items(items) do
  items
  |> Enum.filter(&valid?/1)
  |> Enum.map(&transform/1)
end

# ❌ BAD: Mechanical translation
def processItems(items) do
  result = []
  for item in items do
    if (valid(item)) do
      result = [transform(item) | result]
    end
  end
  Enum.reverse(result)
end
```

### Pattern Matching Generation
```haxe
// Generate proper Elixir pattern matching
function generatePatternMatch(enumType: EnumType): String {
    var cases = [];
    for (construct in enumType.constructs) {
        var pattern = generatePattern(construct);
        var body = generateBody(construct);
        cases.push('${pattern} -> ${body}');
    }
    return 'case value do\n${cases.join("\n")}\nend';
}
```

## 🎛️ Feature Flag System (Compatibility Mode)

**STATUS**: Implemented January 2025
**PURPOSE**: Allow gradual migration from old working code to new experimental features

### Architecture
The feature flag system has three layers:
1. **ElixirASTContext** - Stores the actual feature flag map
2. **BuildContext Interface** - Provides the API (`isFeatureEnabled`, `setFeatureFlag`)
3. **CompilationContext** - Delegates to astContext, initialized from compiler defines

### Available Feature Flags

| Flag Name | Purpose | Default |
|-----------|---------|---------|
| `new_module_builder` | Use new ModuleBuilder system | false |
| `loop_builder_enabled` | Enable LoopBuilder with safety guards | false |
| `idiomatic_comprehensions` | Generate comprehensions instead of reduce_while | false |
| `pattern_extraction` | Use new pattern variable extraction | false |
| `use_new_pattern_builder` | Use modular pattern match builder | false |
| `use_new_loop_builder` | Use modular loop builder | false |

### Usage via Command Line

```bash
# Enable specific features
npx haxe build.hxml -D elixir.feature.new_module_builder=true

# Enable all experimental features
npx haxe build.hxml -D elixir.feature.experimental=true

# Force legacy mode (disable all new features)
npx haxe build.hxml -D elixir.feature.legacy=true

# Debug feature flag state
npx haxe build.hxml -D debug_feature_flags
```

### Using in Compiler Code

```haxe
// Check if a feature is enabled
if (context.isFeatureEnabled("loop_builder_enabled")) {
    // Use new loop builder
    return LoopBuilder.build(expr, context);
} else {
    // Use legacy loop compilation
    return buildWhileLoopLegacy(expr);
}

// Set a feature programmatically
context.setFeatureFlag("idiomatic_comprehensions", true);
```

### Implementation Details
- Feature flags are initialized in `ElixirCompiler.initializeFeatureFlags()`
- Flags default to `false` (old behavior) for safety
- The `experimental` flag enables all new features at once
- The `legacy` flag explicitly disables all new features
- Flags are stored in `ElixirASTContext.featureFlags` map
- All builders and transformers can check flags via `BuildContext`

### Why This Architecture?
1. **Gradual Migration**: Fix tests incrementally without breaking everything
2. **A/B Testing**: Compare old vs new behavior side-by-side
3. **Safe Rollback**: Can instantly revert to old behavior if issues arise
4. **User Control**: Users can opt into experimental features when ready
5. **Development Velocity**: Can merge partial improvements behind flags

## 🎯 Critical Compiler Patterns (September 2025)

### Constructor Context Pattern - Surgical Variable Resolution

**Problem**: Function parameters were incorrectly renamed when passed as constructor arguments due to stale parameter mapping contexts.

**Solution**: Context flags for surgical precision in variable resolution.

```haxe
// VariableBuilder.hx - Context flag pattern
public static function resolveVariableName(
    name: String,
    context: BuildContext,
    ?isConstructorArg: Bool = false  // Explicit context flag
): String {
    // HIGHEST PRIORITY: Preserve names in specific contexts
    if (isConstructorArg == true) {
        return toElixirVarName(name);  // No renaming in constructor args
    }

    // Continue with general resolution logic...
}
```

**Integration Pattern**:
```haxe
// ConstructorBuilder.hx - Pass context flag
for (arg in args) {
    var argName = extractArgumentName(arg);
    var resolvedName = VariableBuilder.resolveVariableName(
        argName,
        context,
        true  // Mark as constructor argument context
    );
    compiledArgs.push(resolvedName);
}
```

**Why This Works**:
- **Surgical precision**: Only affects constructor argument contexts
- **No heuristics**: Explicit intent via boolean flag
- **Self-documenting**: Flag name explains purpose
- **Easy testing**: Can toggle flag independently
- **Preserves architecture**: Doesn't break other variable resolution paths

**Architectural Benefits**:
1. **Context Awareness**: Resolution knows WHERE it's being used
2. **Priority-Based**: Specific contexts override general rules
3. **Maintainable**: Clear separation between context-specific and general logic
4. **Extensible**: Easy to add new context flags (isPatternBinding, isLoopVariable, etc.)

**See**: [`/docs/03-compiler-development/JSONPRINTER_COMPILATION_FIX.md`](/docs/03-compiler-development/JSONPRINTER_COMPILATION_FIX.md) - Complete fix documentation

### Elixir Rebinding Semantics in Hygiene Transforms

**Critical Understanding**: Elixir's `=` operator is pattern matching/rebinding, NOT variable declaration.

```elixir
# Elixir semantics
v = 1          # First binding
v = v + 1      # REBINDING same variable (not creating v_2!)

# vs Imperative semantics (what hygiene initially assumed)
let v = 1;         # Binding 1
let v_2 = v + 1;   # Binding 2 (new variable)
```

**Implication for HygieneTransforms**:

```haxe
// HygieneTransforms.hx - EMatch handling
case EMatch(pattern, expr):
    // Process RHS first to mark usage
    state.currentContext = Expr;
    traverseWithContext(expr, state, allBindings);

    // SKIP LHS pattern processing for EMatch
    // In Elixir, 'v = replacer(key, v)' is rebinding, not new binding
    // The RHS 'v' correctly uses existing parameter
    // Creating second binding would mark parameter as unused
```

**Why This Matters**:
- **Language semantics alignment**: Compiler respects target language behavior
- **Prevents false positives**: Variables aren't marked unused when they're being rebound
- **Idiomatic output**: Generates natural Elixir rebinding patterns

**See**: [`/docs/03-compiler-development/JSONPRINTER_COMPILATION_FIX.md`](/docs/03-compiler-development/JSONPRINTER_COMPILATION_FIX.md#problem-4-parameter-shadowing-in-replacer-callback)

## 📚 Related Documentation
- [`/documentation/COMPILER_BEST_PRACTICES.md`](/documentation/COMPILER_BEST_PRACTICES.md) - Complete development practices
- [`/documentation/COMPILER_PATTERNS.md`](/documentation/COMPILER_PATTERNS.md) - Implementation patterns
- [`/documentation/ARCHITECTURE.md`](/documentation/ARCHITECTURE.md) - Overall architecture
- [`/documentation/HAXE_MACRO_APIS.md`](/documentation/HAXE_MACRO_APIS.md) - Correct macro API usage
- [`/docs/03-compiler-development/JSONPRINTER_COMPILATION_FIX.md`](/docs/03-compiler-development/JSONPRINTER_COMPILATION_FIX.md) - JsonPrinter fix documentation

## 🏆 Quality Standards

Every compiler change must meet these standards:
- **Correctness**: Generated Elixir must be syntactically and semantically correct
- **Idiomaticity**: Output should follow Elixir best practices and conventions  
- **Type Safety**: Preserve Haxe's compile-time guarantees in generated code
- **Performance**: Generated code should be efficient and not wasteful
- **Maintainability**: Compiler code itself must be clear and well-documented

**Remember**: We're not just generating syntactically correct Elixir - we're generating IDIOMATIC Elixir that Elixir developers would be proud to write themselves.
