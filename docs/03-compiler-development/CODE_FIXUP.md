# Code Fixup Guide (Technical Debt Documentation)

> **Parent Context**: See [AGENTS.md](AGENTS.md) for compiler development context

⚠️ **IMPORTANT**: This guide documents **technical debt** - patterns that should be eliminated by fixing root causes in the compiler.

## 🚨 Critical Understanding

**CodeFixupCompiler represents what NOT to do in a compiler**. It performs post-processing string manipulation that should be handled at the AST compilation level. This guide documents its current functionality and the roadmap to eliminate it.

## 📋 Current Post-Processing Operations

### 1. Y Combinator Malformed Conditionals
**Problem**: Y combinator generates malformed inline if-else expressions with struct updates

**Current Band-Aid**:
```haxe
// String replacement to fix malformed syntax
fixedCode = fixedCode.replace(
    ~/, else: expression = %\{/g,
    ", do: expression = %{"
);
```

**Root Cause Location**: `YCombinatorCompiler.hx` - inline conditional generation
**Proper Fix**: Generate correct block syntax from the start

### 2. App Name Resolution  
**Problem**: `getAppName()` calls are left in generated code

**Current Band-Aid**:
```haxe
// Post-processing replacement
code = code.replace("getAppName()", '"' + appName + '"');
```

**Root Cause Location**: Expression compilation where app name is needed
**Proper Fix**: Resolve app names during AST compilation

### 3. Source Map Management
**Problem**: Source maps handled separately from main compilation

**Current Band-Aid**:
```haxe
public function initSourceMapWriter(outputPath: String) {
    sourceMapWriter = new SourceMapWriter(outputPath);
}
```

**Root Cause Location**: Compilation pipeline initialization
**Proper Fix**: Integrate source mapping into core compilation flow

### 4. Syntax Artifact Cleanup
**Problem**: Generated code contains empty string concatenations and other artifacts

**Current Band-Aid**:
```haxe
// Remove empty string concatenations
cleanedCode = cleanedCode.replace(' <> ""', '');
cleanedCode = cleanedCode.replace('"" <> ', '');
```

**Root Cause Location**: String generation in expression compilation
**Proper Fix**: Generate clean expressions without artifacts

## 🔍 App Name Resolution Priority Chain

The current app name resolution follows this priority:
1. **@:appName** metadata on application class
2. **@:native** metadata module prefix extraction
3. **Class name inference** (e.g., `TodoAppApplication` → `TodoApp`)
4. **Fallback**: "MyApp"

**Implementation**:
```haxe
function getCurrentAppName(meta: MetaAccess, className: String): String {
    // Priority 1: @:appName metadata
    if (meta != null && meta.has(":appName")) {
        var appNameMeta = meta.extract(":appName");
        if (appNameMeta.length > 0 && appNameMeta[0].params.length > 0) {
            return extractStringFromExpr(appNameMeta[0].params[0]);
        }
    }
    
    // Priority 2: @:native metadata
    if (meta != null && meta.has(":native")) {
        var nativeMeta = meta.extract(":native");
        if (nativeMeta.length > 0 && nativeMeta[0].params.length > 0) {
            var nativeName = extractStringFromExpr(nativeMeta[0].params[0]);
            return nativeName.split(".")[0];
        }
    }
    
    // Priority 3: Class name inference
    if (className != null && className.endsWith("Application")) {
        return className.substring(0, className.length - "Application".length);
    }
    
    // Priority 4: Fallback
    return "MyApp";
}
```

## 🎯 Elimination Roadmap

### Phase 1: Fix Y Combinator Conditional Generation
**Location**: `YCombinatorCompiler.hx`
**Task**: Modify conditional generation to produce correct syntax initially
```haxe
// Instead of generating malformed inline conditionals
// Generate proper block syntax from the start
```

### Phase 2: AST-Level App Name Resolution  
**Location**: Expression compilation in `ElixirCompiler.hx`
**Task**: Resolve app names when compiling expressions
```haxe
// During expression compilation
case TCall({expr: TLocal({name: "getAppName"})}, []):
    return '"' + getCurrentAppName() + '"';
```

### Phase 3: Integrate Source Mapping
**Location**: Main compilation pipeline
**Task**: Build source mapping into core compilation flow
```haxe
// Add source position tracking to all compilation methods
override function compileExpression(expr: TypedExpr): String {
    var result = // ... compile expression
    if (sourceMapWriter != null) {
        sourceMapWriter.addMapping(expr.pos, currentLine);
    }
    return result;
}
```

### Phase 4: Clean Expression Generation
**Location**: String generation throughout compiler
**Task**: Generate clean syntax without artifacts
```haxe
// Instead of generating "" <> someValue
// Check for empty strings before concatenation
if (leftStr.length > 0 && rightStr.length > 0) {
    return leftStr + " <> " + rightStr;
} else if (leftStr.length > 0) {
    return leftStr;
} else {
    return rightStr;
}
```

## ⚠️ Why This Is Technical Debt

### Problems with String Post-Processing
1. **Fragility**: Regex patterns can match unintended code
2. **Performance**: Multiple passes over generated code
3. **Maintainability**: Hard to debug when transformations fail
4. **Correctness**: Can corrupt valid code that matches patterns
5. **Testability**: Can't test individual transformations in isolation

### Benefits of AST-Level Fixes
1. **Robustness**: Structural transformations can't corrupt syntax
2. **Performance**: Single-pass compilation
3. **Maintainability**: Clear transformation logic at source
4. **Correctness**: Type-safe AST manipulations
5. **Testability**: Each transformation can be unit tested

## 🧪 Testing During Migration

### Validation Strategy
As we migrate each fixup to its proper location:

1. **Identify all affected patterns** in test suite
2. **Create targeted test cases** for the specific fix
3. **Implement AST-level solution**
4. **Remove corresponding fixup code**
5. **Verify all tests still pass**

### Debug Traces for Migration
```haxe
#if debug_fixup_migration
trace("[Migration] Fixing Y combinator at AST level");
trace("[Migration] Previous fixup no longer needed");
#end
```

## 📊 Success Metrics

### When CodeFixupCompiler Can Be Deleted
- [ ] All Y combinator conditionals generate correctly
- [ ] App names resolved during compilation
- [ ] Source maps integrated into main flow
- [ ] No syntax artifacts in generated code
- [ ] All tests pass without post-processing
- [ ] `CodeFixupCompiler.hx` deleted entirely

## 🔧 Migration Guidelines

### For Each Fixup Pattern
1. **Document the pattern** being fixed
2. **Find root cause** in compiler source
3. **Write test case** that exposes the issue
4. **Fix at AST level** in appropriate compiler
5. **Remove fixup code** from CodeFixupCompiler
6. **Verify tests pass** without the fixup

### Priority Order
1. **Y combinator fixes** - Most fragile regex patterns
2. **App name resolution** - Clear AST-level solution
3. **Syntax cleanup** - Expression generation improvements
4. **Source maps** - Architectural integration

## 📚 Related Documentation

- **[Y_COMBINATOR_PATTERNS.md](Y_COMBINATOR_PATTERNS.md)** - Y combinator compilation patterns
- **[AST_CLEANUP_PATTERNS.md](AST_CLEANUP_PATTERNS.md)** - Proper AST processing
- **[COMPILATION_FLOW.md](COMPILATION_FLOW.md)** - Overall compilation pipeline
- **[v1-detailed-roadmap.md](../08-roadmap/v1-detailed-roadmap.md)** - Technical debt elimination plan

---

**Remember**: This documentation exists to help eliminate CodeFixupCompiler, not to perpetuate its use. Every new feature should be implemented at the AST level, never as a post-processing fixup.