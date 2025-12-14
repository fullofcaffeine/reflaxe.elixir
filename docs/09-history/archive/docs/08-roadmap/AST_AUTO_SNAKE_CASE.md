# Automatic Naming Convention System for Elixir AST

## Problem Statement
Currently, we manually call `NameUtils.toSnakeCase()` throughout the compiler for EVERY naming element:
- **Atoms**: Enum constructors, record keys, module attributes
- **Functions**: Method names, static functions, callbacks
- **Variables**: Local variables, parameters, pattern variables
- **Fields**: Struct fields, class properties
- **Modules**: Module names need PascalCase but components need special handling

This violates DRY principles and is error-prone. Each AST node type has its own conversion logic scattered throughout the codebase.

## Proposed Solution: Unified Naming Convention System

### Core Architecture: Abstract Types for Each Naming Context

Instead of one `Atom` type, we create a family of abstract types that understand their context and apply the appropriate transformation:

```haxe
// src/reflaxe/elixir/ast/naming/ElixirNaming.hx
package reflaxe.elixir.ast.naming;

/**
 * Base naming interface - all naming types implement this
 */
interface IElixirName {
    function toString(): String;
    function toRaw(): String;
}

/**
 * Elixir Atom names (always snake_case)
 * Used for: enum constructors, map keys, options, etc.
 */
abstract ElixirAtom(String) to String {
    inline public function new(s: String) {
        this = NameUtils.toSnakeCase(s);
    }
    
    @:from static inline public function fromString(s: String): ElixirAtom {
        return new ElixirAtom(s);
    }
    
    @:from static inline public function fromEnumField(ef: EnumField): ElixirAtom {
        return new ElixirAtom(ef.name);
    }
    
    static inline public function raw(s: String): ElixirAtom {
        return cast s;  // No conversion
    }
    
    // Common Elixir atoms
    static inline public function module_(): ElixirAtom return raw("__MODULE__");
    static inline public function struct_(): ElixirAtom return raw("__struct__");
    static inline public function ok(): ElixirAtom return raw("ok");
    static inline public function error(): ElixirAtom return raw("error");
}

/**
 * Elixir Function names (always snake_case)
 * Used for: def, defp, function references
 */
abstract ElixirFunction(String) to String {
    inline public function new(s: String) {
        this = NameUtils.toSnakeCase(s);
    }
    
    @:from static inline public function fromString(s: String): ElixirFunction {
        return new ElixirFunction(s);
    }
    
    @:from static inline public function fromClassField(cf: ClassField): ElixirFunction {
        return new ElixirFunction(cf.name);
    }
    
    // Special handling for operators
    static inline public function operator(op: String): ElixirFunction {
        return switch(op) {
            case "+": raw("Kernel.+");
            case "-": raw("Kernel.-");
            case "*": raw("Kernel.*");
            case "/": raw("Kernel./");
            default: raw(op);
        }
    }
    
    static inline public function raw(s: String): ElixirFunction {
        return cast s;
    }
}

/**
 * Elixir Variable names (snake_case, with underscore prefix for unused)
 * Used for: local variables, function parameters, pattern variables
 */
abstract ElixirVariable(String) to String {
    var isUnused: Bool;
    
    inline public function new(s: String, unused: Bool = false) {
        var baseName = NameUtils.toSnakeCase(s);
        this = unused && !baseName.startsWith("_") ? "_" + baseName : baseName;
    }
    
    @:from static inline public function fromTVar(tvar: TVar): ElixirVariable {
        var isUnused = tvar.meta != null && tvar.meta.has("-reflaxe.unused");
        return new ElixirVariable(tvar.name, isUnused);
    }
    
    static inline public function underscore(): ElixirVariable {
        return raw("_");
    }
    
    static inline public function raw(s: String): ElixirVariable {
        return cast s;
    }
}

/**
 * Elixir Module names (PascalCase with proper aliasing)
 * Used for: defmodule, alias, Module.function calls
 */
abstract ElixirModule(String) to String {
    inline public function new(s: String) {
        // Module names stay PascalCase but handle nested modules
        this = s.split(".").map(part -> NameUtils.toPascalCase(part)).join(".");
    }
    
    @:from static inline public function fromClassType(ct: ClassType): ElixirModule {
        return new ElixirModule(ct.name);
    }
    
    public function withPrefix(prefix: String): ElixirModule {
        return raw(prefix + "." + this);
    }
    
    static inline public function raw(s: String): ElixirModule {
        return cast s;
    }
}

/**
 * Elixir Field names (atoms for struct fields)
 * Used for: defstruct fields, map keys, record fields
 */
abstract ElixirField(String) to String {
    inline public function new(s: String) {
        this = NameUtils.toSnakeCase(s);
    }
    
    @:from static inline public function fromClassVar(cv: ClassVar): ElixirField {
        return new ElixirField(cv.name);
    }
    
    public function toAtom(): ElixirAtom {
        return ElixirAtom.raw(this);
    }
    
    static inline public function raw(s: String): ElixirField {
        return cast s;
    }
}
```

### Updated AST Definition

```haxe
// In ElixirAST.hx
enum ElixirAST {
    // Atoms now use ElixirAtom type
    EAtom(name: ElixirAtom);
    
    // Functions use ElixirFunction type
    EFunction(name: ElixirFunction, args: Array<ElixirAST>, body: ElixirAST);
    EFunctionCall(module: ElixirModule, func: ElixirFunction, args: Array<ElixirAST>);
    
    // Variables use ElixirVariable type
    EVariable(name: ElixirVariable);
    EBinding(name: ElixirVariable, value: ElixirAST);
    
    // Modules use ElixirModule type
    EModule(name: ElixirModule, body: Array<ElixirAST>);
    
    // Fields use ElixirField type
    EStructField(name: ElixirField, value: ElixirAST);
    
    // ... other AST nodes
}
```

### Usage Examples - Before and After

#### Before (Error-Prone, Repetitive):
```haxe
// In ElixirASTBuilder.hx - MANY manual conversions
case TCall(e, el):
    var funcName = NameUtils.toSnakeCase(extractFunctionName(e));  // Manual!
    var args = el.map(compileExpression);
    EFunctionCall(moduleName, funcName, args);

case TVar(tvar):
    var varName = NameUtils.toSnakeCase(tvar.name);  // Manual!
    if (isUnused(tvar)) varName = "_" + varName;     // Manual!
    EVariable(varName);

case TField(e, FEnum(enumRef, ef)):
    var atomName = NameUtils.toSnakeCase(ef.name);   // Manual!
    EAtom(atomName);
```

#### After (Automatic, DRY):
```haxe
// In ElixirASTBuilder.hx - Automatic conversions via abstract types
case TCall(e, el):
    var funcName: ElixirFunction = extractFunctionName(e);  // Auto conversion!
    var args = el.map(compileExpression);
    EFunctionCall(moduleName, funcName, args);

case TVar(tvar):
    var varName: ElixirVariable = tvar;  // Auto conversion + unused handling!
    EVariable(varName);

case TField(e, FEnum(enumRef, ef)):
    var atomName: ElixirAtom = ef;       // Auto conversion!
    EAtom(atomName);
```

### Benefits of This Architecture

1. **DRY Principle**: Conversion logic in ONE place per naming context
2. **Type Safety**: Can't accidentally pass wrong name type
3. **Context Awareness**: Each type knows its conversion rules
4. **Automatic Unused Handling**: Variables automatically get underscore prefix
5. **Zero Runtime Cost**: All `inline` functions
6. **IDE Support**: Full autocomplete and type checking
7. **Escape Hatches**: `raw()` methods for special cases

### Special Cases Handled Automatically

```haxe
// Module attributes - no conversion
EAtom(ElixirAtom.module_());  // __MODULE__

// Unused variables - automatic prefix
var unused: ElixirVariable = unusedTVar;  // Becomes "_unused_var"

// Operators - special handling
var plus: ElixirFunction = ElixirFunction.operator("+");  // Kernel.+

// Already snake_case - idempotent
var already: ElixirAtom = "already_snake";  // stays "already_snake"

// Elixir module names - preserved
var mod: ElixirModule = ElixirModule.raw("Elixir.Enum");  // Elixir.Enum
```

### Migration Strategy

1. **Phase 1**: Create all abstract types in `ast/naming/` directory
2. **Phase 2**: Update `ElixirAST` enum definition
3. **Phase 3**: Compiler will show all type errors - fix each one
4. **Phase 4**: Remove ALL manual `toSnakeCase()` calls
5. **Phase 5**: Add comprehensive test suite

### Files to Update

Primary files:
- `/src/reflaxe/elixir/ast/ElixirAST.hx` - Update all node definitions
- `/src/reflaxe/elixir/ast/ElixirASTBuilder.hx` - Remove manual conversions
- `/src/reflaxe/elixir/ast/ElixirASTPrinter.hx` - Handle new types
- `/src/reflaxe/elixir/ast/ElixirASTTransformer.hx` - Update transformations

Helper compilers:
- All files in `/src/reflaxe/elixir/helpers/` - Update to use new types

### Testing Requirements

```haxe
// Comprehensive test suite
class NamingConventionTest {
    function testAtomConversion() {
        assertEquals(":todo_updates", print(new ElixirAtom("TodoUpdates")));
        assertEquals(":user_id", print(new ElixirAtom("userId")));
        assertEquals(":__MODULE__", print(ElixirAtom.module_()));
    }
    
    function testFunctionConversion() {
        assertEquals("get_user_by_id", print(new ElixirFunction("getUserById")));
        assertEquals("Kernel.+", print(ElixirFunction.operator("+")));
    }
    
    function testVariableConversion() {
        assertEquals("user_name", print(new ElixirVariable("userName")));
        assertEquals("_unused_var", print(new ElixirVariable("unusedVar", true)));
        assertEquals("_", print(ElixirVariable.underscore()));
    }
    
    function testModuleConversion() {
        assertEquals("TodoApp.User", print(new ElixirModule("TodoApp.User")));
        assertEquals("TodoAppWeb", print(new ElixirModule("TodoAppWeb")));
    }
    
    function testFieldConversion() {
        assertEquals("first_name", print(new ElixirField("firstName")));
    }
}
```

### Implementation Priority

**Priority**: High

This architectural improvement will:
- Prevent entire categories of naming bugs
- Make the compiler significantly more maintainable
- Reduce code duplication by ~30%
- Improve developer confidence

### Estimated Effort

- Abstract types implementation: 3-4 hours
- AST definition updates: 2 hours
- Migration of existing code: 4-6 hours
- Testing: 2-3 hours
- **Total: 2 days**

### Future Extensions

Once proven, this pattern enables:
- **ElixirMacro**: Type-safe macro names
- **ElixirAttribute**: Module attribute names
- **ElixirGenServer**: Callback names with proper conventions
- **ElixirTest**: Test function name conventions

This creates a comprehensive, type-safe naming convention system throughout the entire compiler.