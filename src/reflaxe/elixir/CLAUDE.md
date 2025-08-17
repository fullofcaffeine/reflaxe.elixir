# Compiler Development Context for Reflaxe.Elixir

> **Parent Context**: See [/CLAUDE.md](/CLAUDE.md) for project-wide conventions, architecture, and core development principles

This file contains compiler-specific development guidance for agents working on the Reflaxe.Elixir transpiler source code.

## 🏗️ Compiler Architecture Overview

### Core Components
- **ElixirCompiler.hx** - Main DirectToStringCompiler inheritance, entry point for compilation
- **helpers/** directory - Specialized compiler components for different language features
- **ElixirPrinter.hx** - AST to string conversion and formatting
- **ElixirTyper.hx** - Type mapping between Haxe and Elixir systems

### Helper Compiler Pattern
```
ElixirCompiler.hx (main orchestrator)
├── helpers/ChangesetCompiler.hx    # @:changeset annotation processing
├── helpers/ClassCompiler.hx        # Class and struct compilation  
├── helpers/EnumCompiler.hx         # Enum compilation with pattern matching
├── helpers/LiveViewCompiler.hx     # @:liveview annotation processing
├── helpers/RouterCompiler.hx       # @:router annotation processing
├── helpers/ProtocolCompiler.hx     # @:protocol/@:impl processing
├── helpers/MigrationCompiler.hx    # @:migration database schema processing
└── helpers/HxxCompiler.hx          # HXX template compilation
```

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

### DirectToStringCompiler Inheritance
We inherit from Reflaxe's `DirectToStringCompiler`:
```haxe
class ElixirCompiler extends DirectToStringCompiler {
    // Override specific methods for Elixir-specific behavior
    override function compileClass(classType: ClassType, varFields: Array<String>): String
    override function compileEnum(enumType: EnumType, constructs: Array<String>): String
    override function compileExpression(expr: TypedExpr): String
}
```

## 🎯 Development Rules ⚠️ CRITICAL

### ❌ NEVER Do This:
- Edit generated .ex files to "fix" compilation issues
- Add hardcoded TODOs in production code
- Use string manipulation instead of AST processing
- Skip testing with `npm test` after changes
- Commit without verifying todo-app compiles

### ✅ ALWAYS Do This:
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
// ✅ GOOD: Keep AST until last moment
function compileExpression(expr: TypedExpr): String {
    var result = switch(expr.expr) {
        case TCall(e, el): compileCall(e, el);     // Process AST nodes
        case TBinop(op, e1, e2): compileBinop(op, e1, e2);
        default: // Handle all cases
    }
    return result;
}

// ❌ BAD: Convert to string too early
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

## 📚 Related Documentation
- [`/documentation/COMPILER_BEST_PRACTICES.md`](/documentation/COMPILER_BEST_PRACTICES.md) - Complete development practices
- [`/documentation/COMPILER_PATTERNS.md`](/documentation/COMPILER_PATTERNS.md) - Implementation patterns
- [`/documentation/ARCHITECTURE.md`](/documentation/ARCHITECTURE.md) - Overall architecture
- [`/documentation/HAXE_MACRO_APIS.md`](/documentation/HAXE_MACRO_APIS.md) - Correct macro API usage

## 🏆 Quality Standards

Every compiler change must meet these standards:
- **Correctness**: Generated Elixir must be syntactically and semantically correct
- **Idiomaticity**: Output should follow Elixir best practices and conventions  
- **Type Safety**: Preserve Haxe's compile-time guarantees in generated code
- **Performance**: Generated code should be efficient and not wasteful
- **Maintainability**: Compiler code itself must be clear and well-documented

**Remember**: We're not just generating syntactically correct Elixir - we're generating IDIOMATIC Elixir that Elixir developers would be proud to write themselves.